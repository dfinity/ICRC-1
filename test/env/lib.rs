use async_trait::async_trait;
use candid::utils::{ArgumentDecoder, ArgumentEncoder};
use candid::Principal;
use candid::{CandidType, Int, Nat};
use serde::Deserialize;
use std::fmt;

pub type Subaccount = [u8; 32];

#[derive(CandidType, Clone, Debug, Deserialize, Eq, PartialEq)]
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

#[derive(CandidType, Deserialize, PartialEq, Eq, Debug, Clone)]
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

#[derive(CandidType, Debug, Clone)]
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

#[derive(CandidType, Clone, Debug, PartialEq, Eq)]
pub struct ApproveArgs {
    pub from_subaccount: Option<Subaccount>,
    pub spender: Account,
    pub amount: Nat,
    pub expected_allowance: Option<Nat>,
    pub expires_at: Option<u64>,
    pub memo: Option<Vec<u8>>,
    pub fee: Option<Nat>,
    pub created_at_time: Option<u64>,
}

impl ApproveArgs {
    pub fn approve_amount(amount: impl Into<Nat>, spender: impl Into<Account>) -> Self {
        Self {
            amount: amount.into(),
            fee: None,
            created_at_time: None,
            memo: None,
            from_subaccount: None,
            spender: spender.into(),
            expected_allowance: None,
            expires_at: None,
        }
    }

    pub fn expected_allowance(mut self, expected_allowance: Nat) -> Self {
        self.expected_allowance = Some(expected_allowance);
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

    pub fn expires_at(mut self, time: u64) -> Self {
        self.expires_at = Some(time);
        self
    }

    pub fn memo(mut self, memo: impl Into<Vec<u8>>) -> Self {
        self.memo = Some(memo.into());
        self
    }
}

#[derive(CandidType, Deserialize, Clone, Debug, PartialEq, Eq)]
pub enum ApproveError {
    BadFee { expected_fee: Nat },
    InsufficientFunds { balance: Nat },
    AllowanceChanged { current_allowance: Nat },
    Expired { ledger_time: u64 },
    TooOld,
    CreatedInFuture { ledger_time: u64 },
    Duplicate { duplicate_of: Nat },
    TemporarilyUnavailable,
    GenericError { error_code: Nat, message: String },
}

#[derive(CandidType, Clone, Debug, PartialEq, Eq)]
pub struct TransferFromArgs {
    pub spender_subaccount: Option<Subaccount>,
    pub from: Account,
    pub to: Account,
    pub amount: Nat,
    pub fee: Option<Nat>,
    pub memo: Option<Vec<u8>>,
    pub created_at_time: Option<u64>,
}

impl TransferFromArgs {
    pub fn transfer_from(
        amount: impl Into<Nat>,
        to: impl Into<Account>,
        from: impl Into<Account>,
    ) -> Self {
        Self {
            spender_subaccount: None,
            amount: amount.into(),
            to: to.into(),
            fee: None,
            created_at_time: None,
            memo: None,
            from: from.into(),
        }
    }

    pub fn from_subaccount(mut self, spender_subaccount: Subaccount) -> Self {
        self.spender_subaccount = Some(spender_subaccount);
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

#[derive(CandidType, Deserialize, Clone, Debug, PartialEq, Eq)]
pub enum TransferFromError {
    BadFee { expected_fee: Nat },
    BadBurn { min_burn_amount: Nat },
    InsufficientFunds { balance: Nat },
    InsufficientAllowance { allowance: Nat },
    TooOld,
    CreatedInFuture { ledger_time: u64 },
    Duplicate { duplicate_of: Nat },
    TemporarilyUnavailable,
    GenericError { error_code: Nat, message: String },
}

#[derive(CandidType, Clone, Debug, PartialEq, Eq)]
pub struct AllowanceArgs {
    pub account: Account,
    pub spender: Account,
}

#[derive(CandidType, Deserialize, Clone, Debug, PartialEq, Eq)]
pub struct Allowance {
    pub allowance: Nat,
    #[serde(default)]
    pub expires_at: Option<u64>,
}

#[async_trait(?Send)]
pub trait LedgerEnv {
    /// Creates a new environment pointing to the same ledger but using a new caller.
    fn fork(&self) -> Self;

    /// Returns the caller's principal.
    fn principal(&self) -> Principal;

    /// Returns the approximation of the current ledger time.
    fn time(&self) -> std::time::SystemTime;

    /// Executes a query call with the specified arguments on the ledger.
    async fn query<Input, Output>(&self, method: &str, input: Input) -> anyhow::Result<Output>
    where
        Input: ArgumentEncoder + std::fmt::Debug,
        Output: for<'a> ArgumentDecoder<'a>;

    /// Executes an update call with the specified arguments on the ledger.
    async fn update<Input, Output>(&self, method: &str, input: Input) -> anyhow::Result<Output>
    where
        Input: ArgumentEncoder + std::fmt::Debug,
        Output: for<'a> ArgumentDecoder<'a>;
}

pub mod icrc1 {
    use crate::{
        Account, Allowance, AllowanceArgs, ApproveArgs, ApproveError, LedgerEnv, SupportedStandard,
        Transfer, TransferError, TransferFromArgs, TransferFromError, Value,
    };
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

    pub async fn approve(
        ledger: &impl LedgerEnv,
        arg: ApproveArgs,
    ) -> anyhow::Result<Result<Nat, ApproveError>> {
        ledger.update("icrc2_approve", (arg,)).await.map(|(t,)| t)
    }

    pub async fn transfer_from(
        ledger: &impl LedgerEnv,
        arg: TransferFromArgs,
    ) -> anyhow::Result<Result<Nat, TransferFromError>> {
        ledger
            .update("icrc2_transfer_from", (arg,))
            .await
            .map(|(t,)| t)
    }

    pub async fn allowance(
        ledger: &impl LedgerEnv,
        arg: AllowanceArgs,
    ) -> anyhow::Result<Allowance> {
        ledger.query("icrc2_allowance", (arg,)).await.map(|(t,)| t)
    }
}
