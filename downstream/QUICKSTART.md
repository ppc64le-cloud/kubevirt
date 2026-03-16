# KubeVirt Downstream Build - Quick Start Guide

This guide will help you quickly build and deploy KubeVirt using the downstream Dockerfile-based build system.

## Prerequisites Check

```bash
# Check Go version (need 1.23.9+)
go version

# Check Podman
podman --version

# Check architecture
uname -m  # Should show ppc64le
```

## Step 1: Set Environment Variables

```bash
cd /root/kubevirt_2025/kubevirt/downstream

export REGISTRY=quay.io/pkenchap
export VERSION=v1.0.0-ppc64le
export ARCH=ppc64le
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