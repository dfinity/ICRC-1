use anyhow::{bail, Context};
use candid::Nat;
use candid::Principal;
use futures::StreamExt;
use icrc1_test_env::icrc1::{
    balance_of, metadata, minting_account, supported_standards, token_decimals, token_name,
    token_symbol, transfer, transfer_fee,
};
use icrc1_test_env::{Account, LedgerEnv, Transfer, Value};
use std::future::Future;
use std::pin::Pin;
use std::time::SystemTime;

pub enum Outcome {
    Passed,
    Skipped { reason: String },
}

pub type TestResult = anyhow::Result<Outcome>;

pub struct Test {
    name: String,
    action: Pin<Box<dyn Future<Output = TestResult>>>,
}

pub fn test(name: impl Into<String>, body: impl Future<Output = TestResult> + 'static) -> Test {
    Test {
        name: name.into(),
        action: Box::pin(body),
    }
}

fn lookup<'a, K, V, U>(meta: &'a [(K, V)], key: &U) -> Option<&'a V>
where
    K: PartialEq<U>,
    U: ?Sized,
{
    meta.iter().find_map(|(k, v)| (k == key).then_some(v))
}

fn assert_equal<T: PartialEq + std::fmt::Debug>(lhs: T, rhs: T) -> anyhow::Result<()> {
    if lhs != rhs {
        bail!("{:?} ≠ {:?}", lhs, rhs)
    }
    Ok(())
}

async fn assert_balance(
    ledger: &impl LedgerEnv,
    account: impl Into<Account>,
    expected: impl Into<Nat>,
) -> anyhow::Result<()> {
    let account = account.into();
    let actual = balance_of(ledger, account.clone()).await?;
    let expected = expected.into();

    if expected != actual {
        bail!(
            "Expected the balance of account {:?} to be {}, got {}",
            account,
            expected,
            actual
        )
    }
    Ok(())
}

async fn transfer_or_fail(ledger_env: &impl LedgerEnv, amount: Nat, receiver: Principal) -> Nat {
    transfer(ledger_env, Transfer::amount_to(amount.clone(), receiver))
        .await
        .with_context(|| format!("failed to transfer {} tokens to {}", amount, receiver))
        .unwrap()
        .unwrap()
}

async fn setup_test_account(
    ledger_env: &impl LedgerEnv,
    amount: Nat,
) -> anyhow::Result<impl LedgerEnv> {
    let balance = balance_of(ledger_env, ledger_env.principal()).await?;
    assert!(balance >= amount.clone() + transfer_fee(ledger_env).await?);
    let receiver_env = ledger_env.fork();
    let receiver = receiver_env.principal();
    assert_balance(&receiver_env, receiver, 0).await?;
    let _tx = transfer_or_fail(ledger_env, amount.clone(), receiver).await;
    assert_balance(
        &receiver_env,
        Account {
            owner: receiver,
            subaccount: None,
        },
        amount.clone(),
    )
    .await?;
    Ok(receiver_env)
}

/// Checks whether the ledger supports token transfers and handles
/// default sub accounts correctly.
pub async fn test_transfer(ledger_env: impl LedgerEnv + LedgerEnv) -> TestResult {
    let p1_env = setup_test_account(&ledger_env, Nat::from(20_000)).await?;
    let p2_env = setup_test_account(&ledger_env, Nat::from(20_000)).await?;
    let transfer_amount = 10_000;

    let balance_p1 = balance_of(&p1_env, p1_env.principal()).await?;
    let balance_p2 = balance_of(&p2_env, p2_env.principal()).await?;

    let _tx = transfer_or_fail(&p1_env, Nat::from(transfer_amount), p2_env.principal()).await;

    assert_balance(
        &p2_env,
        Account {
            owner: p2_env.principal(),
            subaccount: None,
        },
        balance_p2.clone() + Nat::from(transfer_amount),
    )
    .await?;

    assert_balance(
        &ledger_env,
        Account {
            owner: p2_env.principal(),
            subaccount: Some([0; 32]),
        },
        balance_p2 + transfer_amount,
    )
    .await?;

    assert_balance(
        &p1_env,
        p1_env.principal(),
        balance_p1 - Nat::from(transfer_amount) - transfer_fee(&p1_env).await?,
    )
    .await?;

    Ok(Outcome::Passed)
}

/// Checks whether the ledger supports token burns.
/// Skips the checks if the ledger does not have a minting account.
pub async fn test_burn(ledger_env: impl LedgerEnv) -> TestResult {
    let minting_account = match minting_account(&ledger_env).await? {
        Some(account) => account,
        None => {
            return Ok(Outcome::Skipped {
                reason: "the ledger does not support burn transactions".to_string(),
            });
        }
    };

    assert_balance(&ledger_env, minting_account.clone(), 0)
        .await
        .context("minting account cannot hold any funds")?;

    let burn_amount = Nat::from(10_000);
    let p1_env = setup_test_account(&ledger_env, burn_amount.clone()).await?;

    // Burning tokens is done by sending the burned amount to the minting account
    let _tx = transfer(
        &p1_env,
        Transfer::amount_to(burn_amount.clone(), minting_account.clone()),
    )
    .await
    .with_context(|| {
        format!(
            "failed to transfer {} tokens to {:?}",
            burn_amount,
            minting_account.clone()
        )
    })
    .unwrap()
    .unwrap();

    assert_balance(&p1_env, p1_env.principal(), 0).await?;
    assert_balance(&ledger_env, minting_account, 0).await?;

    Ok(Outcome::Passed)
}

/// Checks whether the ledger metadata entries agree with named methods.
pub async fn test_metadata(ledger: impl LedgerEnv) -> TestResult {
    let mut metadata = metadata(&ledger).await?;
    metadata.sort_by(|l, r| l.0.cmp(&r.0));

    for ((k1, _), (k2, _)) in metadata.iter().zip(metadata.iter().skip(1)) {
        if k1 == k2 {
            bail!("Key {} is duplicated in the metadata", k1);
        }
    }

    if let Some(name) = lookup(&metadata, "icrc1:name") {
        assert_equal(&Value::Text(token_name(&ledger).await?), name)
            .context("icrc1:name metadata entry does not match the icrc1_name endpoint")?;
    }
    if let Some(sym) = lookup(&metadata, "icrc1:symbol") {
        assert_equal(&Value::Text(token_symbol(&ledger).await?), sym)
            .context("icrc1:symol metadata entry does not match the icrc1_symbol endpoint")?;
    }
    if let Some(meta_decimals) = lookup(&metadata, "icrc1:decimals") {
        let decimals = token_decimals(&ledger).await?;
        assert_equal(&Value::Nat(Nat::from(decimals)), meta_decimals)
            .context("icrc1:decimals metadata entry does not match the icrc1_decimals endpoint")?;
    }
    if let Some(fee) = lookup(&metadata, "icrc1:fee") {
        assert_equal(&Value::Nat(transfer_fee(&ledger).await?), fee)
            .context("icrc1:fee metadata entry does not match the icrc1_fee endpoint")?;
    }
    Ok(Outcome::Passed)
}

/// Checks whether the ledger advertizes support for ICRC-1 standard.
pub async fn test_supported_standards(ledger: impl LedgerEnv) -> anyhow::Result<Outcome> {
    let stds = supported_standards(&ledger).await?;
    if !stds.iter().any(|std| std.name == "ICRC-1") {
        bail!("The ledger does not claim support for ICRC-1: {:?}", stds);
    }

    Ok(Outcome::Passed)
}

/// Checks whether the ledger applies deduplication of transactions correctly
pub async fn test_tx_deduplication(ledger_env: impl LedgerEnv) -> anyhow::Result<Outcome> {
    // Create two test accounts and transfer some tokens to the first account
    let p1_env = setup_test_account(&ledger_env, 200_000.into()).await?;
    let p2_env = p1_env.fork();

    // If created at time is not set, the transfer should not be calssified as a duplicate --> Transfer should succeed
    let transfer_args = Transfer::amount_to(10_000, p2_env.principal());
    if transfer(&p1_env, transfer_args.clone())
        .await
        .unwrap()
        .unwrap()
        > transfer(&p1_env, transfer_args.clone())
            .await
            .unwrap()
            .unwrap()
    {
        return Err(anyhow::Error::msg(
            "BlockIndex of previous transaction is higher than that of the following transaction",
        ));
    }

    let now = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap()
        .as_nanos();

    // Changing the timestamp to the previous transfer args should result in no deduplication --> Transfer should succeed
    let transfer_args = transfer_args.created_at_time(now as u64);
    transfer(&p1_env, transfer_args.clone())
        .await
        .unwrap()
        .unwrap();

    // Sending the previous transaction with the same timestamp twice should not be possible --> Transfer should not succeed
    assert!(transfer(&p1_env, transfer_args.clone())
        .await
        .unwrap()
        .is_err());

    // Changing the fee to the previous transfer args should result in no deduplication --> Transfer should succeed
    let transfer_args = transfer_args.fee(transfer_fee(&ledger_env).await.unwrap());
    transfer(&p1_env, transfer_args.clone())
        .await
        .unwrap()
        .unwrap();

    // If we send the transfer again it should be a duplicate --> Transfer should not succeed
    assert!(transfer(&p1_env, transfer_args.clone())
        .await
        .unwrap()
        .is_err());

    // Changing the memo to the previous transfer args should result in no deduplication --> Transfer should succeed
    let transfer_args = transfer_args.memo(vec![1, 2, 3]);
    transfer(&p1_env, transfer_args.clone())
        .await
        .unwrap()
        .unwrap();

    // If we send the transfer again it should be a duplicate --> Transfer should not succeed
    assert!(transfer(&p1_env, transfer_args.clone())
        .await
        .unwrap()
        .is_err());

    let now = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap()
        .as_nanos();
    let args_1 = Transfer::amount_to(
        10_000,
        Account {
            owner: p2_env.principal(),
            subaccount: None,
        },
    )
    .created_at_time(now as u64);
    let args_2 = Transfer::amount_to(
        10_000,
        Account {
            owner: p2_env.principal(),
            subaccount: Some([0; 32]),
        },
    )
    .created_at_time(now as u64);

    // None and Some([0; 32]) should not be considered duplicates
    transfer(&p1_env, args_1).await.unwrap().unwrap();
    transfer(&p1_env, args_2).await.unwrap().unwrap();

    Ok(Outcome::Passed)
}

/// Returns the entire list of tests.
pub fn test_suite(env: impl LedgerEnv + 'static + Clone) -> Vec<Test> {
    vec![
        test("basic:transfer", test_transfer(env.clone())),
        test("basic:burn", test_burn(env.clone())),
        test("basic:metadata", test_metadata(env.clone())),
        test(
            "basic:supported_standards",
            test_supported_standards(env.clone()),
        ),
        test("basic:tx_deduplication", test_tx_deduplication(env)),
    ]
}

/// Executes the list of tests concurrently and prints results using
/// the TAP protocol (https://testanything.org/).
pub async fn execute_tests(tests: Vec<Test>) -> bool {
    use futures::stream::FuturesOrdered;

    let mut names = Vec::new();
    let mut futures = FuturesOrdered::new();

    for test in tests.into_iter() {
        names.push(test.name);
        futures.push_back(test.action);
    }

    println!("TAP version 14");
    println!("1..{}", futures.len());

    let mut idx = 0;
    let mut success = true;
    while let Some(result) = futures.next().await {
        match result {
            Ok(Outcome::Passed) => {
                println!("ok {} - {}", idx + 1, names[idx]);
            }
            Ok(Outcome::Skipped { reason }) => {
                println!("ok {} - {} # SKIP {}", idx + 1, names[idx], reason);
            }
            Err(err) => {
                success = false;

                for line in format!("{:?}", err).lines() {
                    println!("# {}", line);
                }

                println!("not ok {} - {}", idx + 1, names[idx]);
            }
        }
        idx += 1;
    }

    success
}
