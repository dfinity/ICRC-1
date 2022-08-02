load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

DIDC_BUILD = """
package(default_visibility = ["//visibility:public"])
exports_files(["didc"])
"""

def _didc_impl(repository_ctx):
    os_name = repository_ctx.os.name
    if os_name == "linux":
        repository_ctx.download(
            url = "https://github.com/dfinity/candid/releases/download/2022-07-13/didc-linux64",
            sha256 = "e2bff62f20b23ef2164cb32cd1b7b728c72f5b5c3164a0f7b255e0419e1cbc24",
            executable = True,
            output = "didc",
        )
    elif os_name == "mac os x":
        repository_ctx.download(
            url = "https://github.com/dfinity/candid/releases/download/2022-07-13/didc-macos",
            sha256 = "c0b838eead15c9d6c213ec0078af926f20d4e077fb0725bfd88bf6c1c80b3881",
            executable = True,
            output = "didc",
        )
    else:
        fail("Unsupported operating system: " + os_name)

    repository_ctx.file("BUILD.bazel", DIDC_BUILD, executable = False)

didc_repository = repository_rule(
    implementation = _didc_impl,
    attrs = {},
)
