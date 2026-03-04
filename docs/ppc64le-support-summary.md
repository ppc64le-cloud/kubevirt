# ppc64le Support for KubeVirt

This document summarizes the ppc64le (PowerPC 64-bit Little Endian) architecture support added to KubeVirt.

## Overview

KubeVirt now supports building and running on ppc64le architecture, enabling virtualization workloads on IBM Power systems running RHEL 10.1 and compatible distributions.

## Documentation

- **[Quick Start Guide](build-ppc64le-quickstart.md)** - Fast setup for experienced users
- **[Detailed Build Guide](build-ppc64le-rhel.md)** - Complete step-by-step instructions including building Bazel from source

## What's New

### Added Files

1. **Bazel Platform Definition**
   - [`bazel/platforms/BUILD`](../bazel/platforms/BUILD) - Added `ppc64le-none-linux-gnu` platform

2. **Toolchain Configuration**
   - [`bazel/toolchain/ppc64le-none-linux-gnu/BUILD`](../bazel/toolchain/ppc64le-none-linux-gnu/BUILD) - Toolchain definition
   - [`bazel/toolchain/ppc64le-none-linux-gnu/cc_toolchain_config.bzl`](../bazel/toolchain/ppc64le-none-linux-gnu/cc_toolchain_config.bzl) - C/C++ compiler configuration

3. **Documentation**
   - [`docs/build-ppc64le-rhel.md`](build-ppc64le-rhel.md) - Comprehensive build guide
   - [`docs/build-ppc64le-quickstart.md`](build-ppc64le-quickstart.md) - Quick reference
   - [`docs/ppc64le-support-summary.md`](ppc64le-support-summary.md) - This file

### Modified Files

1. **[`bazel/toolchain/toolchain.bzl`](../bazel/toolchain/toolchain.bzl)**
   - Registered ppc64le toolchain

2. **[`.bazelrc`](../.bazelrc)**
   - Added `ppc64le` configuration for native builds
   - Added `crossbuild-ppc64le` configuration for cross-compilation

3. **[`WORKSPACE`](../WORKSPACE)**
   - Added ppc64le to buildifier assets

## Build Configurations

### Native Build on ppc64le

```bash
bazel build --config=ppc64le //...
```

This configuration is used when building directly on a ppc64le system.

### Cross-Compilation from x86_64

```bash
bazel build --config=crossbuild-ppc64le //...
```

This configuration enables cross-compilation from x86_64 to ppc64le (requires cross-compiler toolchain).

## System Requirements

### For Building on ppc64le

- **OS**: RHEL 10.1 or compatible
- **Architecture**: ppc64le
- **RAM**: 16GB minimum (recommended for building Bazel)
- **Disk**: 100GB free space
- **Bazel**: 6.4.0+ (must be built from source on ppc64le)

### Required Packages

```bash
# Core build tools
gcc, gcc-c++, make, git, wget, unzip

# Java (for Bazel)
java-11-openjdk-devel

# Go (for KubeVirt)
golang 1.21+

# Additional dependencies
libvirt-devel, device-mapper-devel
```

## Toolchain Details

### Compiler Paths

The ppc64le toolchain uses the following compiler paths:

**For Native Builds (on ppc64le):**
- `/usr/bin/gcc`
- `/usr/bin/g++`
- `/usr/bin/ar`
- `/usr/bin/ld`

**For Cross-Compilation (from x86_64):**
- `/usr/bin/powerpc64le-linux-gnu-gcc`
- `/usr/bin/powerpc64le-linux-gnu-g++`
- `/usr/bin/powerpc64le-linux-gnu-ar`
- `/usr/bin/powerpc64le-linux-gnu-ld`

### Include Paths

The toolchain is configured with the following include paths (adjust GCC version as needed):

```
/usr/powerpc64le-linux-gnu/sys-root/usr/include
/usr/lib/gcc/powerpc64le-linux-gnu/12/include
/usr/lib/gcc/powerpc64le-linux-gnu/12/include-fixed
```

## Building Bazel from Source

Since pre-built Bazel binaries may not be available for ppc64le, you need to build Bazel from source:

```bash
# Download Bazel source
BAZEL_VERSION="6.4.0"
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip -d bazel-${BAZEL_VERSION}
cd bazel-${BAZEL_VERSION}

# Build Bazel (30-60 minutes)
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh

# Install
sudo cp output/bazel /usr/local/bin/bazel
```

See [build-ppc64le-rhel.md](build-ppc64le-rhel.md) for detailed instructions.

## Building KubeVirt

### Quick Build

```bash
# Clone repository
git clone https://github.com/kubevirt/kubevirt.git
cd kubevirt

# Build all components
bazel build --config=ppc64le //...
```

### Build Specific Components

```bash
bazel build --config=ppc64le //cmd/virt-launcher:virt-launcher
bazel build --config=ppc64le //cmd/virt-controller:virt-controller
bazel build --config=ppc64le //cmd/virt-api:virt-api
bazel build --config=ppc64le //cmd/virt-handler:virt-handler
bazel build --config=ppc64le //cmd/virt-operator:virt-operator
```

### Build Container Images

```bash
export KUBEVIRT_ARCH=ppc64le
make docker-build
```

## Testing

```bash
# Run unit tests
bazel test --config=ppc64le //pkg/...

# Run specific test suites
bazel test --config=ppc64le //pkg/virt-launcher/...
bazel test --config=ppc64le //pkg/virt-controller/...
```

## Verification

After building, verify the binaries are correctly built for ppc64le:

```bash
# Check architecture
file bazel-bin/cmd/virt-launcher/virt-launcher_/virt-launcher

# Expected output:
# ELF 64-bit LSB executable, 64-bit PowerPC or cisco 7500, version 1 (SYSV)...

# Check dependencies
ldd bazel-bin/cmd/virt-launcher/virt-launcher_/virt-launcher

# Test execution
bazel-bin/cmd/virt-launcher/virt-launcher_/virt-launcher --version
```

## Common Issues and Solutions

### Issue: Out of Memory During Build

**Solution:**
```bash
bazel build --config=ppc64le --local_ram_resources=8192 --jobs=2 //...
```

### Issue: GCC Version Mismatch

**Solution:** Update the GCC version in [`bazel/toolchain/ppc64le-none-linux-gnu/cc_toolchain_config.bzl`](../bazel/toolchain/ppc64le-none-linux-gnu/cc_toolchain_config.bzl)

```bash
# Check your GCC version
gcc --version

# Edit the toolchain config and update paths like:
# /usr/lib/gcc/powerpc64le-linux-gnu/12/include
# to match your version (e.g., /13/ instead of /12/)
```

### Issue: Bazel Build Fails

**Solution:**
```bash
# Clean and rebuild Bazel
cd ~/bazel-build/bazel-${BAZEL_VERSION}
./clean.sh
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk --jobs=2" ./compile.sh
```

### Issue: Cache Corruption

**Solution:**
```bash
bazel clean --expunge
rm -rf ~/.cache/bazel
bazel build --config=ppc64le //...
```

## Performance Optimization

### Recommended Build Settings

Create a `user.bazelrc` file:

```bash
cat > user.bazelrc << EOF
# Optimize for ppc64le
build:ppc64le --jobs=8
build:ppc64le --local_ram_resources=12288
build:ppc64le --local_cpu_resources=8

# Enable disk cache
build --disk_cache=~/.cache/bazel

# Reduce memory usage
build --experimental_inmemory_jdeps_files
build --experimental_inmemory_dotd_files
EOF
```

## Architecture Support Matrix

| Architecture | Native Build | Cross-Compile | Status |
|--------------|--------------|---------------|--------|
| x86_64       | ✅ Yes       | N/A           | Stable |
| aarch64      | ✅ Yes       | ✅ Yes        | Stable |
| s390x        | ✅ Yes       | ✅ Yes        | Stable |
| **ppc64le**  | **✅ Yes**   | **✅ Yes**    | **New** |

## Contributing

Contributions to improve ppc64le support are welcome:

1. **Testing**: Test builds on different RHEL versions and report issues
2. **Documentation**: Improve documentation based on your experience
3. **Performance**: Share benchmarks and optimization tips
4. **Bug Fixes**: Submit PRs for any issues you encounter

## Support

For help with ppc64le builds:

- **GitHub Issues**: [kubevirt/kubevirt/issues](https://github.com/kubevirt/kubevirt/issues)
- **Slack**: [#virtualization on Kubernetes Slack](https://kubernetes.slack.com/messages/virtualization)
- **Mailing List**: [kubevirt-dev Google Group](https://groups.google.com/forum/#!forum/kubevirt-dev)

## References

- [KubeVirt Documentation](README.md)
- [Bazel Documentation](https://bazel.build/docs)
- [Building Bazel from Source](https://bazel.build/install/compile-source)
- [IBM Power Systems](https://www.ibm.com/power)

## License

This work is part of the KubeVirt project and follows the same Apache 2.0 license.

---

**Last Updated**: 2026-03-04  
**Tested On**: RHEL 10.1 on ppc64le  
**Bazel Version**: 6.4.0  
**KubeVirt Version**: main branch