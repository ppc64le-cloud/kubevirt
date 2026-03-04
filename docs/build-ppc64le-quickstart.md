# Quick Start: Building KubeVirt for ppc64le

This is a condensed quick-start guide for building KubeVirt on ppc64le/RHEL 10.1 using the builder container approach. For detailed instructions, see [`build-ppc64le-rhel.md`](build-ppc64le-rhel.md).

## Prerequisites

RHEL 10.1 on ppc64le with 16GB+ RAM and 100GB+ disk space.

## Method 1: Using Builder Container (Recommended)

This follows the same approach as s390x documented in [`build-the-builder.md`](build-the-builder.md).

### Quick Setup

```bash
# 1. Install dependencies
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y java-11-openjdk-devel python3 git wget unzip \
    gcc gcc-c++ libvirt-devel golang podman zlib-devel

# 2. Build Bazel from source
mkdir -p ~/bazel-build && cd ~/bazel-build
BAZEL_VERSION="6.4.0"
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip -d bazel-${BAZEL_VERSION}
cd bazel-${BAZEL_VERSION}
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" ./compile.sh

# 3. Clone KubeVirt and setup Bazel
cd ~
git clone https://github.com/kubevirt/kubevirt.git
cd kubevirt
cp ~/bazel-build/bazel-${BAZEL_VERSION}/output/bazel hack/builder/bazel

# 4. Build bazeldnf from source
cd ~
git clone https://github.com/rmohr/bazeldnf.git
cd bazeldnf
go build -o bazeldnf cmd/bazeldnf/bazeldnf.go
sudo cp bazeldnf /usr/local/bin/

# 5. Update RPM dependencies
cd ~/kubevirt
cat > fix-rpm-deps.sh << 'EOF'
#!/bin/bash
set -ex
BASESYSTEM=${BASESYSTEM:-"centos-stream-release"}
bazeldnf_repos="--repofile rpm/repo.yaml"
centos_main="acl curl-minimal vim-minimal"
centos_extra="coreutils-single glibc-minimal-langpack libcurl-minimal"
sandboxroot_main="findutils gcc glibc-static python3 sssd-client"
bazeldnf fetch ${bazeldnf_repos}
bazeldnf rpmtree --public --nobest --name sandboxroot_ppc64le --arch ppc64le \
    --basesystem ${BASESYSTEM} ${bazeldnf_repos} \
    $centos_main $centos_extra $sandboxroot_main
SINGLE_ARCH=ppc64le make rpm-deps
EOF
chmod +x fix-rpm-deps.sh
./fix-rpm-deps.sh

# 6. Build the builder container
export ARCH="ppc64le"
export DOCKER_PREFIX="quay.io/myuser"  # Change to your registry
export DOCKER_IMAGE="kubevirt-builder"
export VERSION="v1.0-ppc64le"
export KUBEVIRT_BUILDER_IMAGE="${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}"
make builder-build

# 7. Publish builder (optional, if using remote registry)
podman login quay.io
make builder-publish

# 8. Build KubeVirt
export BUILD_ARCH="ppc64le"
export DOCKER_PREFIX="quay.io/myuser"  # Change to your registry
make
make bazel-push-images
make manifests
```

## Method 2: Direct Bazel Build (Alternative)

If you prefer to build directly without the builder container:

```bash
# 1-2. Same as above (install deps and build Bazel)

# 3. Clone KubeVirt
cd ~
git clone https://github.com/kubevirt/kubevirt.git
cd kubevirt

# 4. Build with Bazel directly
bazel build --config=ppc64le //...

# 5. Verify
file bazel-bin/cmd/virt-launcher/virt-launcher_/virt-launcher
```

## Common Commands

### Builder Container Method
```bash
# Build specific components
make bazel-build-virt-launcher
make bazel-build-virt-controller

# Rebuild builder after changes
make builder-build

# Push images
make bazel-push-images
```

### Direct Bazel Method
```bash
# Build specific components
bazel build --config=ppc64le //cmd/virt-launcher:virt-launcher
bazel build --config=ppc64le //cmd/virt-controller:virt-controller

# Run tests
bazel test --config=ppc64le //pkg/...

# Build with optimizations
bazel build --config=ppc64le -c opt //...
```

## Troubleshooting

**Out of memory during Bazel build?**
```bash
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk --jobs=2" ./compile.sh
```

**RPM dependencies not found?**
```bash
# Check available packages
curl -s https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/Packages/ | grep libvirt

# Update hack/rpm-deps.sh with correct versions
# Re-run fix-rpm-deps.sh
```

**Builder container build fails?**
```bash
make builder-clean
make builder-build
```

**bazeldnf not available?**
```bash
# Build from source (shown in setup above)
cd ~/bazeldnf
go build -o bazeldnf cmd/bazeldnf/bazeldnf.go
sudo cp bazeldnf /usr/local/bin/
```

**Container registry authentication?**
```bash
podman login quay.io
# or
podman login docker.io
```

## Build Time Estimates

- **Bazel from source**: 30-60 minutes (first time)
- **Builder container**: 20-40 minutes (first time)
- **KubeVirt components**: 20-40 minutes (first time)
- **Subsequent builds**: 5-15 minutes (incremental)

## Files Modified for ppc64le Support

- [`bazel/platforms/BUILD`](../bazel/platforms/BUILD) - Platform definition
- [`bazel/toolchain/ppc64le-none-linux-gnu/BUILD`](../bazel/toolchain/ppc64le-none-linux-gnu/BUILD) - Toolchain
- [`bazel/toolchain/ppc64le-none-linux-gnu/cc_toolchain_config.bzl`](../bazel/toolchain/ppc64le-none-linux-gnu/cc_toolchain_config.bzl) - Compiler config
- [`bazel/toolchain/toolchain.bzl`](../bazel/toolchain/toolchain.bzl) - Registration
- [`.bazelrc`](../.bazelrc) - Build configuration
- [`WORKSPACE`](../WORKSPACE) - Buildifier assets
- [`docs/build-the-builder.md`](build-the-builder.md) - Added ppc64le references

## Environment Variables Reference

### For Builder Container
```bash
export ARCH="ppc64le"
export DOCKER_PREFIX="<registry>/<namespace>"
export DOCKER_IMAGE="kubevirt-builder"
export VERSION="<tag>"
export KUBEVIRT_BUILDER_IMAGE="${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}"
```

### For KubeVirt Build
```bash
export BUILD_ARCH="ppc64le"
export DOCKER_PREFIX="<registry>/<namespace>"
export QUAY_REPOSITORY="kubevirt"
export PACKAGE_NAME="kubevirt-operatorhub"
```

## Next Steps

- **Deploy**: See [getting-started.md](getting-started.md)
- **Full docs**: See [build-ppc64le-rhel.md](build-ppc64le-rhel.md)
- **Builder details**: See [build-the-builder.md](build-the-builder.md)
- **Issues**: https://github.com/kubevirt/kubevirt/issues

## Key Differences from Other Architectures

- **Bazel**: Must be built from source (like s390x)
- **bazeldnf**: Must be built from source (like s390x)
- **Builder container**: Required for consistent builds
- **RPM repos**: Use ppc64le packages from CentOS Stream

---

**Note**: The builder container method is recommended as it ensures consistency and is the same approach used for s390x support.