# Fix for ppc64le Builder Build Failure

## Problem

When running `make builder-build` on a native ppc64le machine, the build fails with:

```
WARNING: image platform (linux/amd64) does not match the expected platform (linux/ppc64le)
{"msg":"exec container process `/register`: Exec format error","level":"error","time":"2026-03-06T08:41:25.003306Z"}
make: *** [Makefile:180: builder-build] Error 1
```

## Root Cause

The issue occurred in [`hack/builder/build.sh`](../hack/builder/build.sh) where the script unconditionally tried to run the `docker.io/multiarch/qemu-user-static` container to enable cross-architecture emulation. This container is only available for amd64 architecture, causing an "Exec format error" when attempting to run it on ppc64le.

Additionally, ppc64le was not included in the default `ARCHITECTURES` list in [`hack/builder/common.sh`](../hack/builder/common.sh).

## Solution

Two changes were made to fix this issue:

### 1. Skip qemu-user-static on Native Architectures

Modified [`hack/builder/build.sh`](../hack/builder/build.sh) to:
- Detect the host architecture
- Only setup qemu-user-static when building on amd64 hosts (for cross-compilation)
- Skip qemu-user-static setup on native ppc64le, arm64, or s390x hosts

**Rationale**: When building natively on ppc64le, arm64, or s390x machines, there's no need for QEMU emulation since the binaries run natively. The qemu-user-static setup is only required for cross-compilation scenarios (e.g., building arm64 binaries on an x86_64 host).

### 2. Add ppc64le to Supported Architectures

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
# On a ppc64le machine
make builder-build
```

The build will now:
1. Skip the qemu-user-static setup (not needed for native builds)
2. Build the ppc64le builder container using native compilation
3. Complete successfully without the "Exec format error"

## Impact

- **Native ppc64le builds**: Now work correctly without attempting to run amd64 containers
- **Cross-compilation from amd64**: Still works as before with qemu-user-static
- **Other architectures**: arm64 and s390x native builds also benefit from skipping unnecessary emulation setup
- **Backward compatibility**: No impact on existing amd64-based build workflows

## Related Documentation

- [Building KubeVirt for ppc64le on RHEL](build-ppc64le-rhel.md)
- [Build The Builder](build-the-builder.md)
- [ppc64le Support Summary](ppc64le-support-summary.md)

## Additional Notes

This fix aligns with the principle that native builds should not require emulation layers. The qemu-user-static container is specifically designed for cross-compilation scenarios and should only be used when building for foreign architectures.

---

**Date**: 2026-03-06  
**Issue**: Builder build failure on ppc64le machines  
**Status**: Fixed