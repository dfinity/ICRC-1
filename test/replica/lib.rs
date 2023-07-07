use ic_agent::agent::http_transport::ReqwestHttpReplicaV2Transport;
use ic_agent::identity::BasicIdentity;
use ic_agent::Agent;
use std::path::Path;
use std::process::{Child, Command};
use std::sync::Arc;
use tokio::time::{sleep, Duration};

struct KillOnDrop(Child);

pub struct ReplicaContext {
    _proc: KillOnDrop,
    _state: tempfile::TempDir,
    port: u16,
}

impl ReplicaContext {
    pub fn port(&self) -> u16 {
        self.port
    }
}

impl Drop for KillOnDrop {
    fn drop(&mut self) {
        let _ = self.0.kill();
    }
}

fn test_identity() -> BasicIdentity {
    BasicIdentity::from_pem(
        &b"-----BEGIN PRIVATE KEY-----
MFMCAQEwBQYDK2VwBCIEIJKDIfd1Ybt48Z23cVEbjL2DGj1P5iDYmthcrptvBO3z
oSMDIQCJuBJPWt2WWxv0zQmXcXMjY+fP0CJSsB80ztXpOFd2ZQ==
-----END PRIVATE KEY-----"[..],
    )
    .expect("failed to parse identity from PEM")
}

pub async fn start_replica(
    replica_bin: &Path,
    ic_starter_bin: &Path,
    sandbox_launcher_bin: &Path,
    canister_sandbox_bin: &Path,
) -> (Agent, ReplicaContext) {
    let state = tempfile::TempDir::new().expect("failed to create a temporary directory");

    let port_file = state.path().join("replica.port");

    assert!(
        ic_starter_bin.exists(),
        "ic-starter path {} does not exist",
        ic_starter_bin.display(),
    );
    assert!(
        replica_bin.exists(),
        "replica path {} does not exist",
        replica_bin.display(),
    );
    assert!(
        sandbox_launcher_bin.exists(),
        "sandbox_launcher path {} does not exist",
        sandbox_launcher_bin.display(),
    );
    assert!(
        canister_sandbox_bin.exists(),
        "canister_sandbox path {} does not exist",
        canister_sandbox_bin.display(),
    );

    let replica_path = format!(
        "{}:{}{}",
        sandbox_launcher_bin.parent().unwrap().display(),
        canister_sandbox_bin.parent().unwrap().display(),
        std::env::var("PATH").map_or("".into(), |s| format!(":{}", s)),
    );

    let mut cmd = Command::new(ic_starter_bin);
    cmd.env("RUST_MIN_STACK", "8192000")
        .env("PATH", replica_path)
        .arg("--replica-path")
        .arg(replica_bin)
        .arg("--state-dir")
        .arg(state.path())
        .arg("--create-funds-whitelist")
        .arg("*")
        .arg("--log-level")
        .arg("critical")
        .arg("--subnet-type")
        .arg("system")
        .arg("canister_sandboxing")
        .arg("--http-port-file")
        .arg(&port_file)
        .arg("--initial-notary-delay-millis")
        .arg("600");

    #[cfg(target_os = "macos")]
    cmd.args(["--consensus-pool-backend", "rocksdb"]);

    let _proc = KillOnDrop(
        cmd.stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .spawn()
            .unwrap_or_else(|e| {
                panic!(
                    "Failed to execute ic-starter (path = {}, exists? = {}): {}",
                    ic_starter_bin.display(),
                    ic_starter_bin.exists(),
                    e
                )
            }),
    );

    let mut tries_left = 100;
    while tries_left > 0 && !port_file.exists() {
        sleep(Duration::from_millis(100)).await;
        tries_left -= 1;
    }

    if !port_file.exists() {
        panic!("Port file does not exist");
    }

    let port_bytes = std::fs::read(&port_file).expect("failed to read port file");
    let port: u16 = String::from_utf8(port_bytes)
        .unwrap()
        .parse()
        .expect("failed to parse port");

    let client = reqwest::ClientBuilder::new()
        .build()
        .expect("failed to build an HTTP client");

    let transport = Arc::new(
        ReqwestHttpReplicaV2Transport::create_with_client(
            format!("http://localhost:{}", port),
            client,
        )
        .expect("failed to construct replica transport"),
    );

    let agent = Agent::builder()
        .with_transport(transport)
        .with_identity(test_identity())
        .build()
        .expect("failed to build agent");

    let mut tries_left = 100;
    let mut ok = false;
    let mut last_status = None;
    while tries_left > 0 && !ok {
        match agent.status().await {
            Ok(status) => {
                ok = status.replica_health_status == Some("healthy".to_string());
                if let Some(root_key) = status.root_key.as_ref() {
                    agent
                        .set_root_key(root_key.clone())
                        .expect("failed to set agent root key");
                }
                last_status = Some(status);
            }
            Err(_) => {
                sleep(Duration::from_millis(500)).await;
                tries_left -= 1;
            }
        }
    }

    if !ok {
        panic!(
            "Replica did not become healthy on port {}, status: {:?}",
            port, last_status
        );
    }

    (
        agent,
        ReplicaContext {
            _proc,
            _state: state,
            port,
        },
    )
}
