REPLICA_BUILD = """
package(default_visibility = ["//visibility:public"])

exports_files(["replica", "ic-starter", "canister_sandbox", "sandbox_launcher","ic-test-state-machine"])
"""

def _replica_impl(repository_ctx):
    repository_ctx.report_progress("Fetching ic-starter")
    os_name = repository_ctx.os.name
    if os_name == "linux":
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/02138563741c87cefed2b223e31f25b59623307a/binaries/x86_64-linux/ic-starter.gz",
            sha256 = "b491c82cae8ebed2e1dc39dbc884c82ce2b4b5a3b67514e37c4edcaca65f296a",
            output = "ic-starter.gz",
        )
    elif os_name == "mac os x":
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/02138563741c87cefed2b223e31f25b59623307a/binaries/x86_64-darwin/ic-starter.gz",
            sha256 = "7f690883abeca846c29a84fd77340ce1812abeb2e23a48f30dcc961603cffd49",
            output = "ic-starter.gz",
        )
    else:
        fail("Unsupported operating system: " + os_name)

    ic_starter_path = repository_ctx.path("ic-starter.gz")
    repository_ctx.execute(["/usr/bin/gunzip", ic_starter_path])
    repository_ctx.execute(["chmod", "755", "ic-starter"])

    repository_ctx.report_progress("Fetching replica")
    if os_name == "linux":
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/02138563741c87cefed2b223e31f25b59623307a/binaries/x86_64-linux/replica.gz",
            sha256 = "12d1e52f240ec5c6c4a1b78c01e0dddcd05de93bcbec18c6d9b3fdbc5b5a713c",
            output = "replica.gz",
        )
    elif os_name == "mac os x":
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/02138563741c87cefed2b223e31f25b59623307a/binaries/x86_64-darwin/replica.gz",
            sha256 = "757def96a7efdbe05fb4291a8f8a9fda194965cfc5cec2edabb82fa825119b22",
            output = "replica.gz",
        )
    else:
        fail("Unsupported operating system: " + os_name)

    ic_replica_path = repository_ctx.path("replica.gz")
    repository_ctx.execute(["/usr/bin/gunzip", ic_replica_path])
    repository_ctx.execute(["chmod", "755", "replica"])
    repository_ctx.file("BUILD.bazel", REPLICA_BUILD, executable = False)

    repository_ctx.report_progress("Fetching canister_sandbox")
    if os_name == "linux":
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/02138563741c87cefed2b223e31f25b59623307a/binaries/x86_64-linux/canister_sandbox.gz",
            sha256 = "f4f3d4f1661adc6ba038af0723e7fc794fc38f445a7947a500305c5771442139",
            output = "canister_sandbox.gz",
        )
    elif os_name == "mac os x":
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/02138563741c87cefed2b223e31f25b59623307a/binaries/x86_64-darwin/canister_sandbox.gz",
            sha256 = "b60d3ea3534bb68acaa639d348a5354021d9a3a91271c3c6b0c964e2ee98de2b",
            output = "canister_sandbox.gz",
        )
    else:
        fail("Unsupported operating system: " + os_name)

    ic_canister_sandbox_path = repository_ctx.path("canister_sandbox.gz")
    repository_ctx.execute(["/usr/bin/gunzip", ic_canister_sandbox_path])
    repository_ctx.execute(["chmod", "755", "canister_sandbox"])
    
    repository_ctx.report_progress("Fetching ic-test-state-machine")
    if os_name == "linux":
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/2857a39ea4d991b2d5c8307623e00a5360eae84c/binaries/x86_64-linux/ic-test-state-machine.gz",
            sha256 = "213369060b47ac5fd6318e5a1fa3101b846d1baad2cd194ac486fa9979dfba1d",
            output = "ic-test-state-machine.gz",
        )
    elif os_name == "mac os x":
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/2857a39ea4d991b2d5c8307623e00a5360eae84c/binaries/x86_64-darwin/ic-test-state-machine.gz",
            sha256 = "213369060b47ac5fd6318e5a1fa3101b846d1baad2cd194ac486fa9979dfba1d",
            output = "ic-test-state-machine.gz",
        )
    else:
        fail("Unsupported operating system: " + os_name)

    ic_test_state_machine = repository_ctx.path("ic-test-state-machine.gz")
    repository_ctx.execute(["/usr/bin/gunzip", ic_test_state_machine])
    repository_ctx.execute(["chmod", "755", "ic-test-state-machine"])

    repository_ctx.report_progress("Fetching sandbox_launcher")
    if os_name == "linux":
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/02138563741c87cefed2b223e31f25b59623307a/binaries/x86_64-linux/sandbox_launcher.gz",
            sha256 = "eaacaab81203b6a8a34a5c96c413d4e2491c30e02a881597cb5cf62fe85146b8",
            output = "sandbox_launcher.gz",
        )
    elif os_name == "mac os x":
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/02138563741c87cefed2b223e31f25b59623307a/binaries/x86_64-darwin/sandbox_launcher.gz",
            sha256 = "8aaff3721cb239454e50f51a0fd0e8e7f834b379354f5a0f8d874ff1d805c0b0",
            output = "sandbox_launcher.gz",
        )
    else:
        fail("Unsupported operating system " + os_name)

    ic_sandbox_launcher_path = repository_ctx.path("sandbox_launcher.gz")
    repository_ctx.execute(["/usr/bin/gunzip", ic_sandbox_launcher_path])
    repository_ctx.execute(["chmod", "755", "sandbox_launcher"])

_replica = repository_rule(
    implementation = _replica_impl,
    attrs = {},
)

def replica_tools_repository(name):
    _replica(name = name)
