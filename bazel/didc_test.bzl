def _didc_check_impl(ctx):
    didc = ctx.executable._didc
    script = "\n".join(
        ["err=0"] +
        [didc.path + " check " + f.short_path + " || err=1" for f in ctx.files.srcs] +
        ["exit $err"],
    )

    ctx.actions.write(output = ctx.outputs.executable, content = script)

    files = depset(direct = ctx.files.srcs + [didc])
    runfiles = ctx.runfiles(files = files.to_list())

    return [DefaultInfo(runfiles = runfiles)]

DIDC_ATTR = attr.label(
    default = Label("@didc"),
    executable = True,
    allow_single_file = True,
    cfg = "exec",
)

didc_check_test = rule(
    implementation = _didc_check_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "_didc": DIDC_ATTR,
    },
    test = True,
)

def _didc_subtype_check_impl(ctx):
    didc = ctx.executable._didc
    script = """
{didc} check {did} {previous}
    """.format(didc = didc.path, did = ctx.file.did.short_path, previous = ctx.file.previous.short_path)

    ctx.actions.write(output = ctx.outputs.executable, content = script)

    files = depset(direct = [didc, ctx.file.did, ctx.file.previous])
    runfiles = ctx.runfiles(files = files.to_list())

    return [DefaultInfo(runfiles = runfiles)]

didc_subtype_test = rule(
    implementation = _didc_subtype_check_impl,
    attrs = {
        "did": attr.label(allow_single_file = True),
        "previous": attr.label(allow_single_file = True),
        "_didc": DIDC_ATTR,
    },
    test = True,
)
