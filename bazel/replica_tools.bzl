REPLICA_BUILD = """
package(default_visibility = ["//visibility:public"])

exports_files(["replica", "ic-starter", "canister_sandbox", "sandbox_launcher"])
"""

IC_COMMIT_HASH = "09c3000df0a54c470994ceb5bc33bd8457b02fe7"

BINARY_HASHES = {
    "ic-starter.gz": {
        "linux": "8d8c51033cb2cd20049ca4e048144b895684d7a4fdbd07719476797b53ebafb5",
        "mac os x": "1f33354049b6c83c8be06344d913a8bcfdb61ba9234706a8bf3cdb3d620723ab",
    },
    "replica.gz": {
        "linux": "2cd30cca1818b86785b3d9b808612b7c286252363806c70d196c2fcfa48d1188",
        "mac os x": "f320fec5733182e1ceb0dd03d19dc5bec01a1bf7763eb282e3fe14b1e1a6e18b",
    },
    "canister_sandbox.gz": {
        "linux": "11849a543a162f0f25b3dc10f17c177ea054e4fdb8a8c86509c7f87988ce2913",
        "mac os x": "4acdd46cf9b1e5be987f6ce72d0118bf9039162e3ff80cd32056da136f753011",
    },
    "sandbox_launcher.gz": {
        "linux": "96c416bf98724aa3bf72053d06d559f007f8655261b48f435f9104b605c8f77f",
        "mac os x": "ed0bc2eeaf282012c8475ddf1ca3369488dc80d385e5b194d2823ae84514ff8a",
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
