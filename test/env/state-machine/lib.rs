use anyhow::Context;
use async_trait::async_trait;
use candid::utils::{decode_args, encode_args, ArgumentDecoder, ArgumentEncoder};
use candid::Principal;
use ic_test_state_machine_client::StateMachine;
use icrc1_test_env::LedgerEnv;
use rand::rngs::ThreadRng;
use rand::Rng;
use std::sync::{Arc, Mutex};

fn new_principal(n: u64) -> Principal {
    let mut bytes = n.to_le_bytes().to_vec();
    bytes.push(0xfe);
    bytes.push(0x01);
    Principal::try_from_slice(&bytes[..]).unwrap()
}

#[derive(Clone)]
pub struct SMLedger {
    rand: Arc<Mutex<ThreadRng>>,
    sm: Arc<StateMachine>,
    sender: Principal,
    canister_id: Principal,
}

#[async_trait(?Send)]
impl LedgerEnv for SMLedger {
    fn fork(&self) -> Self {
        Self {
            rand: self.rand.clone(),
            sm: self.sm.clone(),
            sender: new_principal(self.rand.lock().expect("failed to grab a lock").gen()),
            canister_id: self.canister_id,
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
            .update_call(self.canister_id, self.sender, method, in_bytes)
            .map_err(|err| anyhow::Error::msg(err.to_string()))
            .with_context(|| {
                format!(
                    "failed to execute update call {} on canister {}",
                    method, self.canister_id
                )
            })? {
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

impl SMLedger {
    pub fn new(sm: Arc<StateMachine>, canister_id: Principal, sender: Principal) -> Self {
        Self {
            rand: Arc::new(Mutex::new(rand::thread_rng())),
            sm,
            canister_id,
            sender,
        }
    }
}
