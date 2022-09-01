use candid::{CandidType, Decode, Encode, Nat};
use ic_agent::Agent;
use ic_types::Principal;
use icrc1_test_env::LedgerEnv;
use icrc1_test_replica::start_replica;
use serde::{Deserialize, Serialize};
use std::time::Duration;

const REF_WASM: &[u8] = include_bytes!(env!("REF_WASM_PATH"));

#[derive(CandidType)]
struct Account {
    owner: Principal,
    subaccount: Option<[u8; 32]>,
}

#[derive(CandidType)]
struct RefInitArg {
    initial_mints: Vec<(Account, Nat)>,
    minting_account: Account,
    token_name: String,
    token_symbol: String,
    decimals: u8,
    transfer_fee: Nat,
}

async fn install_canister(agent: &Agent, wasm: &[u8], init_arg: &[u8]) -> Principal {
    #[derive(CandidType, Deserialize)]
    struct CreateCanisterResult {
        canister_id: Principal,
    }

    #[derive(CandidType)]
    struct Settings {
        controllers: Option<Vec<Principal>>,
    }

    #[derive(CandidType)]
    struct CreateCanisterRequest {
        amount: Option<candid::Nat>,
        settings: Option<Settings>,
    }

    #[derive(CandidType, Serialize)]
    enum InstallMode {
        #[serde(rename = "install")]
        Install,
    }

    #[derive(CandidType, Serialize)]
    struct InstallCode<'a> {
        canister_id: Principal,
        mode: InstallMode,
        wasm_module: &'a [u8],
        arg: &'a [u8],
    }

    let waiter = garcon::Delay::builder()
        .throttle(Duration::from_millis(500))
        .timeout(Duration::from_secs(60 * 5))
        .build();

    let response_bytes = agent
        .update(
            &Principal::management_canister(),
            "provisional_create_canister_with_cycles",
        )
        .with_arg(
            Encode!(&CreateCanisterRequest {
                amount: Some(candid::Nat::from(1_000_000_000_000u64)),
                settings: Some(Settings {
                    controllers: Some(vec![agent.get_principal().unwrap()]),
                })
            })
            .unwrap(),
        )
        .call_and_wait(waiter.clone())
        .await
        .expect("failed to create a canister");

    let canister_id = Decode!(&response_bytes, CreateCanisterResult)
        .expect("failed to decode response")
        .canister_id;

    agent
        .update(&Principal::management_canister(), "install_code")
        .with_arg(
            Encode!(&InstallCode {
                canister_id,
                mode: InstallMode::Install,
                wasm_module: wasm,
                arg: init_arg,
            })
            .unwrap(),
        )
        .call_and_wait(waiter)
        .await
        .expect("failed to install canister");
    canister_id
}

#[tokio::test]
async fn main() {
    let replica_path =
        std::fs::canonicalize(std::env::var_os("IC_REPLICA_PATH").expect("missing replica binary"))
            .unwrap();

    let ic_starter_path = std::fs::canonicalize(
        std::env::var_os("IC_STARTER_PATH").expect("missing ic-starter binary"),
    )
    .unwrap();

    let (agent, _replica_context) = start_replica(&replica_path, &ic_starter_path).await;

    let init_arg = Encode!(&RefInitArg {
        initial_mints: vec![],
        minting_account: Account {
            owner: agent.get_principal().unwrap(),
            subaccount: None
        },
        token_name: "Test token".to_string(),
        token_symbol: "XTK".to_string(),
        decimals: 8,
        transfer_fee: Nat::from(10_000),
    })
    .unwrap();

    let canister_id = install_canister(&agent, REF_WASM, &init_arg).await;

    let env = LedgerEnv::new(agent, canister_id);
    let tests = icrc1_test_suite::test_suite(env);

    if !icrc1_test_suite::execute_tests(tests).await {
        std::process::exit(1);
    }
}
