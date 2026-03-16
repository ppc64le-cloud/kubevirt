# KubeVirt Downstream Build System
# Builds container images using Dockerfiles instead of Bazel
#
# Author: Punith Kenchappa
# Email: pkenchap@in.ibm.com
# Description: Dockerfile-based build system for KubeVirt ppc64le

# Configuration
REGISTRY ?= quay.io/pkenchap
VERSION ?= v1.0.0-ppc64le
ARCH ?= ppc64le
GO_VERSION ?= 1.23.9

# Image names
VIRT_OPERATOR_IMAGE = $(REGISTRY)/virt-operator:$(VERSION)
VIRT_API_IMAGE = $(REGISTRY)/virt-api:$(VERSION)
VIRT_CONTROLLER_IMAGE = $(REGISTRY)/virt-controller:$(VERSION)
VIRT_HANDLER_IMAGE = $(REGISTRY)/virt-handler:$(VERSION)
VIRT_LAUNCHER_IMAGE = $(REGISTRY)/virt-launcher:$(VERSION)
VIRT_EXPORTPROXY_IMAGE = $(REGISTRY)/virt-exportproxy:$(VERSION)
VIRT_EXPORTSERVER_IMAGE = $(REGISTRY)/virt-exportserver:$(VERSION)

# Build directories
BUILD_DIR = _build
BIN_DIR = $(BUILD_DIR)/bin
IMAGE_DIR = $(BUILD_DIR)/images

# Go build flags
GO_BUILD_FLAGS = -mod=vendor -tags=selinux -ldflags="-s -w -X kubevirt.io/client-go/version.gitVersion=$(VERSION)"
CGO_ENABLED = 0
GOOS = linux
GOARCH = $(ARCH)

.PHONY: all
all: build-binaries build-images

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	podman rmi -f $(VIRT_OPERATOR_IMAGE) $(VIRT_API_IMAGE) $(VIRT_CONTROLLER_IMAGE) \
		$(VIRT_HANDLER_IMAGE) $(VIRT_LAUNCHER_IMAGE) $(VIRT_EXPORTPROXY_IMAGE) \
		$(VIRT_EXPORTSERVER_IMAGE) || true

.PHONY: build-binaries
build-binaries: \
	build-virt-operator \
	build-virt-api \
	build-virt-controller \
	build-virt-handler \
	build-virt-launcher \
	build-virt-chroot \
	build-virt-freezer \
	build-virt-probe \
	build-virt-tail \
	build-virt-launcher-monitor \
	build-container-disk \
	build-virt-exportproxy \
	build-virt-exportserver \
	build-csv-generator \
	build-virtctl

.PHONY: build-virt-operator
build-virt-operator:
	@echo "Building virt-operator binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virt-operator ./cmd/virt-operator

.PHONY: build-virt-api
build-virt-api:
	@echo "Building virt-api binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virt-api ./cmd/virt-api

.PHONY: build-virt-controller
build-virt-controller:
	@echo "Building virt-controller binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virt-controller ./cmd/virt-controller

.PHONY: build-virt-handler
build-virt-handler:
	@echo "Building virt-handler binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=1 GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build -mod=vendor -tags=selinux -ldflags="-s -w -X kubevirt.io/client-go/version.gitVersion=$(VERSION)" \
		-o downstream/$(BIN_DIR)/virt-handler ./cmd/virt-handler

.PHONY: build-virt-launcher
build-virt-launcher:
	@echo "Building virt-launcher binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=1 GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build -mod=vendor -tags=selinux -ldflags="-s -w -X kubevirt.io/client-go/version.gitVersion=$(VERSION)" \
		-o downstream/$(BIN_DIR)/virt-launcher ./cmd/virt-launcher

.PHONY: build-virt-chroot
build-virt-chroot:
	@echo "Building virt-chroot binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virt-chroot ./cmd/virt-chroot

.PHONY: build-virt-freezer
build-virt-freezer:
	@echo "Building virt-freezer binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virt-freezer ./cmd/virt-freezer

.PHONY: build-virt-probe
build-virt-probe:
	@echo "Building virt-probe binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virt-probe ./cmd/virt-probe

.PHONY: build-virt-tail
build-virt-tail:
	@echo "Building virt-tail binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virt-tail ./cmd/virt-tail

.PHONY: build-virt-launcher-monitor
build-virt-launcher-monitor:
	@echo "Building virt-launcher-monitor binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virt-launcher-monitor ./cmd/virt-launcher-monitor

.PHONY: build-container-disk
build-container-disk:
	@echo "Building container-disk binary (C program)..."
	@mkdir -p $(BIN_DIR)
	cd ../cmd/container-disk-v2alpha && gcc -o ../../downstream/$(BIN_DIR)/container-disk main.c -static

.PHONY: build-virt-exportproxy
build-virt-exportproxy:
	@echo "Building virt-exportproxy binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virt-exportproxy ./cmd/virt-exportproxy

.PHONY: build-virt-exportserver
build-virt-exportserver:
	@echo "Building virt-exportserver binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virt-exportserver ./cmd/virt-exportserver

.PHONY: build-csv-generator
build-csv-generator:
	@echo "Building csv-generator binary..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/csv-generator ./tools/csv-generator

.PHONY: build-virtctl
build-virtctl:
	@echo "Building virtctl binary for $(ARCH)..."
	@mkdir -p $(BIN_DIR)
	cd .. && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		go build $(GO_BUILD_FLAGS) -o downstream/$(BIN_DIR)/virtctl ./cmd/virtctl
	@echo "virtctl binary built successfully at $(BIN_DIR)/virtctl"
	@file $(BIN_DIR)/virtctl

.PHONY: install-virtctl
install-virtctl: build-virtctl
	@echo "Installing virtctl to /usr/local/bin..."
	@sudo cp $(BIN_DIR)/virtctl /usr/local/bin/virtctl
	@sudo chmod +x /usr/local/bin/virtctl
	@echo "virtctl installed successfully!"
	@echo "Testing virtctl..."
	@virtctl version || echo "Note: virtctl version may fail until KubeVirt is deployed"

.PHONY: build-images
build-images: \
	build-virt-operator-image \
	build-virt-api-image \
	build-virt-controller-image \
	build-virt-handler-image \
	build-virt-launcher-image \
	build-virt-exportproxy-image \
	build-virt-exportserver-image

.PHONY: build-virt-operator-image
build-virt-operator-image: build-virt-operator build-csv-generator
	@echo "Building virt-operator image for $(ARCH)..."
	podman build --platform=linux/$(ARCH) -t $(VIRT_OPERATOR_IMAGE) -f dockerfiles/Dockerfile.virt-operator .

.PHONY: build-virt-api-image
build-virt-api-image: build-virt-api
	@echo "Building virt-api image for $(ARCH)..."
	podman build --platform=linux/$(ARCH) -t $(VIRT_API_IMAGE) -f dockerfiles/Dockerfile.virt-api .

.PHONY: build-virt-controller-image
build-virt-controller-image: build-virt-controller
	@echo "Building virt-controller image for $(ARCH)..."
	podman build --platform=linux/$(ARCH) -t $(VIRT_CONTROLLER_IMAGE) -f dockerfiles/Dockerfile.virt-controller .

.PHONY: build-virt-handler-image
build-virt-handler-image: build-virt-handler build-virt-chroot
	@echo "Building virt-handler image for $(ARCH)..."
	podman build --platform=linux/$(ARCH) -t $(VIRT_HANDLER_IMAGE) -f dockerfiles/Dockerfile.virt-handler .

.PHONY: build-virt-launcher-image
build-virt-launcher-image: build-virt-launcher build-virt-freezer build-virt-probe build-virt-tail build-virt-launcher-monitor build-container-disk
	@echo "Building virt-launcher image for $(ARCH)..."
	podman build --platform=linux/$(ARCH) -t $(VIRT_LAUNCHER_IMAGE) -f dockerfiles/Dockerfile.virt-launcher .

.PHONY: build-virt-exportproxy-image
build-virt-exportproxy-image: build-virt-exportproxy
	@echo "Building virt-exportproxy image for $(ARCH)..."
	podman build --platform=linux/$(ARCH) -t $(VIRT_EXPORTPROXY_IMAGE) -f dockerfiles/Dockerfile.virt-exportproxy .

.PHONY: build-virt-exportserver-image
build-virt-exportserver-image: build-virt-exportserver
	@echo "Building virt-exportserver image for $(ARCH)..."
	podman build --platform=linux/$(ARCH) -t $(VIRT_EXPORTSERVER_IMAGE) -f dockerfiles/Dockerfile.virt-exportserver .

.PHONY: push-images
push-images:
	@echo "Pushing images to registry..."
	podman push $(VIRT_OPERATOR_IMAGE)
	podman push $(VIRT_API_IMAGE)
	podman push $(VIRT_CONTROLLER_IMAGE)
	podman push $(VIRT_HANDLER_IMAGE)
	podman push $(VIRT_LAUNCHER_IMAGE)
	podman push $(VIRT_EXPORTPROXY_IMAGE)
	podman push $(VIRT_EXPORTSERVER_IMAGE)

.PHONY: help
help:
	@echo "KubeVirt Downstream Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all                - Build all binaries and images"
	@echo "  build-binaries     - Build all Go binaries"
	@echo "  build-images       - Build all container images"
	@echo "  push-images        - Push all images to registry"
	@echo "  clean              - Clean build artifacts"
	@echo ""
	@echo "Configuration:"
	@echo "  REGISTRY=$(REGISTRY)"
	@echo "  VERSION=$(VERSION)"
	@echo "  ARCH=$(ARCH)"