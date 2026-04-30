# KubeVirt PPC64LE Cross-Compilation Guide

**Author:** Punith Kenchappa (pkenchap@in.ibm.com)

This guide provides **tested and proven** instructions for cross-compiling KubeVirt for **ppc64le architecture** from an **x86_64 machine**, building container images, and successfully deploying them on ppc64le machines. This process has been validated with successful VMI (Virtual Machine Instance) deployments using images from **quay.io/pkenchap** repository.

**✅ Validation Status:** Successfully tested and deployed on ppc64le with running VMIs
**📦 Image Repository:** quay.io/pkenchap
**🔧 Branch:** ppc64le-2025

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Cross-Compiling for PPC64LE](#cross-compiling-for-ppc64le)
- [Building PPC64LE Container Images](#building-ppc64le-container-images)
- [Troubleshooting Build Issues](#troubleshooting-build-issues)
- [Pushing Images with Skopeo](#pushing-images-with-skopeo)
- [Deploying on PPC64LE Machine](#deploying-on-ppc64le-machine)
- [Complete Workflow Example](#complete-workflow-example)
- [Development Workflow](#development-workflow)
- [Environment Variables Reference](#environment-variables-reference)
- [Quick Reference Commands](#quick-reference-commands)

## Overview

This guide focuses on:
- **Build Machine**: x86_64 (amd64) Linux system
- **Target Architecture**: ppc64le (PowerPC 64-bit Little Endian)
- **Branch**: `ppc64le-2025`
- **Use Case**: Cross-compile KubeVirt on x86_64, then deploy on ppc64le machines
- **Build System**: Bazel with cross-compilation toolchain
- **Container Runtime**: Podman

### Why Cross-Compile on x86_64?

Cross-compiling on x86_64 machines offers several advantages:
- **Faster build times** compared to native ppc64le builds
- **Better toolchain support** and availability
- **Easier CI/CD integration** with existing infrastructure
- **More readily available** x86_64 build infrastructure
- **Cost-effective** - x86_64 machines are more common and cheaper

## Prerequisites

### Build Machine Requirements (x86_64)

Your x86_64 build machine must have:

1. **Operating System**: Linux (Fedora, Ubuntu, RHEL, CentOS, etc.)
2. **Container Runtime**: Podman (recommended) or Docker
3. **Minimum Resources**:
   - CPU: 4+ cores
   - RAM: 8GB+ (16GB recommended for parallel builds)
   - Disk: 50GB+ free space
4. **Tools**:
   - `rsync` - File synchronization
   - `git` - Version control
   - `skopeo` - Container image operations
   - `make` - Build automation
   - `jq` - JSON processing (optional, for debugging)

### Installing Required Tools on x86_64

**Fedora/RHEL/CentOS:**
```bash
sudo dnf install podman rsync git skopeo make jq
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install podman rsync git skopeo make jq
```

### Target Machine Requirements (ppc64le)

Your ppc64le deployment machine needs:
- **Operating System**: Linux (RHEL, Ubuntu, etc.)
- **Kubernetes**: v1.15.0 or newer (KIND recommended for testing)
- **Container Runtime**: Podman or Docker
- **kubectl**: Configured to access the cluster
- **Network**: Access to pull images from your container registry

## Getting Started

### 1. Clone the Repository on x86_64 Machine

```bash
# Clone the KubeVirt repository
git clone https://github.com/pkenchap/kubevirt.git
cd kubevirt

# Checkout the ppc64le-2025 branch
git checkout ppc64le-2025

# Verify you're on the correct branch
git branch --show-current
# Output: ppc64le-2025
```

### 2. Verify Your Build Environment

```bash
# Check your architecture (should be x86_64)
uname -m
# Output: x86_64

# Verify Podman is running
podman ps

# Verify required tools
which rsync git skopeo make
```

## Cross-Compiling for PPC64LE

### Understanding the Cross-Compilation Process

KubeVirt uses **Bazel** as its build system, which runs inside Podman containers. The cross-compilation process involves:

1. **Toolchain Selection**: Bazel selects the ppc64le cross-compilation toolchain from `bazel/toolchain/ppc64le-none-linux-gnu/`
2. **Dependency Resolution**: RPM packages for ppc64le are fetched from CentOS Stream repositories
3. **Binary Compilation**: Go code is compiled for ppc64le using the cross-compiler
4. **Container Image Building**: Multi-stage builds create ppc64le container images

### Step 1: Set Environment Variables

```bash
# Set the builder image for cross-compilation
export KUBEVIRT_BUILDER_IMAGE="quay.io/kubevirt/builder-cross:2604090246-9a1f806a7a"

# Set the target architecture for cross-compilation
export BUILD_ARCH="crossbuild-ppc64le"

# Set your container registry
export DOCKER_PREFIX="quay.io/your-username"

# Set custom build tag
export DOCKER_TAG="v1.0.5-ppc64le"

# Optional: Set CentOS Stream version (default is 10)
export KUBEVIRT_CENTOS_STREAM_VERSION=10
```

**Important Notes:**
- The `KUBEVIRT_BUILDER_IMAGE` **must** use the `builder-cross` image with the ppc64le cross-compilation toolchain
- Use `BUILD_ARCH=crossbuild-ppc64le` for cross-compilation (not just `ppc64le`)

### Step 2: Build KubeVirt Binaries for PPC64LE

Run the build command on your x86_64 machine:

```bash
BUILD_ARCH=crossbuild-ppc64le make bazel-build
```

This command will:
1. Start a Podman container with the build environment
2. Use the ppc64le cross-compilation toolchain
3. Fetch ppc64le RPM dependencies from CentOS Stream
4. Build all KubeVirt components for ppc64le architecture
5. Output binaries to `_out/cmd/` directory

**Build Time**: Expect 15-30 minutes for a full build.

### Step 3: Verify Cross-Compiled Binaries

Check that binaries are built for ppc64le:

```bash
# Check the architecture of a built binary
file _out/cmd/virtctl/virtctl
# Expected output: ELF 64-bit LSB executable, 64-bit PowerPC or cisco 7500, ...
```

## Building PPC64LE Container Images

### Step 1: Configure Your Container Registry

```bash
# For Quay.io (example: quay.io/pkenchap - tested and validated)
export DOCKER_PREFIX=quay.io/pkenchap

# Set image tag
export DOCKER_TAG=v1.0.2-ppc64le

# Ensure architecture is set
export BUILD_ARCH=crossbuild-ppc64le

# Set the builder image
export KUBEVIRT_BUILDER_IMAGE="quay.io/kubevirt/builder-cross:2604090246-9a1f806a7a"

# Set CentOS Stream version
export KUBEVIRT_CENTOS_STREAM_VERSION=10
```

### Step 2: Build Container Images for PPC64LE

```bash
export DOCKER_TAG=v1.0.2-ppc64le BUILD_ARCH=crossbuild-ppc64le make bazel-build-images
```

This builds images for: virt-operator, virt-api, virt-controller, virt-handler, virt-launcher, and more.

**Build Time**: Expect 20-40 minutes for all images.

### Step 3: Verify Built Images

```bash
# List built images
podman images | grep virt-

# Inspect an image to verify architecture
podman inspect ${DOCKER_PREFIX}/virt-operator:${DOCKER_TAG} | grep Architecture
# Should show: "Architecture": "ppc64le"
```

## Troubleshooting Build Issues

### Issue 1: Missing tar2files Rules for PPC64LE

**Symptom:**
```
ERROR: no such target '//rpm:libnbd-libs_ppc64le_cs10'
```

**Solution:**
We added missing `tar2files` rules in [`rpm/BUILD.bazel`](rpm/BUILD.bazel) for ppc64le libraries.

### Issue 2: Missing centos_stream_alias Rules

**Symptom:**
```
ERROR: no such target '//rpm:libvirt-libs_ppc64le/usr/lib64'
```

**Solution:**
Added `centos_stream_alias` rules in [`rpm/BUILD.bazel`](rpm/BUILD.bazel) for ppc64le.

### Issue 3: Missing Platform Support in BUILD.bazel

**Symptom:**
```
ERROR: in cc_library rule //:libvirt-libs: source file is misplaced
```

**Solution:**
Updated [`BUILD.bazel`](BUILD.bazel) cc_library rules to include ppc64le platform conditions.

### Common Build Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `no such target '//rpm:..._ppc64le...'` | Missing tar2files rules | Check rpm/BUILD.bazel |
| `source file is misplaced` | Missing platform in cc_library | Add ppc64le to BUILD.bazel |
| `Architecture: x86_64` in image | Wrong BUILD_ARCH | Set BUILD_ARCH=crossbuild-ppc64le |
| `Bazel server error` | Cache corruption | Stop server, clean, rebuild |

## Pushing Images with Skopeo

### Step 1: Authenticate to Your Registry

```bash
# Login to Quay.io
skopeo login quay.io
```

### Step 2: Push Images Using Make

```bash
make bazel-push-images
```

### Step 3: Verify Pushed Images

```bash
# Inspect pushed image
skopeo inspect docker://${DOCKER_PREFIX}/virt-operator:${DOCKER_TAG}

# Verify architecture is ppc64le
skopeo inspect docker://${DOCKER_PREFIX}/virt-operator:${DOCKER_TAG} | jq -r '.Architecture'
# Should output: ppc64le
```

## Deploying on PPC64LE Machine

### Prerequisites

```bash
# Clone the deployment scripts repository
git clone https://github.ibm.com/redstack-power/virt.git
cd virt/dev/script

# Run prerequisites script
./pre-req.sh
```

### Deploy KubeVirt with KIND

```bash
# Run the KubeVirt installation script
./install_kind_kubevirt.sh
```

### Verify Deployment

```bash
# Check all KubeVirt pods are running
kubectl get pods -n kubevirt

# Check KubeVirt status
kubectl get kubevirt -n kubevirt

# Check deployed VMs
kubectl get vmi
kubectl get vm
```

## Complete Workflow Example

### On x86_64 Build Machine:

```bash
# 1. Clone and setup
git clone https://github.com/pkenchap/kubevirt.git
cd kubevirt
git checkout ppc64le-2025

# 2. Configure build environment
export KUBEVIRT_BUILDER_IMAGE="quay.io/kubevirt/builder-cross:2604090246-9a1f806a7a"
export BUILD_ARCH="crossbuild-ppc64le"
export DOCKER_PREFIX=quay.io/your-username
export DOCKER_TAG="v1.0.2-ppc64le"

# 3. Build binaries
BUILD_ARCH=crossbuild-ppc64le make bazel-build

# 4. Build container images
export DOCKER_TAG=v1.0.2-ppc64le BUILD_ARCH=crossbuild-ppc64le make bazel-build-images

# 5. Push images to registry
make bazel-push-images

# 6. Verify images
skopeo inspect docker://${DOCKER_PREFIX}/virt-operator:${DOCKER_TAG}
```

### On PPC64LE Target Machine:

```bash
# 1. Clone deployment scripts
git clone https://github.ibm.com/redstack-power/virt.git
cd virt/dev/script

# 2. Run prerequisites
./pre-req.sh

# 3. Deploy KubeVirt
./install_kind_kubevirt.sh

# 4. Verify deployment
kubectl get pods -n kubevirt
kubectl get kubevirt -n kubevirt
```

## Development Workflow

### Quick Iteration for Single Component

```bash
# On x86_64: Build and push specific component
PUSH_TARGETS='virt-api' hack/dockerized "hack/bazel-push-images.sh"

# On ppc64le: Restart component
kubectl delete po -n kubevirt -l kubevirt.io=virt-api
```

## Environment Variables Reference

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `KUBEVIRT_BUILDER_IMAGE` | Builder image with toolchain | **Yes** | `quay.io/kubevirt/builder-cross:...` |
| `BUILD_ARCH` | Target architecture | **Yes** | `crossbuild-ppc64le` |
| `DOCKER_PREFIX` | Container registry prefix | **Yes** | `quay.io/username` |
| `DOCKER_TAG` | Image tag | No | `v1.0.2-ppc64le` |
| `KUBEVIRT_CENTOS_STREAM_VERSION` | CentOS Stream version | No | `10` |

## Quick Reference Commands

### Build Commands (x86_64)
```bash
# Build binaries
BUILD_ARCH=crossbuild-ppc64le make bazel-build

# Build images
export DOCKER_TAG=v1.0.2-ppc64le BUILD_ARCH=crossbuild-ppc64le make bazel-build-images

# Push images
make bazel-push-images

# Clean
make clean
```

### Skopeo Commands
```bash
# Login
skopeo login quay.io

# Inspect
skopeo inspect docker://${DOCKER_PREFIX}/virt-operator:${DOCKER_TAG}

# Check architecture
skopeo inspect docker://${DOCKER_PREFIX}/virt-operator:${DOCKER_TAG} | jq -r '.Architecture'
```

### Deployment Commands (ppc64le)
```bash
# Deploy
./install_kind_kubevirt.sh

# Check status
kubectl get pods -n kubevirt
kubectl get kubevirt -n kubevirt
```

## Additional Resources

- [KubeVirt Documentation](https://kubevirt.io/user-guide/)
- [Skopeo Documentation](https://github.com/containers/skopeo)
- [Bazel Documentation](https://bazel.build/)
- [IBM RedStack Power Scripts](https://github.ibm.com/redstack-power/virt/tree/main/dev/script)

---

**Author:** Punith Kenchappa (pkenchap@in.ibm.com)  
**Branch:** `ppc64le-2025`  
**Last Updated:** 2026-04-30