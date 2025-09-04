#FROM quay.io/centos/centos:stream9
FROM quay.io/fedora/fedora:39-ppc64le AS BUILD
#FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS BUILD

COPY virt-api /usr/bin/virt-api
USER 1001
ENTRYPOINT [ "/usr/bin/virt-api" ]
