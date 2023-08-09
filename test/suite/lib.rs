use anyhow::{bail, Context};
use candid::Nat;
use candid::Principal;
use futures::StreamExt;
use icrc1_test_env::icrc1::{
    balance_of, metadata, minting_account, supported_standards, token_decimals, token_name,
    token_symbol, transfer, transfer_fee,
};
use icrc1_test_env::{Account, LedgerEnv, Transfer, TransferError, Value};
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

fn assert_not_equal<T: PartialEq + std::fmt::Debug>(lhs: T, rhs: T) -> anyhow::Result<()> {
    if lhs == rhs {
        bail!("{:?} = {:?}", lhs, rhs)
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

async fn setup_test_account(
    ledger_env: &impl LedgerEnv,
    amount: Nat,
) -> anyhow::Result<impl LedgerEnv> {
    let balance = balance_of(ledger_env, ledger_env.principal()).await?;
    assert!(balance >= amount.clone() + transfer_fee(ledger_env).await?);
    let receiver_env = ledger_env.fork();
    let receiver = receiver_env.principal();
    assert_balance(&receiver_env, receiver, 0).await?;
    let _tx = transfer(ledger_env, Transfer::amount_to(amount.clone(), receiver)).await??;
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
pub async fn icrc1_test_transfer(ledger_env: impl LedgerEnv) -> TestResult {
    let fee = transfer_fee(&ledger_env).await?;
    let p1_env = setup_test_account(&ledger_env, Nat::from(20_000) + fee.clone()).await?;
    let p2_env = ledger_env.fork();
    let transfer_amount = 10_000;

    let balance_p1 = balance_of(&p1_env, p1_env.principal()).await?;
    let balance_p2 = balance_of(&p2_env, p2_env.principal()).await?;

    let _tx = transfer(
        &p1_env,
        Transfer::amount_to(Nat::from(transfer_amount), p2_env.principal()),
    )
    .await??;

    assert_balance(
        &ledger_env,
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
        &ledger_env,
        p1_env.principal(),
        balance_p1 - Nat::from(transfer_amount) - fee,
    )
    .await?;

    Ok(Outcome::Passed)
}

/// Checks whether the ledger supports token burns.
/// Skips the checks if the ledger does not have a minting account.
pub async fn icrc1_test_burn(ledger_env: impl LedgerEnv) -> TestResult {
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
    .await?
    .with_context(|| {
        format!(
            "failed to transfer {} tokens to {:?}",
            burn_amount,
            minting_account.clone()
        )
    })?;

    assert_balance(&p1_env, p1_env.principal(), 0).await?;
    assert_balance(&ledger_env, minting_account, 0).await?;

    Ok(Outcome::Passed)
}

/// Checks whether the ledger metadata entries agree with named methods.
pub async fn icrc1_test_metadata(ledger: impl LedgerEnv) -> TestResult {
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
pub async fn icrc1_test_supported_standards(ledger: impl LedgerEnv) -> anyhow::Result<Outcome> {
    let stds = supported_standards(&ledger).await?;
    if !stds.iter().any(|std| std.name == "ICRC-1") {
        bail!("The ledger does not claim support for ICRC-1: {:?}", stds);
    }

    Ok(Outcome::Passed)
}

/// Checks whether the ledger advertizes support for ICRC-2 standard.
pub async fn icrc2_test_supported_standards(ledger: impl LedgerEnv) -> anyhow::Result<Outcome> {
    let stds = supported_standards(&ledger).await?;
    // If the ledger claims to support ICRC-2 it also needs to support ICRC-1
    if !(stds.iter().any(|std| std.name == "ICRC-2") && stds.iter().any(|std| std.name == "ICRC-1"))
    {
        bail!(
            "The ledger does not claim support for ICRC-1 and ICRC-2: {:?}",
            stds
        );
    }

    Ok(Outcome::Passed)
}

/// Checks whether the ledger applies deduplication of transactions correctly
pub async fn icrc1_test_tx_deduplication(ledger_env: impl LedgerEnv) -> anyhow::Result<Outcome> {
    // Create two test accounts and transfer some tokens to the first account
    let p1_env = setup_test_account(&ledger_env, 200_000.into()).await?;
    let p2_env = p1_env.fork();

    let time_nanos = || {
        ledger_env
            .time()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_nanos() as u64
    };

    // Deduplication should not happen if the created_at_time field is unset.
    let transfer_args = Transfer::amount_to(10_000, p2_env.principal());
    transfer(&p1_env, transfer_args.clone())
        .await?
        .context("failed to execute the first no-dedup transfer")?;

    assert_balance(&p1_env, p2_env.principal(), 10_000).await?;

    transfer(&p1_env, transfer_args.clone())
        .await?
        .context("failed to execute the second no-dedup transfer")?;

    assert_balance(&p1_env, p2_env.principal(), 20_000).await?;

    // Setting the created_at_time field changes the transaction
    // identity, so the transfer should succeed.
    let transfer_args = transfer_args.created_at_time(time_nanos());

    let txid = match transfer(&p1_env, transfer_args.clone()).await? {
        Ok(txid) => txid,
        Err(TransferError::TooOld) => {
            return Ok(Outcome::Skipped {
                reason: "the ledger does not support deduplication".to_string(),
            })
        }
        Err(e) => return Err(e).context("failed to execute the first dedup transfer"),
    };

    assert_balance(&p1_env, p2_env.principal(), 30_000).await?;

    // Sending the same transfer again should trigger deduplication.
    assert_equal(
        Err(TransferError::Duplicate {
            duplicate_of: txid.clone(),
        }),
        transfer(&p1_env, transfer_args.clone()).await?,
    )?;

    assert_balance(&p1_env, p2_env.principal(), 30_000).await?;

    // Explicitly setting the fee field changes the transaction
    // identity, so the transfer should succeed.
    let transfer_args = transfer_args.fee(
        transfer_fee(&ledger_env)
            .await
            .context("failed to obtain the transfer fee")?,
    );

    let txid_2 = transfer(&p1_env, transfer_args.clone())
        .await?
        .context("failed to execute the transfer with an explicitly set fee field")?;

    assert_balance(&p1_env, p2_env.principal(), 40_000).await?;

    assert_not_equal(&txid, &txid_2).context("duplicate txid")?;

    // Sending the same transfer again should trigger deduplication.
    assert_equal(
        Err(TransferError::Duplicate {
            duplicate_of: txid_2.clone(),
        }),
        transfer(&p1_env, transfer_args.clone()).await?,
    )?;

    assert_balance(&p1_env, p2_env.principal(), 40_000).await?;

    // A custom memo changes the transaction identity, so the transfer
    // should succeed.
    let transfer_args = transfer_args.memo(vec![1, 2, 3]);

    let txid_3 = transfer(&p1_env, transfer_args.clone())
        .await?
        .context("failed to execute the transfer with an explicitly set memo field")?;

    assert_balance(&p1_env, p2_env.principal(), 50_000).await?;

    assert_not_equal(&txid, &txid_3).context("duplicate txid")?;
    assert_not_equal(&txid_2, &txid_3).context("duplicate txid")?;

    // Sending the same transfer again should trigger deduplication.
    assert_equal(
        Err(TransferError::Duplicate {
            duplicate_of: txid_3,
        }),
        transfer(&p1_env, transfer_args.clone()).await?,
    )?;

    assert_balance(&p1_env, p2_env.principal(), 50_000).await?;

    let now = time_nanos();

    // Transactions with different subaccounts (even if it's None and
    // Some([0; 32])) should not be considered duplicates.

    transfer(
        &p1_env,
        Transfer::amount_to(
            10_000,
            Account {
                owner: p2_env.principal(),
                subaccount: None,
            },
        )
        .memo(vec![0])
        .created_at_time(now),
    )
    .await?
    .context("failed to execute the transfer with an empty subaccount")?;

    assert_balance(&p1_env, p2_env.principal(), 60_000).await?;

    transfer(
        &p1_env,
        Transfer::amount_to(
            10_000,
            Account {
                owner: p2_env.principal(),
                subaccount: Some([0; 32]),
            },
        )
        .memo(vec![0])
        .created_at_time(now),
    )
    .await?
    .context("failed to execute the transfer with the default subaccount")?;

    assert_balance(&p1_env, p2_env.principal(), 70_000).await?;

    Ok(Outcome::Passed)
}

pub async fn icrc1_test_bad_fee(ledger_env: impl LedgerEnv) -> anyhow::Result<Outcome> {
    // Create two test accounts and transfer some tokens to the first account
    let p1_env = setup_test_account(&ledger_env, 200_000.into()).await?;
    let p2_env = p1_env.fork();

    let mut transfer_args = Transfer::amount_to(10_000, p2_env.principal());
    let ledger_fee = transfer_fee(&ledger_env).await.unwrap();
    // Set incorrect fee
    transfer_args = transfer_args.fee(ledger_fee.clone() + Nat::from(1));
    match transfer(&ledger_env, transfer_args.clone()).await.unwrap() {
        Ok(_) => return Err(anyhow::Error::msg("Expected Bad Fee Error")),
        Err(err) => match err {
            TransferError::BadFee { expected_fee } => {
                if expected_fee != transfer_fee(&ledger_env).await.unwrap() {
                    return Err(anyhow::Error::msg(format!(
                        "Expected BadFee argument to be {}, got {}",
                        ledger_fee, expected_fee
                    )));
                }
            }
            _ => return Err(anyhow::Error::msg("Expected BadFee error")),
        },
    }
    Ok(Outcome::Passed)
}

pub async fn icrc1_test_future_transfer(ledger_env: impl LedgerEnv) -> anyhow::Result<Outcome> {
    // Create two test accounts and transfer some tokens to the first account
    let p1_env = setup_test_account(&ledger_env, 200_000.into()).await?;
    let p2_env = p1_env.fork();

    let mut transfer_args = Transfer::amount_to(10_000, p2_env.principal());

    // Set created time in the future
    transfer_args = transfer_args.created_at_time(u64::MAX);
    match transfer(&ledger_env, transfer_args)
        .await
        .unwrap()
        .unwrap_err()
    {
        TransferError::CreatedInFuture { ledger_time: _ } => Ok(Outcome::Passed),
        _ => Err(anyhow::Error::msg("Expected BadFee error")),
    }
}

pub async fn icrc1_test_memo_bytes_length(ledger_env: impl LedgerEnv) -> anyhow::Result<Outcome> {
    // Create two test accounts and transfer some tokens to the first account
    let p1_env = setup_test_account(&ledger_env, 200_000.into()).await?;
    let p2_env = p1_env.fork();

    let transfer_args = Transfer::amount_to(10_000, p2_env.principal()).memo([1u8; 32]);
    // Ledger should accept memos of at least 32 bytes;
    match transfer(&ledger_env, transfer_args.clone()).await.unwrap() {
        Ok(_) => Ok(Outcome::Passed),
        Err(err) => Err(anyhow::Error::msg(format!(
            "Expected memo with 32 bytes to succeed but received error: {:?}",
            err
        ))),
    }
}

/// Returns the entire list of icrc1 tests.
pub fn icrc1_test_suite(env: impl LedgerEnv + 'static + Clone) -> Vec<Test> {
    vec![
        test("icrc1:transfer", icrc1_test_transfer(env.clone())),
        test("icrc1:burn", icrc1_test_burn(env.clone())),
        test("icrc1:metadata", icrc1_test_metadata(env.clone())),
        test(
            "icrc1:supported_standards",
            icrc1_test_supported_standards(env.clone()),
        ),
        test(
            "icrc1:tx_deduplication",
            icrc1_test_tx_deduplication(env.clone()),
        ),
        test(
            "icrc1:memo_bytes_length",
            icrc1_test_memo_bytes_length(env.clone()),
        ),
        test(
            "icrc1:future_transfers",
            icrc1_test_future_transfer(env.clone()),
        ),
        test("icrc1:bad_fee", icrc1_test_bad_fee(env)),
    ]
}

/// Returns the entire list of icrc2 tests.
pub fn icrc2_test_suite(env: impl LedgerEnv + 'static + Clone) -> Vec<Test> {
    vec![test(
        "icrc2:supported_standards",
        icrc2_test_supported_standards(env.clone()),
    )]
}

pub async fn test_suite(env: impl LedgerEnv + 'static + Clone) -> Vec<Test> {
    match supported_standards(&env).await {
        Ok(standard) => {
            let mut tests = vec![];
            if standard.iter().any(|std| std.name == "ICRC-1") {
                tests.append(&mut icrc1_test_suite(env.clone()));
            }
            if standard.iter().any(|std| std.name == "ICRC-2") {
                tests.append(&mut icrc2_test_suite(env));
            }
            tests
        }
        Err(_) => {
            println!("No standard is supported by the given ledger: Is the endpoint 'icrc1_supported_standards' implemented correctly?");
            vec![]
        }
    }
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
