REPLICA_BUILD = """
package(default_visibility = ["//visibility:public"])

exports_files(["replica", "ic-starter"])
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

_replica = repository_rule(
    implementation = _replica_impl,
    attrs = {},
)

def replica_tools_repository(name):
    _replica(name = name)
