use anyhow::Context;
use async_trait::async_trait;
use candid::utils::{decode_args, encode_args, ArgumentDecoder, ArgumentEncoder};
use candid::Principal;
use ic_agent::identity::BasicIdentity;
use ic_agent::Agent;
use icrc1_test_env::LedgerEnv;
use ring::rand::SystemRandom;
use std::sync::{Arc, Mutex};
use std::time::SystemTime;

pub fn fresh_identity(rand: &SystemRandom) -> BasicIdentity {
    use ring::signature::Ed25519KeyPair as KeyPair;

    let doc = KeyPair::generate_pkcs8(rand).expect("failed to generate an ed25519 key pair");

    let key_pair = KeyPair::from_pkcs8(doc.as_ref())
        .expect("failed to construct a key pair from a pkcs8 document");
    BasicIdentity::from_key_pair(key_pair)
}

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

    fn time(&self) -> SystemTime {
        // The replica relies on the system time by default.
        // Unfortunately, this assumption might break during the time
        // shifts, but it's probably good enough for tests.
        SystemTime::now()
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
