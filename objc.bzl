# objc.bzl

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

def _objc_rename_impl(ctx):
    outputs = []
    # 建立影子目录结构
    for f in ctx.files.srcs + ctx.files.hdrs:
        # 使用 short_path 保留目录结构，例如 src/video/cocoa/xxx.m
        out_path = f.short_path
        if f.extension == "m":
            out = ctx.actions.declare_file(out_path + ".c")
        elif f.extension == "mm":
            out = ctx.actions.declare_file(out_path + ".cc")
        else:
            out = ctx.actions.declare_file(out_path)

        ctx.actions.symlink(output = out, target_file = f)
        outputs.append(out)
    return [DefaultInfo(files = depset(outputs))]

_objc_rename = rule(
    implementation = _objc_rename_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "hdrs": attr.label_list(allow_files = True),
    },
)

def objc_library(name, srcs = [], hdrs = [], deps = [], copts = [], **kwargs):
    # 将 .m 和头文件一起 symlink 到 shadow 目录
    _objc_rename(
        name = name + "_shadow",
        srcs = srcs,
        hdrs = hdrs,
    )

    # 使用 cc_library 进行编译，此时影子目录中的相对路径是正确的
    cc_library(
        name = name,
        srcs = [":" + name + "_shadow"],
        deps = deps,
        copts = copts + ["-x", "objective-c", "-fobjc-arc"],
        **kwargs
    )

def objc_binary(name, srcs = [], hdrs = [], deps = [], copts = [], **kwargs):
    _objc_rename(
        name = name + "_shadow_bin",
        srcs = srcs,
        hdrs = hdrs,
    )
    cc_binary(
        name = name,
        srcs = [":" + name + "_shadow_bin"],
        deps = deps,
        copts = copts + ["-x", "objective-c", "-fobjc-arc"],
        **kwargs
    )

def objc_test(name, srcs = [], hdrs = [], deps = [], copts = [], **kwargs):
    _objc_rename(
        name = name + "_shadow_test",
        srcs = srcs,
        hdrs = hdrs,
    )
    cc_test(
        name = name,
        srcs = [":" + name + "_shadow_test"],
        deps = deps,
        copts = copts + ["-x", "objective-c", "-fobjc-arc"],
        **kwargs
    )
