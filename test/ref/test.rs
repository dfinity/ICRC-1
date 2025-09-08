use candid::Principal;
use candid::{CandidType, Decode, Encode, Nat};
use ic_agent::Agent;
use ic_agent::Identity;
use icrc1_test_env_pocket_ic::SMLedger;
use icrc1_test_env_replica::fresh_identity;
use icrc1_test_env_replica::ReplicaLedger;
use icrc1_test_replica::start_replica;
use pocket_ic::nonblocking::PocketIc;
use ring::rand::SystemRandom;
use serde::{Deserialize, Serialize};
use std::sync::Arc;

const REF_WASM: &[u8] = include_bytes!(env!("REF_WASM_PATH"));

#[derive(CandidType, Deserialize, Debug)]
struct Account {
    owner: Principal,
    subaccount: Option<[u8; 32]>,
}

#[derive(CandidType, Debug)]
struct Mints {
    account: Account,
    amount: Nat,
}

#[derive(CandidType)]
struct RefInitArg {
    initial_mints: Vec<Mints>,
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
        .call_and_wait()
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
        .call_and_wait()
        .await
        .expect("failed to install canister");
    canister_id
}

async fn pic_env() -> PocketIc {
    PocketIc::new().await
}

async fn test_replica() {
    let replica_path =
        std::fs::canonicalize(std::env::var_os("IC_REPLICA_PATH").expect("missing replica binary"))
            .unwrap();

    let ic_starter_path = std::fs::canonicalize(
        std::env::var_os("IC_STARTER_PATH").expect("missing ic-starter binary"),
    )
    .unwrap();

    let sandbox_launcher_path = std::fs::canonicalize(
        std::env::var_os("SANDBOX_LAUNCHER").expect("missing sandbox_launcher"),
    )
    .unwrap();

    let canister_sandbox_path = std::fs::canonicalize(
        std::env::var_os("CANISTER_SANDBOX").expect("missing canister_sandbox"),
    )
    .unwrap();

    let (mut agent, _replica_context) = start_replica(
        &replica_path,
        &ic_starter_path,
        &sandbox_launcher_path,
        &canister_sandbox_path,
    )
    .await;

    // We need a fresh identity to be used for the tests
    // This identity simulates the identity a user would parse to the binary
    let p1 = fresh_identity(&SystemRandom::new());

    let init_arg = Encode!(&RefInitArg {
        initial_mints: vec![Mints {
            account: Account {
                owner: p1.sender().unwrap(),
                subaccount: None
            },
            amount: Nat::from(100_000_000u32)
        }],
        minting_account: Account {
            owner: agent.get_principal().unwrap(),
            subaccount: None
        },
        token_name: "Test token".to_string(),
        token_symbol: "XTK".to_string(),
        decimals: 8,
        transfer_fee: Nat::from(10_000u16),
    })
    .unwrap();

    let canister_id = install_canister(&agent, REF_WASM, &init_arg).await;

    // We need to set the identity of the agent to that of what a user would parse
    agent.set_identity(p1);
    let env = ReplicaLedger::new(agent, canister_id);
    let tests = icrc1_test_suite::test_suite(env).await;

    if !icrc1_test_suite::execute_tests(tests).await {
        std::process::exit(1);
    }
}

async fn test_pocket_ic() {
    let pic = pic_env().await;
    // We need a fresh identity to be used for the tests
    // This identity simulates the identity a user would parse to the binary
    let minter = fresh_identity(&SystemRandom::new());
    let p1 = fresh_identity(&SystemRandom::new());

    // The tests expect the parsed identity to have enough ICP to run the tests
    let init_arg = Encode!(&RefInitArg {
        initial_mints: vec![Mints {
            account: Account {
                owner: p1.sender().unwrap(),
                subaccount: None
            },
            amount: Nat::from(100_000_000u32)
        }],
        minting_account: Account {
            owner: minter.sender().unwrap(),
            subaccount: None
        },
        token_name: "Test token".to_string(),
        token_symbol: "XTK".to_string(),
        decimals: 8,
        transfer_fee: Nat::from(10_000u16),
    })
    .unwrap();

    let canister_id = pic.create_canister().await;
    pic.add_cycles(canister_id, 1_000_000_000_000u128).await;

    pic.install_canister(canister_id, REF_WASM.to_vec(), init_arg, None)
        .await;

    let env = SMLedger::new(Arc::new(pic), canister_id, p1.sender().unwrap());

    let tests = icrc1_test_suite::test_suite(env).await;

    if !icrc1_test_suite::execute_tests(tests).await {
        std::process::exit(1);
    }
}

#[tokio::main]
async fn main() {
    test_pocket_ic().await;

    test_replica().await;
}
