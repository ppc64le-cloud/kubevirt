# KubeVirt Downstream Build System

**Author:** Punith Kenchappa
**Email:** pkenchap@in.ibm.com
**Purpose:** Dockerfile-based build system for KubeVirt ppc64le architecture

This directory contains a Dockerfile-based build system for KubeVirt, designed as an alternative to the Bazel-based upstream build. This approach is similar to OpenShift Virtualization's downstream build process.

## Overview

Instead of using Bazel for building container images, this system:
1. Builds Go binaries directly using the Go toolchain
2. Creates container images using simple Dockerfiles
3. Provides a straightforward Makefile for orchestration

## Prerequisites

- Go 1.23.9 or later
- Podman or Docker
- ppc64le architecture system (or cross-compilation setup)
- Access to quay.io or your container registry

## Directory Structure

```
downstream/
├── Makefile                    # Main build orchestration
├── README.md                   # This file
├── dockerfiles/                # Dockerfiles for each component
│   ├── Dockerfile.virt-operator
│   ├── Dockerfile.virt-api
│   ├── Dockerfile.virt-controller
│   ├── Dockerfile.virt-handler
│   ├── Dockerfile.virt-launcher
│   ├── Dockerfile.virt-exportproxy
│   └── Dockerfile.virt-exportserver
└── _build/                     # Build output (created during build)
    └── bin/                    # Compiled binaries
```

## Configuration

Set these environment variables before building:

```bash
export REGISTRY=quay.io/pkenchap    # Your container registry
export VERSION=v1.0.0-ppc64le       # Image version tag
export ARCH=ppc64le                 # Target architecture
```

## Building

### Build Everything

```bash
cd downstream
make all
```

This will:
1. Build all Go binaries
2. Create all container images

### Build Only Binaries

```bash
make build-binaries
```

### Build Only Images

```bash
make build-images
```

### Build Individual Components

```bash
# Build specific binary
make build-virt-operator
make build-virt-api
make build-virt-controller
make build-virt-handler
make build-virt-launcher
make build-virtctl

# Build and install virtctl CLI
make build-virtctl
make install-virtctl  # Installs to /usr/local/bin

# Build specific image
make build-virt-operator-image
make build-virt-api-image
make build-virt-controller-image
make build-virt-handler-image
make build-virt-launcher-image
```

## Pushing Images

```bash
# Push all images to registry
make push-images
```

## Components Built

### Core Components

1. **virt-operator** - Manages KubeVirt installation and lifecycle
2. **virt-api** - API server for KubeVirt resources
3. **virt-controller** - Manages VM lifecycle
4. **virt-handler** - Node agent managing VMs on each node
5. **virt-launcher** - Launches and manages individual VM processes

### Supporting Components

6. **virt-exportproxy** - Proxy for VM export operations
7. **virt-exportserver** - Server for VM export operations

### CLI Tool

8. **virtctl** - Command-line tool for managing VMs
   - Create, start, stop, and delete VMs
   - Access VM console and VNC
   - Manage VM snapshots and migrations
   - Port forwarding and file uploads
   - Install with: `make install-virtctl`

### Helper Binaries

- **virt-chroot** - Chroot helper for virt-handler
- **virt-freezer** - VM freeze/thaw operations
- **virt-probe** - VM readiness/liveness probes
- **virt-tail** - Log tailing utility
- **virt-launcher-monitor** - Monitors virt-launcher process
- **container-disk** - Container disk management (C program)
- **csv-generator** - Generates ClusterServiceVersion for OLM

## Image Details

### Base Images

All images use `quay.io/centos/centos:stream9` as the base image for consistency with RHEL/OpenShift environments.

### Runtime Dependencies

- **virt-operator, virt-api, virt-controller**: Minimal dependencies (ca-certificates)
- **virt-handler**: libvirt-libs, qemu-kvm-core, networking tools
- **virt-launcher**: Full QEMU/KVM stack, libvirt-daemon-driver-qemu
- **virt-exportserver**: qemu-img for disk conversion

### Users and Permissions

- Most components run as non-root user (UID 1001)
- virt-handler and virt-launcher run as root (require elevated privileges)
- QEMU user (UID 107) created for VM processes

## Cleaning Up

```bash
# Remove build artifacts and images
make clean
```

## Differences from Upstream

1. **No Bazel**: Uses standard Go build instead of Bazel
2. **Simple Dockerfiles**: Each component has a straightforward Dockerfile
3. **Direct Dependencies**: RPM packages installed directly in images
4. **Easier Customization**: Modify Dockerfiles for downstream requirements
5. **Faster Iteration**: No Bazel cache or complex build rules

## Integration with OpenShift Virtualization

This build system is designed to be compatible with OpenShift Virtualization workflows:

1. Build images with your registry and version tags
2. Push to your internal registry
3. Modify manifests to reference your images
4. Deploy to OpenShift cluster

## Troubleshooting

### Build Failures

1. **Missing dependencies**: Ensure Go 1.23.9+ is installed
2. **Vendor directory**: Run `go mod vendor` in parent directory if needed
3. **CGO errors**: virt-handler and virt-launcher require CGO_ENABLED=1

### Image Build Failures

1. **Missing binaries**: Run `make build-binaries` first
2. **Registry access**: Ensure you're logged into your registry
3. **Architecture mismatch**: Verify ARCH variable matches your system

### Runtime Issues

1. **Permission errors**: virt-handler and virt-launcher need privileged containers
2. **Missing libraries**: Check base image has required RPM packages
3. **SELinux**: Ensure SELinux policies are compatible

## Contributing

When adding new components:

1. Add binary build target to Makefile
2. Create Dockerfile in dockerfiles/
3. Add image build target to Makefile
4. Update this README

## License

Same as KubeVirt upstream (Apache 2.0)