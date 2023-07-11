use anyhow::{bail, Context};
use candid::Nat;
use futures::StreamExt;
use icrc1_test_env::{Account, LedgerEnv, Transfer, Value};
use std::future::Future;
use std::pin::Pin;

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
    env: &impl LedgerEnv,
    account: impl Into<Account>,
    expected: impl Into<Nat>,
) -> anyhow::Result<()> {
    let account = account.into();
    let actual = env.balance_of(account.clone()).await?;
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

/// Checks whether the ledger supports token transfers and handles
/// default sub accounts correctly.
pub async fn test_transfer(env: impl LedgerEnv) -> TestResult {
    let receiver_env = env.fork();
    let receiver = receiver_env.principal();

    let amount = 10_000;

    let _tx = env
        .transfer(Transfer::amount_to(amount, receiver))
        .await
        .with_context(|| format!("failed to transfer {} tokens to {}", amount, receiver))?;

    assert_balance(
        &env,
        Account {
            owner: receiver,
            subaccount: None,
        },
        amount,
    )
    .await?;

    assert_balance(&env, Account{ owner: receiver, subaccount: Some([0; 32]) }, amount)
        .await
        .context("the ledger does not treat accounts with an empty subaccount as accounts with the default subaccount")?;

    Ok(Outcome::Passed)
}

/// Checks whether the ledger supports token burns.
/// Skips the checks if the ledger does not have a minting account.
pub async fn test_burn(env: impl LedgerEnv) -> TestResult {
    let minting_account = match env.minting_account().await? {
        Some(account) => account,
        None => {
            return Ok(Outcome::Skipped {
                reason: "the ledger does not support burn transactions".to_string(),
            });
        }
    };

    assert_balance(&env, minting_account.clone(), 0)
        .await
        .context("minting account cannot hold any funds")?;

    let burn_amount = Nat::from(10_000) + env.transfer_fee().await?;
    let tmp_account_env = env.fork();
    let tmp_account = tmp_account_env.principal();

    env.transfer(Transfer::amount_to(burn_amount.clone(), tmp_account))
        .await?
        .context("failed to transfer funds to a temporary account")?;

    assert_balance(&env, tmp_account, burn_amount.clone()).await?;

    let _tx = tmp_account_env
        .transfer(Transfer::amount_to(burn_amount, minting_account.clone()).fee(0))
        .await
        .context("failed to burn tokens");

    assert_balance(&env, tmp_account, 0).await?;
    assert_balance(&env, minting_account, 0).await?;

    Ok(Outcome::Passed)
}

/// Checks whether the ledger metadata entries agree with named methods.
pub async fn test_metadata(env: impl LedgerEnv) -> TestResult {
    let mut metadata = env.metadata().await?;
    metadata.sort_by(|l, r| l.0.cmp(&r.0));

    for ((k1, _), (k2, _)) in metadata.iter().zip(metadata.iter().skip(1)) {
        if k1 == k2 {
            bail!("Key {} is duplicated in the metadata", k1);
        }
    }

    if let Some(name) = lookup(&metadata, "icrc1:name") {
        assert_equal(&Value::Text(env.token_name().await?), name)
            .context("icrc1:name metadata entry does not match the icrc1_name endpoint")?;
    }
    if let Some(sym) = lookup(&metadata, "icrc1:symbol") {
        assert_equal(&Value::Text(env.token_symbol().await?), sym)
            .context("icrc1:symol metadata entry does not match the icrc1_symbol endpoint")?;
    }
    if let Some(meta_decimals) = lookup(&metadata, "icrc1:decimals") {
        let decimals = env.token_decimals().await?;
        assert_equal(&Value::Nat(Nat::from(decimals)), meta_decimals)
            .context("icrc1:decimals metadata entry does not match the icrc1_decimals endpoint")?;
    }
    if let Some(fee) = lookup(&metadata, "icrc1:fee") {
        assert_equal(&Value::Nat(env.transfer_fee().await?), fee)
            .context("icrc1:fee metadata entry does not match the icrc1_fee endpoint")?;
    }
    Ok(Outcome::Passed)
}

/// Checks whether the ledger advertizes support for ICRC-1 standard.
pub async fn test_supported_standards(env: impl LedgerEnv) -> anyhow::Result<Outcome> {
    let stds = env.supported_standards().await?;
    if !stds.iter().any(|std| std.name == "ICRC-1") {
        bail!("The ledger does not claim support for ICRC-1: {:?}", stds);
    }

    Ok(Outcome::Passed)
}

/// Returns the entire list of tests.
pub fn test_suite(env: impl LedgerEnv + 'static + Clone) -> Vec<Test> {
    vec![
        test("basic:transfer", test_transfer(env.clone())),
        test("basic:burn", test_burn(env.clone())),
        test("basic:metadata", test_metadata(env.clone())),
        test("basic:supported_standards", test_supported_standards(env)),
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
