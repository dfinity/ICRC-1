use anyhow::Context;
use async_trait::async_trait;
use candid::utils::{decode_args, encode_args, ArgumentDecoder, ArgumentEncoder};
use candid::Principal;
use candid::{CandidType, Int, Nat};
use ic_agent::identity::BasicIdentity;
use ic_agent::Agent;
use ring::rand::SystemRandom;
use serde::Deserialize;
use std::fmt;
use std::sync::{Arc, Mutex};

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

fn fresh_identity(rand: &SystemRandom) -> BasicIdentity {
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
pub trait Canister {
    async fn query<Input, Output>(&self, method: &str, input: Input) -> anyhow::Result<Output>
    where
        Input: ArgumentEncoder + std::fmt::Debug,
        Output: for<'a> ArgumentDecoder<'a>;
    async fn update<Input, Output>(&self, method: &str, input: Input) -> anyhow::Result<Output>
    where
        Input: ArgumentEncoder + std::fmt::Debug,
        Output: for<'a> ArgumentDecoder<'a>;
}

pub trait LedgerEnv {
    fn fork(&self) -> Self;
    fn principal(&self) -> Principal;
}

// #[async_trait(?Send)]
// pub trait LedgerTransactions{
//    async fn burn<F,Output,Input>(&self,ledger: &impl Canister, args:Input) -> Output
//         where Input: ArgumentEncoder + std::fmt::Debug,
//         Output: for<'a> ArgumentDecoder<'a>;
//     };

#[derive(Clone)]
pub struct ReplicaLedger {
    rand: Arc<Mutex<SystemRandom>>,
    agent: Arc<Agent>,
    canister_id: Principal,
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
        }
    }
    fn principal(&self) -> Principal {
        self.agent
            .get_principal()
            .expect("failed to get agent principal")
    }
}

#[async_trait(?Send)]
impl Canister for ReplicaLedger {
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
            .call_and_wait()
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
    pub fn new(agent: Agent, canister_id: Principal) -> Self {
        Self {
            rand: Arc::new(Mutex::new(SystemRandom::new())),
            agent: Arc::new(agent),
            canister_id,
        }
    }
}

pub async fn transfer(
    ledger: &Arc<impl Canister>,
    arg: Transfer,
) -> anyhow::Result<Result<Nat, TransferError>> {
    ledger.update("icrc1_transfer", (arg,)).await.map(|(t,)| t)
}

pub async fn balance_of(
    ledger: &Arc<impl Canister>,
    account: impl Into<Account>,
) -> anyhow::Result<Nat> {
    ledger
        .query("icrc1_balance_of", (account.into(),))
        .await
        .map(|(t,)| t)
}

pub async fn supported_standards(
    ledger: &Arc<impl Canister>,
) -> anyhow::Result<Vec<SupportedStandard>> {
    ledger
        .query("icrc1_supported_standards", ())
        .await
        .map(|(t,)| t)
}

pub async fn metadata(ledger: &Arc<impl Canister>) -> anyhow::Result<Vec<(String, Value)>> {
    ledger.query("icrc1_metadata", ()).await.map(|(t,)| t)
}

pub async fn minting_account(ledger: &Arc<impl Canister>) -> anyhow::Result<Option<Account>> {
    ledger
        .query("icrc1_minting_account", ())
        .await
        .map(|(t,)| t)
}

pub async fn token_name(ledger: &Arc<impl Canister>) -> anyhow::Result<String> {
    ledger.query("icrc1_name", ()).await.map(|(t,)| t)
}

pub async fn token_symbol(ledger: &Arc<impl Canister>) -> anyhow::Result<String> {
    ledger.query("icrc1_symbol", ()).await.map(|(t,)| t)
}

pub async fn token_decimals(ledger: &Arc<impl Canister>) -> anyhow::Result<u8> {
    ledger.query("icrc1_decimals", ()).await.map(|(t,)| t)
}

pub async fn transfer_fee(ledger: &Arc<impl Canister>) -> anyhow::Result<Nat> {
    ledger.query("icrc1_fee", ()).await.map(|(t,)| t)
}

// pub struct SMLedger {
//     sm: ic_state_machine_tests::StateMachine,
//     rand: Arc<Mutex<SystemRandom>>
// }
