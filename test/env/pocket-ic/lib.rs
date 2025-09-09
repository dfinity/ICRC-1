use anyhow::Context;
use async_trait::async_trait;
use candid::utils::{decode_args, encode_args, ArgumentDecoder, ArgumentEncoder};
use candid::Principal;
use icrc1_test_env::LedgerEnv;
use pocket_ic::nonblocking::PocketIc;
use std::convert::TryInto;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;

fn new_principal(n: u64) -> Principal {
    let mut bytes = n.to_le_bytes().to_vec();
    bytes.push(0xfe);
    bytes.push(0x01);
    Principal::try_from_slice(&bytes[..]).unwrap()
}

#[derive(Clone)]
pub struct PICLedger {
    counter: Arc<AtomicU64>,
    pic: Arc<PocketIc>,
    sender: Principal,
    canister_id: Principal,
}

#[async_trait(?Send)]
impl LedgerEnv for PICLedger {
    fn fork(&self) -> Self {
        Self {
            counter: self.counter.clone(),
            pic: self.pic.clone(),
            sender: new_principal(self.counter.fetch_add(1, Ordering::Relaxed)),
            canister_id: self.canister_id,
        }
    }

    fn principal(&self) -> Principal {
        self.sender
    }

    async fn time(&self) -> std::time::SystemTime {
        self.pic
            .get_time()
            .await
            .try_into()
            .expect("Failed to convert PocketIC time to SystemTime")
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
            .pic
            .query_call(self.canister_id, self.sender, method, in_bytes)
            .await
        {
            Ok(bytes) => decode_args(&bytes).with_context(|| {
                format!(
                    "Failed to decode method {} response into type {}, bytes: {}",
                    method,
                    std::any::type_name::<Output>(),
                    hex::encode(bytes)
                )
            }),
            Err(reject_response) => Err(anyhow::Error::msg(format!(
                "Query call to ledger {:?} was rejected: {}",
                self.canister_id, reject_response.reject_message
            ))),
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
            .pic
            .update_call(self.canister_id, self.sender, method, in_bytes)
            .await
        {
            Ok(bytes) => decode_args(&bytes).with_context(|| {
                format!(
                    "Failed to decode method {} response into type {}, bytes: {}",
                    method,
                    std::any::type_name::<Output>(),
                    hex::encode(&bytes)
                )
            }),
            Err(reject_response) => Err(anyhow::Error::msg(format!(
                "Update call to ledger {:?} was rejected: {}",
                self.canister_id, reject_response.reject_message
            ))),
        }
    }
}

impl PICLedger {
    pub fn new(pic: Arc<PocketIc>, canister_id: Principal, sender: Principal) -> Self {
        Self {
            counter: Arc::new(AtomicU64::new(0)),
            pic,
            canister_id,
            sender,
        }
    }
}
