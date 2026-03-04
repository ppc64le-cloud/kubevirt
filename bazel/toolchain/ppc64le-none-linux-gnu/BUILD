load(":cc_toolchain_config.bzl", "cc_toolchain_config")

package(default_visibility = ["//visibility:public"])

filegroup(name = "empty")

cc_toolchain_config(name = "ppc64le_toolchain_config")

cc_toolchain(
    name = "ppc64le_toolchain",
    all_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    toolchain_config = ":ppc64le_toolchain_config",
    toolchain_identifier = "ppc64le-toolchain",
)

cc_toolchain_suite(
    name = "gcc_toolchain",
    tags = ["manual"],
    toolchains = {
        "ppc64le": ":ppc64le_toolchain",
    },
)

toolchain(
    name = "ppc64le_linux_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:ppc",
    ],
    toolchain = ":ppc64le_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)