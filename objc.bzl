# objc.bzl

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

def _objc_rename_impl(ctx):
    outputs = []
    # Get the current package path (e.g., "tests" or "src/video")
    package_path = ctx.label.package
    
    for f in ctx.files.srcs:
        if f.extension in ["m", "mm"]:
            # 1. Calculate the path relative to the current package.
            # In Bzlmod, f.short_path might look like 'rules_objc~/tests/main.m'.
            # We need to strip the repository prefix and the package path to use it in declare_file.
            short_path = f.short_path
            
            # Find the position of the package path to extract the sub-path
            # For example: 'external/rules_objc~/tests/subdir/main.m' -> 'subdir/main.m'
            if package_path == "":
                # Root package case
                rel_path = short_path.split("/")[-1] if "/" in short_path and "~" in short_path else short_path
            else:
                search_str = package_path + "/"
                index = short_path.find(search_str)
                if index != -1:
                    rel_path = short_path[index + len(search_str):]
                else:
                    # Fallback to basename if package path isn't found in short_path
                    rel_path = f.basename

            # 2. Declare the stub file with the correct extension
            ext = ".c" if f.extension == "m" else ".cc"
            out = ctx.actions.declare_file(rel_path + ext)
            
            # 3. Calculate the include path relative to the repository root.
            # f.path is the execution path. workspace_root is 'external/repo_name' for external repos.
            include_path = f.path
            workspace_root = f.owner.workspace_root
            if workspace_root and include_path.startswith(workspace_root + "/"):
                include_path = include_path[len(workspace_root + "/"):]

            # 4. Generate the stub content referencing the original file
            ctx.actions.write(
                output = out,
                content = '#include "%s"\n' % include_path,
            )
            outputs.append(out)
            
    return [DefaultInfo(files = depset(outputs))]

_objc_rename = rule(
    implementation = _objc_rename_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
    },
)

def _objc_common(name, rule_fn, srcs = [], hdrs = [], deps = [], copts = [], **kwargs):
    # Determine if we are compiling Objective-C or Objective-C++
    has_mm = False
    if type(srcs) == "list":
        has_mm = any([s.endswith(".mm") for s in srcs])
    lang = "objective-c++" if has_mm else "objective-c"

    # Generate the stub .c/.cc files
    _objc_rename(
        name = name + "_stubs",
        srcs = srcs,
    )

    rule_fn(
        name = name,
        srcs = [":" + name + "_stubs"],
        # Use textual_hdrs to ensure original sources are available in the sandbox
        # during compilation of the stub files.
        textual_hdrs = srcs + hdrs,
        deps = deps,
        copts = copts + ["-x", lang, "-fobjc-arc"],
        **kwargs
    )

def objc_library(name, **kwargs):
    _objc_common(name, cc_library, **kwargs)

def objc_binary(name, **kwargs):
    _objc_common(name, cc_binary, **kwargs)

def objc_test(name, **kwargs):
    _objc_common(name, cc_test, **kwargs)
