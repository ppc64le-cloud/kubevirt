# Fix for ppc64le Builder Build Failure

## Problem

When running `make builder-build` on a native ppc64le machine, the build fails with two issues:

### Issue 1: qemu-user-static Error
```
WARNING: image platform (linux/amd64) does not match the expected platform (linux/ppc64le)
{"msg":"exec container process `/register`: Exec format error","level":"error","time":"2026-03-06T08:41:25.003306Z"}
make: *** [Makefile:180: builder-build] Error 1
```

### Issue 2: Cross-Architecture Build Failure
After fixing Issue 1, the build attempts to build containers for all architectures (amd64, arm64, s390x, ppc64le) and fails when trying to build amd64 on ppc64le:
```
+ podman build --platform=linux/amd64 ...
exec container process `/bin/sh`: Exec format error
Error: building at STEP "RUN dnf install ...": while running runtime: exit status 1
```

## Root Cause

Two problems were identified in [`hack/builder/build.sh`](../hack/builder/build.sh):

1. **qemu-user-static setup**: The script unconditionally tried to run the `docker.io/multiarch/qemu-user-static` container, which is only available for amd64 architecture
2. **Multi-architecture builds**: The script attempted to build containers for all architectures in the `ARCHITECTURES` list, even on non-amd64 hosts where cross-compilation isn't properly configured

Additionally, ppc64le was not included in the default `ARCHITECTURES` list in [`hack/builder/common.sh`](../hack/builder/common.sh).

## Solution

Three changes were made to fix these issues:

### 1. Skip qemu-user-static on Native Architectures

Modified [`hack/builder/build.sh`](../hack/builder/build.sh) to:
- Detect the host architecture
- Only setup qemu-user-static when building on amd64 hosts (for cross-compilation)
- Skip qemu-user-static setup on native ppc64le, arm64, or s390x hosts

**Rationale**: When building natively on ppc64le, arm64, or s390x machines, there's no need for QEMU emulation since the binaries run natively. The qemu-user-static setup is only required for cross-compilation scenarios (e.g., building arm64 binaries on an x86_64 host).

### 2. Build Only Native Architecture on Non-amd64 Hosts

Modified [`hack/builder/build.sh`](../hack/builder/build.sh) to automatically limit builds to the native architecture when running on non-amd64 hosts:

```bash
# On non-amd64 hosts, only build for the native architecture unless explicitly overridden
if [ "${HOST_ARCH}" != "amd64" ] && [ -z "${ARCHITECTURES}" ]; then
    ARCHITECTURES="${HOST_ARCH}"
    echo "Building for native architecture only: ${HOST_ARCH}"
fi
```

**Rationale**: Cross-compilation requires qemu-user-static, which is only available for amd64. On ppc64le, arm64, or s390x hosts, attempting to build for foreign architectures will fail. Users can still override this by explicitly setting the `ARCHITECTURES` environment variable if they have configured emulation manually.

### 3. Add ppc64le to Supported Architectures

Modified [`hack/builder/common.sh`](../hack/builder/common.sh) to include ppc64le in the default `ARCHITECTURES` list:

```bash
ARCHITECTURES=${ARCHITECTURES:-"amd64 arm64 s390x ppc64le"}
```

## Changes Made

### File: hack/builder/build.sh

Added host architecture detection and conditional qemu-user-static setup:

```bash
# Detect host architecture
HOST_ARCH=$(uname -m)
case ${HOST_ARCH} in
    x86_64)
        HOST_ARCH="amd64"
        ;;
    aarch64)
        HOST_ARCH="arm64"
        ;;
    ppc64le)
        HOST_ARCH="ppc64le"
        ;;
    s390x)
        HOST_ARCH="s390x"
        ;;
esac

# Only setup qemu-user-static on amd64 hosts for cross-compilation
if [ "${HOST_ARCH}" = "amd64" ]; then
    if ! grep -q -E '^enabled$' /proc/sys/fs/binfmt_misc/qemu-aarch64 2>/dev/null; then
        ${KUBEVIRT_CRI} >&2 run --rm --privileged docker.io/multiarch/qemu-user-static --reset -p yes
    fi
fi
```

### File: hack/builder/common.sh

Added ppc64le to the architectures list:

```bash
ARCHITECTURES=${ARCHITECTURES:-"amd64 arm64 s390x ppc64le"}
```

## Testing

After applying these changes, you can build the builder container on a ppc64le machine:

```bash
# On a ppc64le machine - builds only ppc64le by default
make builder-build
```

The build will now:
1. Detect that you're on a ppc64le host
2. Skip the qemu-user-static setup (not needed for native builds)
3. Automatically set ARCHITECTURES to "ppc64le" only
4. Build only the ppc64le builder container using native compilation
5. Complete successfully without any "Exec format error"

### Building Multiple Architectures

If you need to build for multiple architectures (and have configured emulation), you can override:

```bash
# Build for specific architectures
ARCHITECTURES="ppc64le arm64" make builder-build

# Build for all architectures (requires proper emulation setup)
ARCHITECTURES="amd64 arm64 s390x ppc64le" make builder-build
```

## Impact

- **Native ppc64le builds**: Now work correctly without attempting to run amd64 containers or build foreign architectures
- **Native arm64/s390x builds**: Also benefit from the same fixes
- **Cross-compilation from amd64**: Still works as before with qemu-user-static for building all architectures
- **Backward compatibility**: No impact on existing amd64-based build workflows
- **Flexibility**: Users can still override ARCHITECTURES if they have custom emulation setups

## Related Documentation

- [Building KubeVirt for ppc64le on RHEL](build-ppc64le-rhel.md)
- [Build The Builder](build-the-builder.md)
- [ppc64le Support Summary](ppc64le-support-summary.md)

## Additional Notes

This fix aligns with the principle that native builds should not require emulation layers. The qemu-user-static container is specifically designed for cross-compilation scenarios and should only be used when building for foreign architectures.

### Why Only amd64 Supports Multi-Architecture Builds

The `docker.io/multiarch/qemu-user-static` container that enables cross-compilation is only available for amd64. This is why:
- **amd64 hosts**: Can build for all architectures (amd64, arm64, s390x, ppc64le)
- **Other hosts**: Should build only for their native architecture by default

If you need multi-architecture builds on non-amd64 hosts, you would need to:
1. Manually configure qemu-user-static for your architecture
2. Set the `ARCHITECTURES` environment variable explicitly

---

**Date**: 2026-03-06  
**Issue**: Builder build failure on ppc64le machines  
**Status**: Fixed