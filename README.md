# rules_objc (Simplified Objective-C for Bazel)

[中文版](#rules_objc-bazel-的简化版-objective-c-支持)

This project provides a simple set of Bazel macros to support Objective-C (`.m`) and Objective-C++ (`.mm`) compilation using `rules_cc`.

## Features

- **`objc_library`**: A macro to compile Objective-C libraries. It automatically handles `.m`, `.mm`, and native C/C++ files.
- **`objc_binary`**: A macro to compile Objective-C executable binaries.
- **ARC Support**: Automatically enables Automatic Reference Counting (`-fobjc-arc`).
- **Seamless Integration**: Built on top of `rules_cc`, allowing easy dependency management between C++ and Objective-C.

## Why the File Renaming?

Bazel's `rules_cc` has specific default behaviors for different file extensions. To ensure full control over compilation flags (like avoiding unwanted C++ flags for pure `.m` files), `objc.bzl` uses a trick:
1. It symlinks `.m` files to `.m.c`.
2. it symlinks `.mm` files to `.mm.cc`.
3. It then tells the compiler to treat these files as Objective-C or Objective-C++ using the `-x` flag.

## Usage

### 1. In your `BUILD.bazel`

Load the macros from `objc.bzl`:

```python
load("//:objc.bzl", "objc_binary", "objc_library")

objc_library(
    name = "math_utils",
    srcs = ["add.m", "sub.m"],
    hdrs = ["math_utils.h"]
)

objc_binary(
    name = "hello",
    srcs = ["main.m"],
    deps = [":math_utils"]
)
```

### 2. Implementation Details

- **`objc_library`**: Internal parts are split into `_m_part` and `_mm_part` if both types are present. This ensures that the correct compiler flags are applied to each group.
- **`objc_binary`**: Simplifies the process for binaries, automatically detecting if Objective-C++ is needed based on the presence of `.mm` files.

---

# rules_objc (Bazel 的简化版 Objective-C 支持)

该项目提供了一组简单的 Bazel 宏，用于利用 `rules_cc` 支持 Objective-C (`.m`) 和 Objective-C++ (`.mm`) 的编译。

## 特性

- **`objc_library`**: 用于编译 Objective-C 库的宏。自动处理 `.m`、`.mm` 以及原生 C/C++ 文件。
- **`objc_binary`**: 用于编译 Objective-C 可执行二进制文件的宏。
- **ARC 支持**: 自动开启自动引用计数 (`-fobjc-arc`)。
- **无缝集成**: 基于 `rules_cc` 构建，方便 C++ 与 Objective-C 之间的依赖管理。

## 为什么要重命名文件？

Bazel 的 `rules_cc` 对不同的文件扩展名有特定的默认行为。为了确保对编译标志的完全控制（例如避免为纯 `.m` 文件注入不需要的 C++ 标志），`objc.bzl` 使用了一个技巧：
1. 将 `.m` 文件软链接为 `.m.c`。
2. 将 `.mm` 文件软链接为 `.mm.cc`。
3. 然后使用 `-x` 标志告知编译器将这些文件分别视为 Objective-C 或 Objective-C++。

## 使用方法

### 1. 在你的 `BUILD.bazel` 中

从 `objc.bzl` 加载宏：

```python
load("//:objc.bzl", "objc_binary", "objc_library")

objc_library(
    name = "math_utils",
    srcs = ["add.m", "sub.m"],
    hdrs = ["math_utils.h"]
)

objc_binary(
    name = "hello",
    srcs = ["main.m"],
    deps = [":math_utils"]
)
```

### 2. 实现细节

- **`objc_library`**: 如果同时存在两种类型的文件，内部会拆分为 `_m_part` 和 `_mm_part`。这确保了每组文件都能应用正确的编译器标志。
- **`objc_binary`**: 简化了二进制文件的处理流程，根据是否存在 `.mm` 文件自动检测是否需要 Objective-C++ 支持。
