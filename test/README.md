# ICRC-1 acceptance test suite

This directory contains acceptance tests for ICRC-1 ledgers.
You'll need either Cargo (best installed via [rustup.rs](https://rustup.rs/)) or Bazel (best installed via [bazelisk](https://github.com/bazelbuild/bazelisk)) installed to run the test suite.

The test checks that a ledger with the specified `CANISTER_ID` deployed to a `REPLICA_URL` complies with the ICRC-1 specification, given that the account identified by a secret key encoded in `identity.pem` has enough funds to execute the test.

Execute the following command to rust the test suite:

```
# ==========
# With Cargo
# ==========

$ cargo run --bin icrc1-test-runner -- -u REPLICA_URL -c CANISTER_ID -s identity.pem

# ==========
# With Bazel
# ==========

$ bazel run //test/runner -- -u REPLICA_URL -c CANISTER_ID -s identity.pem

# for example

$ bazel run //test/runner -- -u http://localhost:9000 -c rrkah-fqaaa-aaaaa-aaaaq-cai -s ~/.config/dfx/identity/test/identity.pem
```
