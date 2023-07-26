REPLICA_BUILD = """
package(default_visibility = ["//visibility:public"])

exports_files(["replica", "ic-starter", "canister_sandbox", "sandbox_launcher","ic-test-state-machine"])
"""

IC_COMMIT_HASH = "02138563741c87cefed2b223e31f25b59623307a"

BINARY_HASHES = {
    "ic-starter.gz": {
        "linux": "b491c82cae8ebed2e1dc39dbc884c82ce2b4b5a3b67514e37c4edcaca65f296a",
        "mac os x": "7f690883abeca846c29a84fd77340ce1812abeb2e23a48f30dcc961603cffd49",
    },
    "replica.gz": {
        "linux": "12d1e52f240ec5c6c4a1b78c01e0dddcd05de93bcbec18c6d9b3fdbc5b5a713c",
        "mac os x": "757def96a7efdbe05fb4291a8f8a9fda194965cfc5cec2edabb82fa825119b22",
    },
    "canister_sandbox.gz": {
        "linux": "f4f3d4f1661adc6ba038af0723e7fc794fc38f445a7947a500305c5771442139",
        "mac os x": "b60d3ea3534bb68acaa639d348a5354021d9a3a91271c3c6b0c964e2ee98de2b",
    },
    "sandbox_launcher.gz": {
        "linux": "eaacaab81203b6a8a34a5c96c413d4e2491c30e02a881597cb5cf62fe85146b8",
        "mac os x": "8aaff3721cb239454e50f51a0fd0e8e7f834b379354f5a0f8d874ff1d805c0b0",
    },
    "ic-test-state-machine.gz": {
        "linux": "0e29029a7774ea19a37dd670ce105cb54b7e492f246f95adc506b95a32ade8ab",
        "mac os x": "3d9bbee8f92b4aaf48e1e390689ea96797fe9cb379fcd803bdfef36393d1233a",
    },
}

def _replica_impl(repository_ctx):
    repository_ctx.report_progress("Fetching ic-starter")
    os_name = repository_ctx.os.name
    ic_arch = ""
    if os_name == "linux":
        ic_arch = "x86_64-linux"
    elif os_name == "mac os x":
        ic_arch = "x86_64-darwin"
    else:
        fail("Unsupported operating system: " + os_name)

    repository_ctx.file("BUILD.bazel", REPLICA_BUILD, executable = False)

    for (bin_name, os_to_hash) in BINARY_HASHES.items():
        repository_ctx.report_progress("Fetching " + bin_name)
        repository_ctx.download(
            url = "https://download.dfinity.systems/ic/{commit}/binaries/{ic_arch}/{bin_name}".format(commit = IC_COMMIT_HASH, ic_arch = ic_arch, bin_name = bin_name),
            sha256 = os_to_hash[os_name],
            output = bin_name,
        )
        bin_path = repository_ctx.path(bin_name)
        repository_ctx.execute(["/usr/bin/gunzip", bin_path])
        repository_ctx.execute(["chmod", "755", bin_name.removesuffix(".gz")])

_replica = repository_rule(
    implementation = _replica_impl,
    attrs = {},
)

def replica_tools_repository(name):
    _replica(name = name)
