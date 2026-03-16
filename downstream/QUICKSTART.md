# KubeVirt Downstream Build - Quick Start Guide

**Author:** Punith Kenchappa
**Email:** pkenchap@in.ibm.com
**Architecture:** ppc64le

This guide will help you quickly build and deploy KubeVirt using the downstream Dockerfile-based build system.

## Prerequisites Check

```bash
# Check Go version (need 1.23.9+)
go version

# Check Podman
podman --version

# Check GCC (needed for container-disk C program)
gcc --version

# Check architecture
uname -m  # Should show ppc64le
```

## Step 1: Set Environment Variables

```bash
cd /root/kubevirt_2025/kubevirt/downstream

# Required: Container registry configuration
export REGISTRY=quay.io/pkenchap
export VERSION=v1.0.0-ppc64le
export ARCH=ppc64le

# Required: Go build configuration
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=ppc64le

# Optional: Additional Go flags
export GO_BUILD_FLAGS="-mod=vendor -tags=selinux -ldflags=\"-s -w -X kubevirt.io/client-go/version.gitVersion=${VERSION}\""
```

### Complete Export Script

Save this as `setup-env.sh` for easy reuse:

```bash
#!/bin/bash
# KubeVirt Downstream Build Environment

# Container registry settings
export REGISTRY=quay.io/pkenchap
export VERSION=v1.0.0-ppc64le
export ARCH=ppc64le

# Go build settings
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=ppc64le
export GO_VERSION=1.23.9

# Image names (auto-generated)
export VIRT_OPERATOR_IMAGE=${REGISTRY}/virt-operator:${VERSION}
export VIRT_API_IMAGE=${REGISTRY}/virt-api:${VERSION}
export VIRT_CONTROLLER_IMAGE=${REGISTRY}/virt-controller:${VERSION}
export VIRT_HANDLER_IMAGE=${REGISTRY}/virt-handler:${VERSION}
export VIRT_LAUNCHER_IMAGE=${REGISTRY}/virt-launcher:${VERSION}
export VIRT_EXPORTPROXY_IMAGE=${REGISTRY}/virt-exportproxy:${VERSION}
export VIRT_EXPORTSERVER_IMAGE=${REGISTRY}/virt-exportserver:${VERSION}

# For manifest generation
export DOCKER_PREFIX=${REGISTRY}
export DOCKER_TAG=${VERSION}

echo "Environment configured for KubeVirt ${VERSION} on ${ARCH}"
echo "Registry: ${REGISTRY}"
```

Then source it:

```bash
chmod +x setup-env.sh
source ./setup-env.sh
```

## Step 2a: Build and Install virtctl (Recommended)

virtctl is the CLI tool for managing KubeVirt VMs. Install it for easy VM management:

```bash
# Build virtctl for ppc64le
make build-virtctl

# Install to /usr/local/bin (requires sudo)
make install-virtctl

# Verify installation
virtctl version
which virtctl
```

### virtctl Usage Examples

Once KubeVirt is deployed, you can use virtctl to manage VMs:

```bash
# Start a VM
virtctl start <vm-name>

# Stop a VM
virtctl stop <vm-name>

# Access VM console
virtctl console <vm-name>

# Access VM via VNC
virtctl vnc <vm-name>

# Get VM status
virtctl guestosinfo <vm-name>

# Port forward to VM
virtctl port-forward <vm-name> 8080:80

# Upload files to VM
virtctl image-upload dv <datavolume-name> --image-path=/path/to/image.img
```


## Step 2: Build All Binaries

```bash
make build-binaries
```

This will compile all KubeVirt components:
- virt-operator
- virt-api
- virt-controller
- virt-handler
- virt-launcher
- And all supporting binaries

**Expected output**: Binaries in `_build/bin/` directory

## Step 3: Build Container Images

```bash
make build-images
```

This creates 7 container images:
1. virt-operator
2. virt-api
3. virt-controller
4. virt-handler
5. virt-launcher
6. virt-exportproxy
7. virt-exportserver

**Expected output**: Images tagged with your REGISTRY and VERSION

## Step 4: Verify Images

```bash
podman images | grep kubevirt
```

You should see all 7 images listed.

## Step 5: Push to Registry (Optional)

```bash
# Login to your registry
podman login quay.io

# Push all images
make push-images
```

## Step 6: Generate Manifests

```bash
cd ..  # Back to kubevirt root directory

# Set image references
export DOCKER_PREFIX=quay.io/pkenchap
export DOCKER_TAG=v1.0.0-ppc64le

# Generate manifests
make manifests
```

**Expected output**: Manifests in `_out/manifests/release/`

## Step 7: Deploy to Kubernetes

```bash
# Deploy KubeVirt operator
kubectl create -f _out/manifests/release/kubevirt-operator.yaml

# Wait for operator to be ready
kubectl wait --for=condition=Ready pod -l kubevirt.io=virt-operator -n kubevirt --timeout=300s

# Deploy KubeVirt CR
kubectl create -f _out/manifests/release/kubevirt-cr.yaml

# Wait for all components
kubectl wait --for=condition=Ready pod -l kubevirt.io -n kubevirt --timeout=600s
```

## Step 8: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n kubevirt

# Check KubeVirt CR status
kubectl get kubevirt -n kubevirt

# Verify version
kubectl get kubevirt -n kubevirt -o yaml | grep observedKubeVirtVersion
```

## Troubleshooting

### Build Issues

**Problem**: `go: cannot find main module`
```bash
# Solution: Ensure you're in the downstream directory
cd /root/kubevirt_2025/kubevirt/downstream
```

**Problem**: `vendor directory not found`
```bash
# Solution: Create vendor directory
cd /root/kubevirt_2025/kubevirt
go mod vendor
cd downstream
```

**Problem**: CGO compilation errors
```bash
# Solution: Install development libraries
dnf install -y libvirt-devel gcc
```

### Image Build Issues

**Problem**: `COPY failed: file not found`
```bash
# Solution: Build binaries first
make build-binaries
```

**Problem**: `Error: unable to find image`
```bash
# Solution: Pull base image
podman pull quay.io/centos/centos:stream9
```

### Deployment Issues

**Problem**: Pods stuck in `ImagePullBackOff`
```bash
# Solution: Check image names in manifests match your registry
kubectl get pods -n kubevirt
kubectl describe pod <pod-name> -n kubevirt
```

**Problem**: Pods in `CrashLoopBackOff`
```bash
# Solution: Check logs
kubectl logs <pod-name> -n kubevirt
```

## One-Command Build

For convenience, build everything at once:

```bash
cd /root/kubevirt_2025/kubevirt/downstream

export REGISTRY=quay.io/pkenchap
export VERSION=v1.0.0-ppc64le
export ARCH=ppc64le

make all
```

## Rebuilding After Changes

```bash
# Clean previous build
make clean

# Rebuild everything
make all
```

## Building Individual Components

If you only need to rebuild specific components:

```bash
# Rebuild virt-operator
make build-virt-operator
make build-virt-operator-image

# Rebuild virt-launcher
make build-virt-launcher
make build-virt-launcher-image
```

## Next Steps

After successful deployment:

1. **Test VM Creation**: Create a test VM to verify functionality
2. **Check Logs**: Monitor component logs for any issues
3. **Performance Testing**: Run performance tests if needed
4. **Integration**: Integrate with your OpenShift environment

## Getting Help

- Check logs: `kubectl logs -n kubevirt <pod-name>`
- Describe resources: `kubectl describe <resource> -n kubevirt`
- Review README.md for detailed documentation
- Check upstream KubeVirt documentation

## Summary

```bash
# Complete workflow
cd /root/kubevirt_2025/kubevirt/downstream
export REGISTRY=quay.io/pkenchap VERSION=v1.0.0-ppc64le ARCH=ppc64le
make all
make push-images
cd .. && make manifests
kubectl create -f _out/manifests/release/kubevirt-operator.yaml
kubectl create -f _out/manifests/release/kubevirt-cr.yaml
kubectl get pods -n kubevirt
```

Success! You now have KubeVirt running with your custom-built images.

## Summary - Complete Build Workflow

```bash
# 1. Navigate to downstream directory
cd /root/kubevirt_2025/kubevirt/downstream

# 2. Set up environment
source ./setup-env.sh

# 3. Build all binaries and images
make all

# 4. (Optional) Push images to registry
podman login ${REGISTRY}
make push-images

# 5. Generate manifests
cd /root/kubevirt_2025/kubevirt
export DOCKER_PREFIX=${REGISTRY}
export DOCKER_TAG=${VERSION}
make manifests

# 6. Deploy to Kubernetes
kubectl create -f _out/manifests/release/kubevirt-operator.yaml
kubectl create -f _out/manifests/release/kubevirt-cr.yaml

# 7. Verify deployment
kubectl get pods -n kubevirt -w
```

## Important Notes

### Binary Types
- **Go binaries**: Most components (virt-operator, virt-api, etc.)
- **C binary**: container-disk (compiled with gcc)
- **CGO binaries**: virt-handler and virt-launcher (need libvirt-devel)

### Architecture Specification
All images are built with `--platform=linux/ppc64le` to ensure correct architecture metadata.

### Registry Authentication
Before pushing images:
```bash
podman login quay.io
# Or for other registries
podman login your-registry.com
```

### Customization
Edit `setup-env.sh` to change:
- Registry location
- Version tags
- Architecture (for cross-compilation)

Success! You now have KubeVirt running with your custom-built ppc64le images.