#!/bin/bash
# KubeVirt Downstream Build Environment Configuration
# Source this file before building: source ./setup-env.sh
#
# Author: Punith Kenchappa
# Email: pkenchap@in.ibm.com
# Purpose: Environment setup for KubeVirt ppc64le builds

# Container registry settings
export REGISTRY=quay.io/pkenchap
export VERSION=v1.0.0-ppc64le
export ARCH=ppc64le

# Go build settings
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=ppc64le
export GO_VERSION=1.23.9

# Image names (auto-generated from REGISTRY and VERSION)
export VIRT_OPERATOR_IMAGE=${REGISTRY}/virt-operator:${VERSION}
export VIRT_API_IMAGE=${REGISTRY}/virt-api:${VERSION}
export VIRT_CONTROLLER_IMAGE=${REGISTRY}/virt-controller:${VERSION}
export VIRT_HANDLER_IMAGE=${REGISTRY}/virt-handler:${VERSION}
export VIRT_LAUNCHER_IMAGE=${REGISTRY}/virt-launcher:${VERSION}
export VIRT_EXPORTPROXY_IMAGE=${REGISTRY}/virt-exportproxy:${VERSION}
export VIRT_EXPORTSERVER_IMAGE=${REGISTRY}/virt-exportserver:${VERSION}

# For manifest generation (used by parent Makefile)
export DOCKER_PREFIX=${REGISTRY}
export DOCKER_TAG=${VERSION}
export BUILD_ARCH=${ARCH}

# Display configuration
echo "========================================="
echo "KubeVirt Downstream Build Environment"
echo "========================================="
echo "Version:      ${VERSION}"
echo "Architecture: ${ARCH}"
echo "Registry:     ${REGISTRY}"
echo "Go Version:   ${GO_VERSION}"
echo "========================================="
echo ""
echo "Image Tags:"
echo "  - ${VIRT_OPERATOR_IMAGE}"
echo "  - ${VIRT_API_IMAGE}"
echo "  - ${VIRT_CONTROLLER_IMAGE}"
echo "  - ${VIRT_HANDLER_IMAGE}"
echo "  - ${VIRT_LAUNCHER_IMAGE}"
echo "  - ${VIRT_EXPORTPROXY_IMAGE}"
echo "  - ${VIRT_EXPORTSERVER_IMAGE}"
echo "========================================="
echo ""
echo "Ready to build! Run: make all"
echo ""

# Made with Bob
