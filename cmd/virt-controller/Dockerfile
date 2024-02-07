#FROM quay.io/centos/centos:stream9
FROM quay.io/fedora/fedora:39-ppc64le AS BUILD
#FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS BUILD

RUN chmod 0644 /etc/passwd
RUN echo "nonroot-user:x:1001:1001:nonroot-user:/home/nonroot-user:/bin/bash" >> /etc/passwd
USER 1001
COPY virt-controller /usr/bin/virt-controller
ENTRYPOINT [ "/usr/bin/virt-controller" ]
