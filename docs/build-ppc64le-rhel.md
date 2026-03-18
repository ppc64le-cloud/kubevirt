# Building KubeVirt for ppc64le on RHEL 10.1

This guide provides step-by-step instructions for building KubeVirt with ppc64le (PowerPC 64-bit Little Endian) support on RHEL 10.1.

## Overview

KubeVirt uses a containerized build system with a "builder" container that includes all necessary toolchains and dependencies. For ppc64le architecture, you'll need to:

1. Build Bazel from source (similar to s390x)
2. Build the KubeVirt builder container for ppc64le
3. Use that builder container to build KubeVirt components

This approach is consistent with how KubeVirt supports other architectures like s390x.

## Prerequisites

### System Requirements

- RHEL 10.1 (or compatible distribution) on ppc64le architecture
- Minimum 16GB RAM (recommended for building Bazel)
- Minimum 100GB free disk space
- Root or sudo access

### Required Base Packages

```bash
# Update system packages
sudo dnf update -y

# Install base development tools
sudo dnf groupinstall -y "Development Tools"

# Install required dependencies
sudo dnf install -y \
    java-11-openjdk-devel \
    java-11-openjdk \
    python3 \
    python3-pip \
    python3-devel \
    git \
    wget \
    curl \
    unzip \
    zip \
    gcc \
    gcc-c++ \
    make \
    which \
    file \
    patch \
    podman

# Install Go (check KubeVirt's go.mod for required version)
sudo dnf install -y golang

# Install additional dependencies
sudo dnf install -y \
    libvirt-devel \
    device-mapper-devel \
    glibc-static \
    libstdc++-static \
    zlib-devel
```

## Step 1: Build Bazel from Source

Since pre-built Bazel binaries are not available for ppc64le, you need to build Bazel from source. This process is similar to building for s390x as documented in [`build-the-builder.md`](build-the-builder.md).

### 1.1 Download Bazel Source

```bash
# Create a build directory
mkdir -p ~/bazel-build
cd ~/bazel-build

# Download Bazel source (check KubeVirt's .bazelversion for required version)
BAZEL_VERSION="6.4.0"  # Adjust based on KubeVirt requirements
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip

# Extract the source
unzip bazel-${BAZEL_VERSION}-dist.zip -d bazel-${BAZEL_VERSION}
cd bazel-${BAZEL_VERSION}
```

### 1.2 Build Bazel (Bootstrap Process)

```bash
# Set Java home
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# Start the bootstrap build (this will take 30-60 minutes)
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh

# The build process will:
# 1. Compile a minimal version of Bazel
# 2. Use that to build the full Bazel binary
# 3. Output the final binary to output/bazel
```

### 1.3 Install Bazel

```bash
# Install Bazel system-wide
sudo cp output/bazel /usr/local/bin/bazel
sudo chmod +x /usr/local/bin/bazel

# Verify installation
bazel --version

# Clone KubeVirt repository
cd ~
git clone https://github.com/kubevirt/kubevirt.git
cd kubevirt

# Also copy bazel to the builder directory
cp ~/bazel-build/bazel-${BAZEL_VERSION}/output/bazel hack/builder/bazel

# Verify
./hack/builder/bazel --version

# IMPORTANT: Restart Bazel server to pick up new .bazelrc configuration
bazel shutdown
```

## Step 2: Build the KubeVirt Builder Container

Following the process documented in [`build-the-builder.md`](build-the-builder.md):

### 2.1 Set Environment Variables

```bash
export ARCH="ppc64le"
export DOCKER_PREFIX="<your-registry-URL>/<your-namespace>"
export DOCKER_IMAGE="builder"
export VERSION="<your-tag>"  # e.g., "v1.0-ppc64le"
export KUBEVIRT_BUILDER_IMAGE="${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}"
```

Example:
```bash
export ARCH="ppc64le"
export DOCKER_PREFIX="quay.io/myuser"
export DOCKER_IMAGE="kubevirt-builder"
export VERSION="v1.0-ppc64le"
export KUBEVIRT_BUILDER_IMAGE="${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}"
```

### 2.2 Add ppc64le Repositories

First, ensure ppc64le repositories are configured in `rpm/repo.yaml`:

```bash
cd ~/kubevirt

# Verify ppc64le repositories are present
grep -A 2 "arch: ppc64le" rpm/repo.yaml
```

The file should contain:
```yaml
- arch: ppc64le
  baseurl: http://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
  name: centos/stream9-baseos-ppc64le
  gpgkey: https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
- arch: ppc64le
  baseurl: http://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
  name: centos/stream9-appstream-ppc64le
  gpgkey: https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
- arch: ppc64le
  baseurl: http://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
  name: centos/stream9-crb-ppc64le
  gpgkey: https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
```

### 2.3 Update RPM Dependencies

Edit `hack/rpm-deps.sh` to ensure the RPM versions are available for ppc64le in the CentOS Stream repositories:

```bash
# Check available versions at:
# https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/Packages/

# Example versions (update as needed):
LIBVIRT_VERSION=${LIBVIRT_VERSION:-0:9.5.0-5.el9}
QEMU_VERSION=${QEMU_VERSION:-17:8.0.0-13.el9}
# ... etc
```

### 2.4 Obtain bazeldnf Utility

For ppc64le, you'll need to build `bazeldnf` from source:

```bash
# Clone bazeldnf
cd ~
git clone https://github.com/rmohr/bazeldnf.git
cd bazeldnf

# Build
go build -o bazeldnf cmd/bazeldnf/bazeldnf.go

# Install
sudo cp bazeldnf /usr/local/bin/
sudo chmod +x /usr/local/bin/bazeldnf

# Verify
bazeldnf --help
```

### 2.5 Update RPM Dependencies with bazeldnf

**Important**: Run bazeldnf commands directly, NOT through `make rpm-deps` yet (the builder container doesn't exist yet).

```bash
cd ~/kubevirt

# Fetch repository metadata
bazeldnf fetch --repofile rpm/repo.yaml

# Generate RPM tree for ppc64le
bazeldnf rpmtree \
    --public --nobest \
    --name sandboxroot_ppc64le --arch ppc64le \
    --basesystem centos-stream-release \
    --repofile rpm/repo.yaml \
    acl curl-minimal vim-minimal \
    coreutils-single glibc-minimal-langpack libcurl-minimal \
    findutils gcc glibc-static python3 sssd-client

# This generates the BUILD.bazel file with ppc64le RPM dependencies
# DO NOT run "make rpm-deps" yet - it requires the builder container
```

### 2.6 Build the Builder Container

**Important:** When building natively on ppc64le, you don't need QEMU. Create a dummy file to skip QEMU setup:

```bash
# Skip QEMU setup (not needed for native ppc64le builds)
sudo mkdir -p /proc/sys/fs/binfmt_misc
echo 'enabled' | sudo tee /proc/sys/fs/binfmt_misc/qemu-aarch64 > /dev/null

# Build the builder container
make builder-build

# This will create a container image with:
# - Bazel toolchain
# - Cross-compilation tools
# - All dependencies for building KubeVirt
```

### 2.7 Publish the Builder Container (Optional)

If you want to use the builder from a remote registry:

```bash
# Login to your container registry
podman login <your-registry-URL>

# Push the builder image
make builder-publish
```

**Note**: If you're building locally, you can skip publishing and use the local builder image.

### 2.8 Update RPM Dependencies Using Builder Container

Now that the builder container exists, you can run the full RPM dependency update:

```bash
# This will use the builder container to update all RPM dependencies
SINGLE_ARCH=ppc64le make rpm-deps

# This command:
# 1. Runs inside the builder container
# 2. Updates rpm/BUILD.bazel with ppc64le packages
# 3. Ensures all dependencies are correctly configured
```

## Step 3: Build KubeVirt Components

Now use your builder container to build KubeVirt:

### 3.1 Set Build Environment Variables

```bash
export BUILD_ARCH="ppc64le"
export DOCKER_PREFIX="<your-registry-URL>/<your-namespace>"
export QUAY_REPOSITORY="kubevirt"
export PACKAGE_NAME="kubevirt-operatorhub"
```

### 3.2 Build KubeVirt

```bash
# Build all components
make

# Build and push container images
make bazel-push-images

# Generate manifests
make manifests
```

### 3.3 Build Specific Components

```bash
# Build individual components using the builder container
make bazel-build-virt-launcher
make bazel-build-virt-controller
make bazel-build-virt-api
make bazel-build-virt-handler
make bazel-build-virt-operator
```

## Step 4: Verify the Build

```bash
# Check binary architecture
file _out/cmd/virt-launcher/virt-launcher

# Expected output:
# ELF 64-bit LSB executable, 64-bit PowerPC or cisco 7500, version 1 (SYSV)...

# List built images
podman images | grep kubevirt
```

## Alternative: Direct Bazel Build (Without Builder Container)

If you prefer to build directly with Bazel (not using the builder container):

```bash
# Ensure Bazel is in PATH
export PATH=~/bazel-build/bazel-${BAZEL_VERSION}/output:$PATH

# Build with ppc64le configuration
bazel build --config=ppc64le //...

# Build specific components
bazel build --config=ppc64le //cmd/virt-launcher:virt-launcher
bazel build --config=ppc64le //cmd/virt-controller:virt-controller
```

## Troubleshooting

### Issue: Bazel Build Fails with Memory Error

```bash
# Solution: Limit resources during Bazel bootstrap
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk --jobs=2" ./compile.sh
```

### Issue: RPM Dependencies Not Found

```bash
# Check available packages for ppc64le
curl -s https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/Packages/ | grep -i <package-name>

# Update version in hack/rpm-deps.sh
# Re-run fix-rpm-deps.sh
```

### Issue: Builder Container Build Fails

```bash
# Clean and rebuild
make builder-clean
make builder-build
```

### Issue: bazeldnf Not Available for ppc64le

```bash
# Build from source
cd ~
git clone https://github.com/rmohr/bazeldnf.git
cd bazeldnf
go build -o bazeldnf cmd/bazeldnf/bazeldnf.go
sudo cp bazeldnf /usr/local/bin/
```

### Issue: Container Registry Authentication

```bash
# Login to registry
podman login quay.io
# or
podman login docker.io

# Verify credentials
cat ~/.docker/config.json
```

## Architecture-Specific Configuration

The ppc64le support is configured in:

1. **Platform Definition**: [`bazel/platforms/BUILD`](../bazel/platforms/BUILD)
   - Defines `ppc64le-none-linux-gnu` platform

2. **Toolchain Configuration**: [`bazel/toolchain/ppc64le-none-linux-gnu/`](../bazel/toolchain/ppc64le-none-linux-gnu/)
   - [`BUILD`](../bazel/toolchain/ppc64le-none-linux-gnu/BUILD): Toolchain definition
   - [`cc_toolchain_config.bzl`](../bazel/toolchain/ppc64le-none-linux-gnu/cc_toolchain_config.bzl): C/C++ compiler configuration

3. **Toolchain Registration**: [`bazel/toolchain/toolchain.bzl`](../bazel/toolchain/toolchain.bzl)
   - Registers ppc64le toolchain

4. **Build Configuration**: [`.bazelrc`](../.bazelrc)
   - Defines `ppc64le` and `crossbuild-ppc64le` configurations

## Performance Tips

### Optimize Builder Container Build

```bash
# Use local cache
export DOCKER_BUILDKIT=1

# Limit parallel jobs if memory constrained
export BAZEL_BUILD_OPTS="--jobs=4 --local_ram_resources=8192"
```

### Speed Up Subsequent Builds

```bash
# The builder container caches dependencies
# Subsequent builds will be much faster

# Use incremental builds
make bazel-build-virt-launcher  # Only rebuild changed components
```

## Next Steps

After successful build:

1. **Test Locally**: Deploy to a local Kubernetes cluster
2. **Integration Tests**: Run KubeVirt test suites
3. **Deploy**: Follow [getting-started.md](getting-started.md) for deployment

## Additional Resources

- **[Build The Builder](build-the-builder.md)** - Detailed builder container documentation
- **[Getting Started](getting-started.md)** - KubeVirt deployment guide
- **[Quick Start](build-ppc64le-quickstart.md)** - Quick reference for ppc64le
- **[Support Summary](ppc64le-support-summary.md)** - Complete ppc64le support overview

## Support

For issues or questions:

- **GitHub Issues**: [kubevirt/kubevirt/issues](https://github.com/kubevirt/kubevirt/issues)
- **Slack**: [#virtualization on Kubernetes Slack](https://kubernetes.slack.com/messages/virtualization)
- **Mailing List**: [kubevirt-dev Google Group](https://groups.google.com/forum/#!forum/kubevirt-dev)

## Contributing

Contributions to improve ppc64le support are welcome:

1. Test the build process and report issues
2. Submit pull requests with improvements
3. Update documentation based on your experience
4. Share performance benchmarks

---

**Last Updated**: 2026-03-04  
**Tested On**: RHEL 10.1 on ppc64le  
**Bazel Version**: 6.4.0  
**Build Method**: Builder container (recommended) or direct Bazel build