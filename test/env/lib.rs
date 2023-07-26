use async_trait::async_trait;
use candid::utils::{ArgumentDecoder, ArgumentEncoder};
use candid::Principal;
use candid::{CandidType, Int, Nat};
use serde::Deserialize;
use std::fmt;

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
pub trait LedgerEnv {
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

pub mod icrc1 {
    use crate::{Account, LedgerEnv, SupportedStandard, Transfer, TransferError, Value};
    use candid::Nat;

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
}
