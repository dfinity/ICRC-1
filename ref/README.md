# Reference implementation

This directory contains a reference implementation of the ICRC-1 standard in [Motoko](https://internetcomputer.org/docs/current/developer-docs/build/languages/motoko/).
The goal of this implementation is to faithfully implement all the features of the standard in the most straightforward way.
This implementation is not suitable for production use.

# Building the code

  1. Install the [Bazel](https://bazel.build/) build system.
     [Bazelisk](https://github.com/bazelbuild/bazelisk) is an easy way to get Bazel on your system.
  2. Build the canister module
             bazel build //ref:icrc1_ref
  3. Find the canister module at `bazel-bin/ref/icrc1_ref.wasm`.
