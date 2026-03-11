# Building and Deploying KubeVirt for ppc64le

This guide walks you through building KubeVirt images using your custom ppc64le builder and deploying KubeVirt to a Kubernetes cluster.

## Prerequisites

- Custom builder images already built and pushed:
  - `quay.io/pkenchap/kubevirt-builder:2603061006-f63d5df66a` (amd64)
  - `quay.io/pkenchap/kubevirt-builder:2603061006-f63d5df66a-ppc64le` (ppc64le)
- Access to a Kubernetes cluster (for deployment)
- Docker/Podman installed and configured
- `kubectl` configured to access your cluster
- Sufficient permissions to push images to your registry

## Step 1: Set Environment Variables

Configure your build environment with the custom builder and target registry:

```bash
# Set your custom builder image
export KUBEVIRT_BUILDER_IMAGE=quay.io/pkenchap/kubevirt-builder:2603061006-f63d5df66a

# Set the Docker registry where KubeVirt images will be pushed
export DOCKER_PREFIX=quay.io/pkenchap
export DOCKER_TAG=v1.0.0-ppc64le  # Use your preferred tag

# Set build architecture for ppc64le
export BUILD_ARCH=ppc64le

# Optional: If you need to increase timeout for module fetching
export PULLER_TIMEOUT=10000
```

### For Multi-Architecture Builds

If you want to build for multiple architectures:

```bash
# Build for both amd64 and ppc64le
export BUILD_ARCH="amd64 ppc64le"
```

## Step 2: Build KubeVirt Images

Build all KubeVirt component images:

```bash
make bazel-build-images
```

This command builds the following images:
- **virt-operator**: Manages KubeVirt deployment lifecycle
- **virt-api**: API server for KubeVirt resources
- **virt-controller**: Manages VM lifecycle
- **virt-handler**: Runs on each node, manages VM processes
- **virt-launcher**: Wraps libvirt and QEMU processes
- **virt-exportproxy**: Handles VM export operations
- **virt-exportserver**: Serves exported VM data
- **synchronization-controller**: Manages resource synchronization

### Alternative: Build Everything

To build binaries, images, and manifests in one command:

```bash
make && make manifests
```

## Step 3: Push Images to Registry

Push the built images to your container registry:

```bash
make push
```

Or use the direct command:

```bash
make bazel-push-images
```

### Verify Images Were Pushed

Check your registry to confirm images are available:

```bash
# List images in your registry (example for quay.io)
# Visit: https://quay.io/repository/pkenchap?tab=tags

# Or use Docker/Podman to verify
podman images | grep kubevirt
```

## Step 4: Generate Deployment Manifests

Generate the KubeVirt deployment manifests:

```bash
make manifests
```

This creates manifests in the `_out/manifests/release/` directory:
- `kubevirt-operator.yaml`: Operator deployment
- `kubevirt-cr.yaml`: KubeVirt custom resource

### Inspect Generated Manifests

```bash
# View operator manifest
cat _out/manifests/release/kubevirt-operator.yaml

# View CR manifest
cat _out/manifests/release/kubevirt-cr.yaml
```

## Step 5: Deploy KubeVirt Operator

Deploy the KubeVirt operator to your cluster:

```bash
# Create kubevirt namespace (if not exists)
kubectl create namespace kubevirt --dry-run=client -o yaml | kubectl apply -f -

# Deploy the operator
kubectl create -f _out/manifests/release/kubevirt-operator.yaml

# Wait for operator to be ready
kubectl wait --for=condition=Available --timeout=300s -n kubevirt deployment/virt-operator

# Check operator status
kubectl get deployment -n kubevirt virt-operator
kubectl get pods -n kubevirt -l kubevirt.io=virt-operator
```

## Step 6: Deploy KubeVirt Custom Resource

Create the KubeVirt CR to activate all KubeVirt components:

```bash
# Deploy KubeVirt CR
kubectl create -f _out/manifests/release/kubevirt-cr.yaml

# Wait for KubeVirt to be ready (this may take several minutes)
kubectl wait --for=condition=Available --timeout=600s -n kubevirt kv/kubevirt

# Check KubeVirt status
kubectl get kubevirt -n kubevirt kubevirt -o yaml
```

## Step 7: Verify Deployment

Verify that all KubeVirt components are running:

```bash
# Check all pods in kubevirt namespace
kubectl get pods -n kubevirt

# Expected pods:
# - virt-operator (1 pod)
# - virt-api (2 pods by default)
# - virt-controller (2 pods by default)
# - virt-handler (1 pod per node)

# Check KubeVirt version and status
kubectl get kubevirt -n kubevirt

# View detailed KubeVirt status
kubectl describe kubevirt -n kubevirt kubevirt
```

### Check Component Logs

If you encounter issues, check component logs:

```bash
# Operator logs
kubectl logs -n kubevirt deployment/virt-operator

# API server logs
kubectl logs -n kubevirt deployment/virt-api

# Controller logs
kubectl logs -n kubevirt deployment/virt-controller

# Handler logs (on specific node)
kubectl logs -n kubevirt ds/virt-handler
```

## Step 8: Test KubeVirt Installation

Create a test Virtual Machine Instance:

```bash
# Create a simple test VMI
kubectl create -f examples/vmi-ephemeral.yaml

# Check VMI status
kubectl get vmi

# Check VMI details
kubectl describe vmi vmi-ephemeral

# Delete test VMI
kubectl delete -f examples/vmi-ephemeral.yaml
```

## Quick Reference: All-in-One Commands

### Complete Build and Deploy

```bash
# Set environment
export KUBEVIRT_BUILDER_IMAGE=quay.io/pkenchap/kubevirt-builder:2603061006-f63d5df66a
export DOCKER_PREFIX=quay.io/pkenchap
export DOCKER_TAG=v1.0.0-ppc64le
export BUILD_ARCH=ppc64le

# Build, push, and generate manifests
make && make push && make manifests

# Deploy to cluster
kubectl create -f _out/manifests/release/kubevirt-operator.yaml
kubectl wait --for=condition=Available --timeout=300s -n kubevirt deployment/virt-operator
kubectl create -f _out/manifests/release/kubevirt-cr.yaml
kubectl wait --for=condition=Available --timeout=600s -n kubevirt kv/kubevirt

# Verify
kubectl get pods -n kubevirt
kubectl get kubevirt -n kubevirt
```

## Development Workflow: Local Cluster

For development and testing with a local cluster:

```bash
# Set environment
export KUBEVIRT_BUILDER_IMAGE=quay.io/pkenchap/kubevirt-builder:2603061006-f63d5df66a
export BUILD_ARCH=ppc64le

# Start local cluster
make cluster-up

# Build and sync KubeVirt to the cluster
make cluster-sync

# Run functional tests
make functest

# Tear down cluster
make cluster-down
```

## Troubleshooting

### Build Issues

**Problem**: Bazel build fails with module fetch timeout
```bash
# Solution: Increase timeout
export PULLER_TIMEOUT=10000
```

**Problem**: Build fails with "no space left on device"
```bash
# Solution: Clean up Docker/Bazel cache
docker system prune -a
bazel clean --expunge
```

### Deployment Issues

**Problem**: Operator pod fails to start
```bash
# Check operator logs
kubectl logs -n kubevirt deployment/virt-operator

# Check events
kubectl get events -n kubevirt --sort-by='.lastTimestamp'
```

**Problem**: virt-handler pods not starting on ppc64le nodes
```bash
# Verify node architecture
kubectl get nodes -o wide

# Check if images are available for ppc64le
kubectl describe pod -n kubevirt <virt-handler-pod-name>

# Verify image pull policy and registry access
kubectl get pods -n kubevirt -o jsonpath='{.items[*].spec.containers[*].image}'
```

**Problem**: KubeVirt CR stuck in "Deploying" phase
```bash
# Check operator logs for errors
kubectl logs -n kubevirt deployment/virt-operator -f

# Check if all required images are accessible
kubectl get pods -n kubevirt -o yaml | grep image:

# Verify resource availability
kubectl describe nodes
```

### Image Registry Issues

**Problem**: Cannot push images to registry
```bash
# Login to registry
docker login quay.io

# Or for podman
podman login quay.io

# Verify credentials
cat ~/.docker/config.json
```

## Updating KubeVirt

To update an existing KubeVirt installation:

```bash
# Build new images with updated tag
export DOCKER_TAG=v1.0.1-ppc64le
make && make push && make manifests

# Update the deployment
kubectl apply -f _out/manifests/release/kubevirt-operator.yaml
kubectl apply -f _out/manifests/release/kubevirt-cr.yaml

# Monitor the update
kubectl get pods -n kubevirt -w
```

## Uninstalling KubeVirt

To remove KubeVirt from your cluster:

```bash
# Delete KubeVirt CR (this removes all components)
kubectl delete -f _out/manifests/release/kubevirt-cr.yaml

# Wait for cleanup to complete
kubectl wait --for=delete kv/kubevirt -n kubevirt --timeout=300s

# Delete the operator
kubectl delete -f _out/manifests/release/kubevirt-operator.yaml

# Optional: Delete the namespace
kubectl delete namespace kubevirt
```

## Additional Resources

- [KubeVirt Documentation](https://kubevirt.io/user-guide/)
- [Getting Started Guide](./getting-started.md)
- [Build the Builder Guide](./build-the-builder.md)
- [ppc64le Support Summary](./ppc64le-support-summary.md)

## Next Steps

After successful deployment:

1. **Explore VM Management**: Create and manage Virtual Machines
2. **Configure Storage**: Set up persistent storage for VMs
3. **Network Configuration**: Configure VM networking
4. **Enable Features**: Explore KubeVirt feature gates
5. **Performance Tuning**: Optimize for your workload

For more information, refer to the [KubeVirt User Guide](https://kubevirt.io/user-guide/).