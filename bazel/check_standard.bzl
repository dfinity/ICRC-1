"""
This module defines a macro for checking whether definitions from a markdown file match the candid interface.
"""

load(":didc_test.bzl", "didc_subtype_test")

def check_standard(name, md_file, candid_file):
    """Checks whether definitions from a markdown file match the candid interface.

    Args:
      name: the prefix for generated target names.
      md_file: the path to the markdown file with the standard definition.
      candid_file: the Candid file with the standardized interface.
    """
    generated_name = name + "_generated.did"

    native.genrule(
        name = generated_name,
        srcs = [md_file],
        outs = [generated_name],
        cmd_bash = "$(location @lmt) $(SRCS); mv \"{}\" $@".format(candid_file),
        exec_tools = ["@lmt"],
    )

    didc_subtype_test(
        name = name + "_check_generated_subtype",
        did = ":" + generated_name,
        previous = candid_file,
    )

    didc_subtype_test(
        name = name + "_check_source_subtype",
        did = candid_file,
        previous = ":" + generated_name,
    )
