# KubeVirt ppc64le Build - Next Steps

**Author:** Punith Kenchappa <pkenchap@in.ibm.com>  
**Date:** 2026-03-16  
**Architecture:** ppc64le

## Current Status

✅ **Completed:**
1. Built custom KubeVirt builder images for ppc64le
2. Pushed builder images to quay.io:
   - `quay.io/pkenchap/kubevirt-builder:2603061006-f63d5df66a`
   - `quay.io/pkenchap/kubevirt-builder:2603061006-f63d5df66a-ppc64le`
3. Created complete downstream build system in `downstream/` directory
4. Updated Dockerfiles with complete RPM package lists from Bazel definitions

## What We Just Did

### Updated Dockerfiles with Complete Package Lists

We extracted the complete package lists from the Bazel build definitions in `rpm/BUILD.bazel`:

1. **`Dockerfile.virt-handler`** - Now includes all packages from `handlerbase_x86_64` (lines 502-630)
   - 118 runtime packages for virt-handler
   - Includes libvirt, qemu, networking tools, selinux policies, etc.
   - Added symlinks: `/var/run` → `../run`, `/usr/sbin/iptables` → `/usr/sbin/iptables-legacy`

2. **`Dockerfile.virt-launcher`** - Now includes all packages from `launcherbase_x86_64` (lines 1039-1250)
   - 195 runtime packages for virt-launcher (VM execution environment)
   - Includes QEMU/KVM, libvirt, virtualization drivers, TPM, OVMF, etc.
   - Added capabilities: `cap_net_bind_service` for `/usr/libexec/qemu-kvm`
   - Added symlinks for iptables, netcat, OVMF, crypto-policies

## Next Steps to Build and Deploy KubeVirt

### Step 1: Build All Binaries

```bash
cd downstream
source ./setup-env.sh
make build-binaries
```

This will compile all KubeVirt components:
- virt-operator, virt-api, virt-controller
- virt-handler, virt-launcher, virt-launcher-monitor
- virtctl (CLI tool)
- And all supporting binaries

**Expected Output:** Binaries in `_build/bin/` directory

### Step 2: Build Container Images

```bash
make build-images
```

This will create Docker images for all components:
- `quay.io/pkenchap/virt-operator:v1.0.0-ppc64le`
- `quay.io/pkenchap/virt-api:v1.0.0-ppc64le`
- `quay.io/pkenchap/virt-controller:v1.0.0-ppc64le`
- `quay.io/pkenchap/virt-handler:v1.0.0-ppc64le`
- `quay.io/pkenchap/virt-launcher:v1.0.0-ppc64le`
- `quay.io/pkenchap/virt-exportproxy:v1.0.0-ppc64le`
- `quay.io/pkenchap/virt-exportserver:v1.0.0-ppc64le`

**Note:** All images use `--platform=linux/ppc64le` for ppc64le architecture

### Step 3: Push Images to Registry

```bash
# Login to your registry
podman login quay.io

# Push all images
make push-images
```

### Step 4: Generate KubeVirt Manifests

```bash
cd ..  # Back to kubevirt root directory
make manifests
```

This generates deployment manifests in `_out/manifests/release/`:
- `kubevirt-operator.yaml` - Operator deployment
- `kubevirt-cr.yaml` - KubeVirt custom resource

**Important:** You'll need to update the image references in these manifests to point to your ppc64le images.

### Step 5: Update Manifest Image References

Edit `_out/manifests/release/kubevirt-operator.yaml` and replace image references:

```yaml
# Change from:
image: quay.io/kubevirt/virt-operator:latest

# To:
image: quay.io/pkenchap/virt-operator:v1.0.0-ppc64le
```

Do this for all component images in both `kubevirt-operator.yaml` and `kubevirt-cr.yaml`.

### Step 6: Deploy KubeVirt Operator

```bash
# Create kubevirt namespace
kubectl create namespace kubevirt

# Deploy the operator
kubectl create -f _out/manifests/release/kubevirt-operator.yaml
```

**Verify operator is running:**
```bash
kubectl get pods -n kubevirt
# Should see: virt-operator-xxxxx running
```

### Step 7: Deploy KubeVirt CR

```bash
kubectl create -f _out/manifests/release/kubevirt-cr.yaml
```

This activates KubeVirt and deploys all components:
- virt-api
- virt-controller
- virt-handler (DaemonSet on all nodes)

### Step 8: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n kubevirt

# Check KubeVirt CR status
kubectl get kubevirt -n kubevirt

# Expected output:
# NAME       AGE   PHASE
# kubevirt   1m    Deployed
```

### Step 9: Install virtctl CLI

```bash
cd downstream
make install-virtctl

# Verify installation
virtctl version
```

### Step 10: Test with a Sample VM

```bash
# Create a test VM
kubectl apply -f - <<EOF
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: testvm
    spec:
      domain:
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
        resources:
          requests:
            memory: 1024M
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/kubevirt/cirros-container-disk-demo
EOF

# Start the VM
virtctl start testvm

# Check VM status
kubectl get vms
kubectl get vmis
```

## Troubleshooting

### If Binary Build Fails

1. Check Go version: `go version` (should be 1.21+)
2. Check CGO settings: `echo $CGO_ENABLED` (should be 0)
3. Check architecture: `echo $GOARCH` (should be ppc64le)

### If Image Build Fails

1. Check Podman/Docker is running
2. Verify binaries exist in `_build/bin/`
3. Check Dockerfile syntax
4. Verify base image is available: `podman pull quay.io/fedora/fedora:42-ppc64le`

### If Package Installation Fails in Dockerfile

Some packages might not be available in Fedora 42 ppc64le. You can:
1. Remove unavailable packages from the RUN command
2. Use alternative packages
3. Switch to a different base image (e.g., CentOS Stream 9)

### If Deployment Fails

1. Check operator logs: `kubectl logs -n kubevirt deployment/virt-operator`
2. Check node compatibility: `kubectl get nodes -o wide`
3. Verify images are accessible: `podman pull quay.io/pkenchap/virt-operator:v1.0.0-ppc64le`
4. Check resource availability: `kubectl describe nodes`

## Architecture Notes

### Why Downstream Build System?

The upstream Bazel build system has issues with ppc64le:
- Bazel binary corruption on ppc64le
- Java 21 compatibility issues with Bazel 5.4.1
- Complex cross-compilation setup
- Platform definition mismatches

The downstream system:
- Uses standard Go toolchain (no Bazel)
- Simple Dockerfiles for each component
- Explicit ppc64le platform specification
- Matches OpenShift Virtualization's approach

### Package Lists

The Dockerfiles now include the exact same packages that Bazel uses:
- **handlerbase**: 118 packages for virt-handler runtime
- **launcherbase**: 195 packages for virt-launcher runtime

These were extracted from `rpm/BUILD.bazel` definitions and adapted for Fedora 42.

## References

- Upstream KubeVirt: https://github.com/kubevirt/kubevirt
- KubeVirt Documentation: https://kubevirt.io/user-guide/
- OpenShift Virtualization: https://docs.openshift.com/container-platform/latest/virt/about_virt/about-virt.html

## Support

For issues or questions:
- Email: pkenchap@in.ibm.com
- Check logs: `kubectl logs -n kubevirt <pod-name>`
- Review documentation in `downstream/README.md` and `downstream/QUICKSTART.md`