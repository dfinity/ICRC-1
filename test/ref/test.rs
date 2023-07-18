use candid::{CandidType, Decode, Encode, Nat, Principal};
use flate2::read::GzDecoder;
use ic_agent::Agent;
use ic_agent::Identity;
use ic_test_state_machine_client::StateMachine;
use icrc1_test_env::fresh_identity;
use icrc1_test_env::standard_replica_burn_fn;
use icrc1_test_env::standard_sm_burn_fn;
use icrc1_test_env::ReplicaLedger;
use icrc1_test_env::SMLedger;
use icrc1_test_replica::start_replica;
use ring::rand::SystemRandom;
use serde::{Deserialize, Serialize};
use std::env;
use std::fs;
use std::fs::File;
use std::os::unix::fs::PermissionsExt;
use std::path::Path;
use std::sync::Arc;
use std::time::Duration;

const REF_WASM: &[u8] = include_bytes!(env!("REF_WASM_PATH"));

#[derive(CandidType, Deserialize, Debug)]
struct Account {
    owner: Principal,
    subaccount: Option<[u8; 32]>,
}

#[derive(CandidType)]
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

fn unzip_file(file_path: &str, output_path: &str) {
    let file = File::open(file_path).unwrap();
    let mut decoder = GzDecoder::new(file);
    let mut output_file = File::create(output_path).unwrap();
    std::io::copy(&mut decoder, &mut output_file).unwrap();
}

pub static STATE_MACHINE_BINARY: &str = "../ic-test-state-machine";
fn sm_env() -> StateMachine {
    let path = match env::var_os("STATE_MACHINE_BINARY") {
        None => STATE_MACHINE_BINARY.to_string(),
        Some(path) => path
            .clone()
            .into_string()
            .unwrap_or_else(|_| panic!("Invalid string path for {path:?}")),
    };

    if !Path::new(&path).exists() {
        println!("
        Could not find state machine binary to run canister integration tests.

        I looked for it at {:?}. You can specify another path with the environment variable STATE_MACHINE_BINARY (note that I run from {:?}).

        Run the following command to get the binary:
            curl -sLO https://download.dfinity.systems/ic/$commit/binaries/$platform/ic-test-state-machine.gz
            gzip -d ic-test-state-machine.gz
            chmod +x ic-test-state-machine
        where $commit can be read from `.ic-commit` and $platform is 'x86_64-linux' for Linux and 'x86_64-darwin' for Intel/rosetta-enabled Darwin.
        ", &path, &env::current_dir().map(|x| x.display().to_string()).unwrap_or_else(|_| "an unknown directory".to_string()));
    }

    let new_path = env::temp_dir().join("ic-test-state-machine");
    unzip_file(
        &path,
        &new_path.clone().into_os_string().into_string().unwrap(),
    );

    // Get the current permissions
    let mut permissions = fs::metadata(new_path.clone()).unwrap().permissions();

    // Add the executable permission
    permissions.set_mode(permissions.mode() | 0o111);

    // Set the updated permissions
    fs::set_permissions(new_path.clone(), permissions).unwrap();

    StateMachine::new(&new_path.into_os_string().into_string().unwrap(), false)
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

    // The tests expect the parsed identity to have enough ICP to run the tests
    let init_arg = Encode!(&RefInitArg {
        initial_mints: vec![Mints {
            account: Account {
                owner: p1.sender().unwrap(),
                subaccount: None
            },
            amount: Nat::from(100_000_000)
        }],
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

    // We need to set the identity of the agent to that of what a user would parse
    agent.set_identity(p1);
    let env = ReplicaLedger::new(agent, canister_id, standard_replica_burn_fn);
    let tests = icrc1_test_suite::test_suite(env);

    if !icrc1_test_suite::execute_tests(tests).await {
        std::process::exit(1);
    }
}

async fn test_state_machine() {
    let sm_env = sm_env();

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
            amount: Nat::from(100_000_000)
        }],
        minting_account: Account {
            owner: minter.sender().unwrap(),
            subaccount: None
        },
        token_name: "Test token".to_string(),
        token_symbol: "XTK".to_string(),
        decimals: 8,
        transfer_fee: Nat::from(10_000),
    })
    .unwrap();
    let canister_id = sm_env.create_canister(Some(minter.sender().unwrap()));

    sm_env.install_canister(
        canister_id,
        (*REF_WASM).to_vec(),
        init_arg,
        Some(minter.sender().unwrap()),
    );

    let env = SMLedger::new(
        Arc::new(sm_env),
        canister_id,
        p1.sender().unwrap(),
        standard_sm_burn_fn,
    );

    let tests = icrc1_test_suite::test_suite(env);

    if !icrc1_test_suite::execute_tests(tests).await {
        std::process::exit(1);
    }
}

#[tokio::main]
async fn main() {
    test_replica().await;

    test_state_machine().await;
}
