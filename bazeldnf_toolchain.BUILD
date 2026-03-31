load("@bazeldnf//bazeldnf:toolchain.bzl", "bazeldnf_toolchain")

# Custom toolchain for ppc64le that uses the Go-based bazeldnf binary
bazeldnf_toolchain(
    name = "bazeldnf_ppc64le_toolchain_impl",
    target = "@bazeldnf//:bazeldnf",
)

toolchain(
    name = "bazeldnf_ppc64le_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:ppc",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:ppc",
    ],
    toolchain = ":bazeldnf_ppc64le_toolchain_impl",
    toolchain_type = "@bazeldnf//bazeldnf:toolchain_type",
)