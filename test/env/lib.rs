use anyhow::Context;
use async_trait::async_trait;
use candid::utils::{decode_args, encode_args, ArgumentDecoder, ArgumentEncoder};
use candid::{CandidType, Int, Nat, Principal};
use ic_agent::identity::BasicIdentity;
use ic_agent::{Agent, Identity};
use ic_test_state_machine_client::StateMachine;
use icrc1::LedgerTransaction;
use ring::rand::SystemRandom;
use serde::Deserialize;
use std::fmt;
use std::pin::Pin;
use std::sync::{Arc, Mutex};
use std::time::Duration;

pub type Subaccount = [u8; 32];

#[derive(CandidType, Clone, Debug, Deserialize)]
pub struct Account {
    pub owner: Principal,
    pub subaccount: Option<Subaccount>,
}

impl From<Principal> for Account {
    fn from(owner: Principal) -> Self {
        Self {
            owner,
            subaccount: None,
        }
    }
}

#[derive(CandidType, Deserialize, PartialEq, Clone, Debug)]
pub struct SupportedStandard {
    pub name: String,
    pub url: String,
}

#[derive(CandidType, Clone, Debug, Deserialize, PartialEq)]
pub enum Value {
    Text(String),
    Blob(Vec<u8>),
    Nat(Nat),
    Int(Int),
}

#[derive(CandidType, Deserialize, Debug, Clone)]
pub enum TransferError {
    BadFee { expected_fee: Nat },
    BadBurn { min_burn_amount: Nat },
    InsufficientFunds { balance: Nat },
    TooOld,
    CreatedInFuture { ledger_time: u64 },
    Duplicate { duplicate_of: Nat },
    TemporarilyUnavailable,
    GenericError { error_code: Nat, message: String },
}

impl fmt::Display for TransferError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::BadFee { expected_fee } => write!(
                f,
                "Invalid transfer fee, the ledger expected fee {}",
                expected_fee
            ),
            Self::BadBurn { min_burn_amount } => write!(
                f,
                "Invalid burn amount, the minimal burn amount is {}",
                min_burn_amount
            ),
            Self::InsufficientFunds { balance } => write!(
                f,
                "The account owner doesn't have enough funds to for the transfer, balance: {}",
                balance
            ),
            Self::TooOld => write!(f, "created_at_time is too far in the past"),
            Self::CreatedInFuture { ledger_time } => write!(
                f,
                "created_at_time is too far in the future, ledger time: {}",
                ledger_time
            ),
            Self::Duplicate { duplicate_of } => write!(
                f,
                "the transfer is a duplicate of transaction {}",
                duplicate_of
            ),
            Self::TemporarilyUnavailable => write!(f, "the ledger is temporarily unavailable"),
            Self::GenericError {
                error_code,
                message,
            } => write!(f, "generic error (code {}): {}", error_code, message),
        }
    }
}

impl std::error::Error for TransferError {}

#[derive(CandidType, Debug)]
pub struct Transfer {
    from_subaccount: Option<Subaccount>,
    amount: Nat,
    to: Account,
    fee: Option<Nat>,
    created_at_time: Option<u64>,
    memo: Option<Vec<u8>>,
}

pub fn fresh_identity(rand: &SystemRandom) -> BasicIdentity {
    use ring::signature::Ed25519KeyPair as KeyPair;

    let doc = KeyPair::generate_pkcs8(rand).expect("failed to generate an ed25519 key pair");

    let key_pair = KeyPair::from_pkcs8(doc.as_ref())
        .expect("failed to construct a key pair from a pkcs8 document");

    BasicIdentity::from_key_pair(key_pair)
}

impl Transfer {
    pub fn amount_to(amount: impl Into<Nat>, to: impl Into<Account>) -> Self {
        Self {
            from_subaccount: None,
            amount: amount.into(),
            to: to.into(),
            fee: None,
            created_at_time: None,
            memo: None,
        }
    }

    pub fn from_subaccount(mut self, from_subaccount: Subaccount) -> Self {
        self.from_subaccount = Some(from_subaccount);
        self
    }

    pub fn fee(mut self, fee: impl Into<Nat>) -> Self {
        self.fee = Some(fee.into());
        self
    }

    pub fn created_at_time(mut self, time: u64) -> Self {
        self.created_at_time = Some(time);
        self
    }

    pub fn memo(mut self, memo: impl Into<Vec<u8>>) -> Self {
        self.memo = Some(memo.into());
        self
    }
}

#[async_trait(?Send)]
pub trait LedgerEnv: Clone {
    fn fork(&self) -> Self;
    fn principal(&self) -> Principal;
    async fn query<Input, Output>(&self, method: &str, input: Input) -> anyhow::Result<Output>
    where
        Input: ArgumentEncoder + std::fmt::Debug,
        Output: for<'a> ArgumentDecoder<'a>;
    async fn update<Input, Output>(&self, method: &str, input: Input) -> anyhow::Result<Output>
    where
        Input: ArgumentEncoder + std::fmt::Debug,
        Output: for<'a> ArgumentDecoder<'a>;
}

pub type BurnReturnType =
    Pin<Box<dyn std::future::Future<Output = anyhow::Result<Result<Nat, TransferError>>>>>;

pub type ReplicaBurnFn = fn(ReplicaLedger, Nat) -> BurnReturnType;

#[derive(Clone)]
pub struct ReplicaLedger {
    rand: Arc<Mutex<SystemRandom>>,
    agent: Arc<Agent>,
    canister_id: Principal,
    burn_fn: ReplicaBurnFn,
}

pub fn waiter() -> garcon::Delay {
    garcon::Delay::builder()
        .throttle(Duration::from_millis(500))
        .timeout(Duration::from_secs(60 * 5))
        .build()
}

#[async_trait(?Send)]
impl LedgerEnv for ReplicaLedger {
    fn fork(&self) -> Self {
        let mut agent = Arc::clone(&self.agent);
        Arc::make_mut(&mut agent).set_identity({
            let r = self.rand.lock().expect("failed to grab a lock");
            fresh_identity(&r)
        });
        Self {
            rand: Arc::clone(&self.rand),
            agent,
            canister_id: self.canister_id,
            burn_fn: self.burn_fn,
        }
    }
    fn principal(&self) -> candid::Principal {
        self.agent
            .get_principal()
            .expect("failed to get agent principal")
    }

    async fn query<Input, Output>(&self, method: &str, input: Input) -> anyhow::Result<Output>
    where
        Input: ArgumentEncoder + std::fmt::Debug,
        Output: for<'a> ArgumentDecoder<'a>,
    {
        let debug_inputs = format!("{:?}", input);
        let in_bytes = encode_args(input)
            .with_context(|| format!("Failed to encode arguments {}", debug_inputs))?;
        let bytes = self
            .agent
            .query(&self.canister_id, method)
            .with_arg(in_bytes)
            .call()
            .await
            .with_context(|| {
                format!(
                    "failed to call method {} on {} with args {}",
                    method, self.canister_id, debug_inputs
                )
            })?;

        decode_args(&bytes).with_context(|| {
            format!(
                "Failed to decode method {} response into type {}, bytes: {}",
                method,
                std::any::type_name::<Output>(),
                hex::encode(bytes)
            )
        })
    }

    async fn update<Input, Output>(&self, method: &str, input: Input) -> anyhow::Result<Output>
    where
        Input: ArgumentEncoder + std::fmt::Debug,
        Output: for<'a> ArgumentDecoder<'a>,
    {
        let debug_inputs = format!("{:?}", input);
        let in_bytes = encode_args(input)
            .with_context(|| format!("Failed to encode arguments {}", debug_inputs))?;
        let bytes = self
            .agent
            .update(&self.canister_id, method)
            .with_arg(in_bytes)
            .call_and_wait(waiter())
            .await
            .with_context(|| {
                format!(
                    "failed to call method {} on {} with args {}",
                    method, self.canister_id, debug_inputs
                )
            })?;

        decode_args(&bytes).with_context(|| {
            format!(
                "Failed to decode method {} response into type {}, bytes: {}",
                method,
                std::any::type_name::<Output>(),
                hex::encode(bytes)
            )
        })
    }
}

impl ReplicaLedger {
    pub fn new(agent: Agent, canister_id: Principal, burn_fn: ReplicaBurnFn) -> Self {
        Self {
            rand: Arc::new(Mutex::new(SystemRandom::new())),
            agent: Arc::new(agent),
            canister_id,
            burn_fn,
        }
    }
}

#[async_trait(?Send)]
impl LedgerTransaction for ReplicaLedger {
    async fn burn(&self, amount: Nat) -> anyhow::Result<Result<Nat, TransferError>> {
        (self.burn_fn)(self.clone(), amount).await
    }
}

pub type SMBurnFn = fn(SMLedger, Nat) -> BurnReturnType;

#[derive(Clone)]
pub struct SMLedger {
    rand: Arc<Mutex<SystemRandom>>,
    sm: Arc<StateMachine>,
    sender: Principal,
    canister_id: Principal,
    burn_fn: SMBurnFn,
}

#[async_trait(?Send)]
impl LedgerEnv for SMLedger {
    fn fork(&self) -> Self {
        Self {
            rand: self.rand.clone(),
            sm: self.sm.clone(),
            sender: fresh_identity(&self.rand.lock().expect("failed to grab a lock"))
                .sender()
                .unwrap(),
            canister_id: self.canister_id,
            burn_fn: self.burn_fn,
        }
    }
    fn principal(&self) -> Principal {
        self.sender
    }

    async fn query<Input, Output>(&self, method: &str, input: Input) -> anyhow::Result<Output>
    where
        Input: ArgumentEncoder + std::fmt::Debug,
        Output: for<'a> ArgumentDecoder<'a>,
    {
        let debug_inputs = format!("{:?}", input);
        let in_bytes = encode_args(input)
            .with_context(|| format!("Failed to encode arguments {}", debug_inputs))?;
        match self
            .sm
            .query_call(
                Principal::from_slice(self.canister_id.as_slice()),
                Principal::from_slice(self.sender.as_slice()),
                method,
                in_bytes,
            )
            .map_err(|err| anyhow::Error::msg(err.to_string()))?
        {
            ic_test_state_machine_client::WasmResult::Reply(bytes) => decode_args(&bytes)
                .with_context(|| {
                    format!(
                        "Failed to decode method {} response into type {}, bytes: {}",
                        method,
                        std::any::type_name::<Output>(),
                        hex::encode(bytes)
                    )
                }),
            ic_test_state_machine_client::WasmResult::Reject(msg) => {
                return Err(anyhow::Error::msg(format!(
                    "Query call to ledger {:?} was rejected: {}",
                    self.canister_id, msg
                )))
            }
        }
    }

    async fn update<Input, Output>(&self, method: &str, input: Input) -> anyhow::Result<Output>
    where
        Input: ArgumentEncoder + std::fmt::Debug,
        Output: for<'a> ArgumentDecoder<'a>,
    {
        let debug_inputs = format!("{:?}", input);
        let in_bytes = encode_args(input)
            .with_context(|| format!("Failed to encode arguments {}", debug_inputs))?;
        match self
            .sm
            .update_call(
                Principal::from_slice(self.canister_id.as_slice()),
                Principal::from_slice(self.sender.as_slice()),
                method,
                in_bytes,
            )
            .map_err(|err| anyhow::Error::msg(err.to_string()))?
        {
            ic_test_state_machine_client::WasmResult::Reply(bytes) => decode_args(&bytes)
                .with_context(|| {
                    format!(
                        "Failed to decode method {} response into type {}, bytes: {}",
                        method,
                        std::any::type_name::<Output>(),
                        hex::encode(bytes)
                    )
                }),
            ic_test_state_machine_client::WasmResult::Reject(msg) => {
                return Err(anyhow::Error::msg(format!(
                    "Query call to ledger {:?} was rejected: {}",
                    self.canister_id, msg
                )))
            }
        }
    }
}

#[async_trait(?Send)]
impl LedgerTransaction for SMLedger {
    async fn burn(&self, amount: Nat) -> anyhow::Result<Result<Nat, TransferError>> {
        (self.burn_fn)(self.clone(), amount).await
    }
}

impl SMLedger {
    pub fn new(
        sm: Arc<StateMachine>,
        canister_id: Principal,
        sender: Principal,
        burn_fn: SMBurnFn,
    ) -> Self {
        Self {
            rand: Arc::new(Mutex::new(SystemRandom::new())),
            sm,
            canister_id,
            sender,
            burn_fn,
        }
    }
}

pub mod icrc1 {
    use crate::{Account, LedgerEnv, SupportedStandard, Transfer, TransferError, Value};
    use async_trait::async_trait;
    use candid::Nat;

    #[async_trait(?Send)]
    pub trait LedgerTransaction {
        async fn burn(&self, amount: Nat) -> anyhow::Result<Result<Nat, TransferError>>;
    }

    pub async fn transfer(
        ledger: &impl LedgerEnv,
        arg: Transfer,
    ) -> anyhow::Result<Result<Nat, TransferError>> {
        ledger.update("icrc1_transfer", (arg,)).await.map(|(t,)| t)
    }

    pub async fn balance_of(
        ledger: &impl LedgerEnv,
        account: impl Into<Account>,
    ) -> anyhow::Result<Nat> {
        ledger
            .query("icrc1_balance_of", (account.into(),))
            .await
            .map(|(t,)| t)
    }

    pub async fn supported_standards(
        ledger: &impl LedgerEnv,
    ) -> anyhow::Result<Vec<SupportedStandard>> {
        ledger
            .query("icrc1_supported_standards", ())
            .await
            .map(|(t,)| t)
    }

    pub async fn metadata(ledger: &impl LedgerEnv) -> anyhow::Result<Vec<(String, Value)>> {
        ledger.query("icrc1_metadata", ()).await.map(|(t,)| t)
    }

    pub async fn minting_account(ledger: &impl LedgerEnv) -> anyhow::Result<Option<Account>> {
        ledger
            .query("icrc1_minting_account", ())
            .await
            .map(|(t,)| t)
    }

    pub async fn token_name(ledger: &impl LedgerEnv) -> anyhow::Result<String> {
        ledger.query("icrc1_name", ()).await.map(|(t,)| t)
    }

    pub async fn token_symbol(ledger: &impl LedgerEnv) -> anyhow::Result<String> {
        ledger.query("icrc1_symbol", ()).await.map(|(t,)| t)
    }

    pub async fn token_decimals(ledger: &impl LedgerEnv) -> anyhow::Result<u8> {
        ledger.query("icrc1_decimals", ()).await.map(|(t,)| t)
    }

    pub async fn transfer_fee(ledger: &impl LedgerEnv) -> anyhow::Result<Nat> {
        ledger.query("icrc1_fee", ()).await.map(|(t,)| t)
    }

    pub async fn total_supply(ledger: &impl LedgerEnv) -> anyhow::Result<Nat> {
        ledger.query("icrc1_total_supply", ()).await.map(|(t,)| t)
    }
}

pub fn standard_replica_burn_fn(ledger_env: ReplicaLedger, amount: Nat) -> BurnReturnType {
    // This method panics if it is called but burning is not supported by the given icrc1 ledger
    Box::pin(async move { standard_burn_fn(ledger_env, amount).await })
}

async fn standard_burn_fn(
    ledger_env: impl LedgerEnv,
    amount: Nat,
) -> anyhow::Result<Result<Nat, TransferError>> {
    let minting_account: Account = ledger_env
        .query::<(), (Option<Account>,)>("icrc1_minting_account", ())
        .await
        .map(|(t,)| t)
        .unwrap()
        .unwrap();
    let res = ledger_env
        .update(
            "icrc1_transfer",
            (Transfer::amount_to(amount, minting_account.owner),),
        )
        .await
        .map(|(t,)| t)
        .unwrap();
    Ok(res)
}

pub fn standard_sm_burn_fn(ledger_env: SMLedger, amount: Nat) -> BurnReturnType {
    // This method panics if it is called but burning is not supported by the given icrc1 ledger
    Box::pin(async move { standard_burn_fn(ledger_env, amount).await })
}
