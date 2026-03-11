# objc.bzl

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

def _objc_rename_impl(ctx):
    outputs = []
    for src in ctx.files.srcs:
        # .m -> .c 这样 cc_library 不会注入 C++ 参数
        if src.extension == "m":
            out = ctx.actions.declare_file(src.basename + ".m.c")
            ctx.actions.symlink(output = out, target_file = src)
            outputs.append(out)
            # .mm -> .cc 这样可以接受 C++ 参数

        elif src.extension == "mm":
            out = ctx.actions.declare_file(src.basename + ".mm.cc")
            ctx.actions.symlink(output = out, target_file = src)
            outputs.append(out)
        else:
            outputs.append(src)
    return [DefaultInfo(files = depset(outputs))]

_objc_rename = rule(
    implementation = _objc_rename_impl,
    attrs = {"srcs": attr.label_list(allow_files = True)},
)

def objc_library(name, srcs = [], hdrs = [], deps = [], copts = [], **kwargs):
    # 分组
    m_files = [s for s in srcs if s.endswith(".m")]
    mm_files = [s for s in srcs if s.endswith(".mm")]
    native_files = [s for s in srcs if not (s.endswith(".m") or s.endswith(".mm"))]

    internal_deps = []

    # 处理纯 ObjC (.m)
    if m_files:
        m_name = name + "_m_part"
        _objc_rename(name = m_name + "_rename", srcs = m_files)
        cc_library(
            name = m_name,
            srcs = [":" + m_name + "_rename"],
            hdrs = hdrs,  # 包含头文件以允许 include
            deps = deps,
            copts = copts + ["-x", "objective-c", "-fobjc-arc"],
            includes = ["."],
            visibility = ["//visibility:private"],
            **kwargs
        )
        internal_deps.append(":" + m_name)

    # 处理 ObjC++ (.mm)
    if mm_files:
        mm_name = name + "_mm_part"
        _objc_rename(name = mm_name + "_rename", srcs = mm_files)
        cc_library(
            name = mm_name,
            srcs = [":" + mm_name + "_rename"],
            hdrs = hdrs,
            deps = deps,
            copts = copts + ["-x", "objective-c++", "-fobjc-arc"],
            includes = ["."],
            visibility = ["//visibility:private"],
            **kwargs
        )
        internal_deps.append(":" + mm_name)

    # 处理原生 C/C++ (.c, .cc)
    if native_files:
        native_part_name = name + "_native_part"
        cc_library(
            name = native_part_name,
            srcs = native_files,
            hdrs = hdrs,
            deps = deps,
            copts = copts,
            includes = ["."],
            visibility = ["//visibility:private"],
            **kwargs
        )
        internal_deps.append(":" + native_part_name)

    # 最终汇总的 cc_library
    cc_library(
        name = name,
        hdrs = hdrs,
        deps = deps + internal_deps,
        includes = ["."],
        **kwargs
    )

def objc_binary(name, srcs = [], deps = [], **kwargs):
    # binary 比较简单，直接把 srcs 处理后交给 cc_binary
    # 也可以复用上面的分拆逻辑，但通常 binary 源文件较少，我们直接处理：
    _objc_rename(name = name + "_rename_bin", srcs = srcs)

    # 简单的逻辑：如果有 .mm 就开 objc++，否则开 objc
    has_mm = any([s.endswith(".mm") for s in srcs])
    lang = "objective-c++" if has_mm else "objective-c"
    cc_binary(
        name = name,
        srcs = [":" + name + "_rename_bin"],
        deps = deps,
        copts = kwargs.pop("copts", []) + ["-x", lang, "-fobjc-arc"],
        includes = ["."],
        **kwargs
    )

def objc_test(name, srcs = [], deps = [], **kwargs):
    _objc_rename(name = name + "_rename_test", srcs = srcs)
    has_mm = any([s.endswith(".mm") for s in srcs])
    lang = "objective-c++" if has_mm else "objective-c"
    cc_test(
        name = name,
        srcs = [":" + name + "_rename_test"],
        deps = deps,
        copts = kwargs.pop("copts", []) + ["-x", lang, "-fobjc-arc"],
        includes = ["."],
        **kwargs
    )
