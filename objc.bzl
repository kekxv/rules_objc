# objc.bzl

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

def _objc_rename_impl(ctx):
    outputs = []
    # 获取当前 package 的路径，例如 "tests"
    pkg_path = ctx.label.package
    
    for f in ctx.files.srcs + ctx.files.hdrs:
        # --- 计算相对路径 ---
        # 我们需要从 f.short_path 中剥离掉 repo 名和 package 名
        # 例如将 "rules_objc~/tests/sub/main.m" 变为 "sub/main.m"
        
        short_path = f.short_path
        
        # 处理 Bzlmod 下外部库路径包含 repo 前缀的情况
        if pkg_path:
            # 找到 package 路径在 short_path 中的位置，并截掉它及其之前的部分
            search_str = pkg_path + "/"
            index = short_path.find(search_str)
            if index != -1:
                # 只保留 package 之后的部分（支持子目录结构）
                rel_path = short_path[index + len(search_str):]
            else:
                # 如果找不到（文件就在 package 根目录），直接取文件名
                rel_path = f.basename
        else:
            # 如果是根目录 package
            rel_path = short_path

        # --- 根据后缀名生成影子文件 ---
        if f.extension == "m":
            out = ctx.actions.declare_file(rel_path + ".c")
        elif f.extension == "mm":
            out = ctx.actions.declare_file(rel_path + ".cc")
        else:
            out = ctx.actions.declare_file(rel_path)

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
