#FROM quay.io/centos/centos:stream9
FROM quay.io/fedora/fedora:39-ppc64le AS BUILD
#FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS BUILD

RUN dnf install -y libvirt-devel qemu
COPY virt-launcher /usr/bin/virt-launcher
COPY virt-launcher-monitor /usr/bin/virt-launcher-monitor
COPY virt-tail /usr/bin/virt-tail
COPY virt-probe /usr/bin/virt-probe
COPY virt-freezer /usr/bin/virt-freezer
COPY node-labeller.sh /usr/bin/node-labeller.sh

ENTRYPOINT [ "/usr/bin/virt-launcher" ]
