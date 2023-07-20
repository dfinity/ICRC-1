use candid::Principal;
use ic_agent::agent::http_transport::ReqwestHttpReplicaV2Transport;
use ic_agent::identity::BasicIdentity;
use ic_agent::Agent;
use icrc1_test_env::{standard_replica_burn_fn, ReplicaLedger};
use pico_args::Arguments;
use std::path::PathBuf;
use std::sync::Arc;

fn print_help() {
    println!(
        r#"{} OPTIONS
Options:
  -u, --url URL                The url of a replica hosting the ledger

  -c, --canister PRINCIPAL     The canister id of the ledger

  -s, --secret-key PATH        The path to the PEM file of the identity
                               holding enough funds for the test
"#,
        std::env::args().next().unwrap()
    )
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let mut args = Arguments::from_env();
    if args.contains(["-h", "--help"]) {
        print_help();
        std::process::exit(0);
    }

    let canister_id = args
        .value_from_fn(["-c", "--canister"], |s: &str| Principal::from_text(s))
        .unwrap_or_else(|e| {
            eprintln!("Failed to parse ledger canister id: {}", e);
            print_help();
            std::process::exit(1);
        });

    let url: String = args.value_from_str(["-u", "--url"]).unwrap_or_else(|e| {
        eprintln!("Failed to parse ledger URL: {}", e);
        print_help();
        std::process::exit(1);
    });

    let key_path: PathBuf = args
        .value_from_str(["-s", "--secret-key"])
        .unwrap_or_else(|e| {
            eprintln!("Failed to parse secret key path: {}", e);
            print_help();
            std::process::exit(1);
        });

    let identity = BasicIdentity::from_pem_file(&key_path).unwrap_or_else(|e| {
        panic!(
            "failed to parse secret key PEM from file {}: {}",
            key_path.display(),
            e
        )
    });

    let client = reqwest::ClientBuilder::new()
        .build()
        .expect("failed to build an HTTP client");

    let transport = Arc::new(
        ReqwestHttpReplicaV2Transport::create_with_client(url, client)
            .expect("failed to construct replica transport"),
    );

    let agent = Agent::builder()
        .with_transport(transport)
        .with_identity(identity)
        .build()
        .expect("failed to build agent");

    agent
        .fetch_root_key()
        .await
        .expect("agent failed to fetch the root key");

    let env = ReplicaLedger::new(agent, canister_id, standard_replica_burn_fn);
    let tests = icrc1_test_suite::test_suite_async(env);

    if !icrc1_test_suite::execute_async_tests(tests).await {
        std::process::exit(1);
    }
}
