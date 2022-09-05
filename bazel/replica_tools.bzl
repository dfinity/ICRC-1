REPLICA_BUILD = """
package(default_visibility = ["//visibility:public"])

exports_files(["replica", "ic-starter"])
"""

def _replica_impl(repository_ctx):
    repository_ctx.report_progress("Fetching ic-starter")
    os_name = repository_ctx.os.name
    if os_name == "linux":
        repository_ctx.download(
            url = "https://download.dfinity.systems/blessed/ic/d004accc3904e24dddb13a11d93451523e1a8a5f/sdk-release/x86_64-linux/ic-starter.gz",
            sha256 = "972ee8bac0e7f1e7e73c21899411671193dbb0c0b911d19a51f8f68e469853bc",
            output = "ic-starter.gz",
        )
    elif os_name == "mac os x":
        repository_ctx.download(
            url = "https://download.dfinity.systems/blessed/ic/d004accc3904e24dddb13a11d93451523e1a8a5f/sdk-release/x86_64-darwin/ic-starter.gz",
            sha256 = "61d647fc196c38352510d079ca0482de54abab4df4b13bd4d0ce301ed024c1e1",
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
            url = "https://download.dfinity.systems/blessed/ic/d004accc3904e24dddb13a11d93451523e1a8a5f/sdk-release/x86_64-linux/replica.gz",
            sha256 = "6e95796ebbeecf74916a56633fdceb56d9575b698fdf40984d35c674454b96a8",
            output = "replica.gz",
        )
    elif os_name == "mac os x":
        repository_ctx.download(
            url = "https://download.dfinity.systems/blessed/ic/d004accc3904e24dddb13a11d93451523e1a8a5f/sdk-release/x86_64-darwin/replica.gz",
            sha256 = "000d30a2720cb87fdd1114b50cf60dcb2246102ce66a59a53e3a8694733f1710",
            output = "replica.gz",
        )
    else:
        fail("Unsupported operating system: " + os_name)

    ic_replica_path = repository_ctx.path("replica.gz")
    repository_ctx.execute(["/usr/bin/gunzip", ic_replica_path])
    repository_ctx.execute(["chmod", "755", "replica"])
    repository_ctx.file("BUILD.bazel", REPLICA_BUILD, executable = False)

_replica = repository_rule(
    implementation = _replica_impl,
    attrs = {},
)

def replica_tools_repository(name):
    _replica(name = name)
