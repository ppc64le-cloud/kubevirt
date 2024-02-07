#FROM quay.io/centos/centos:stream9
FROM quay.io/fedora/fedora:39-ppc64le AS BUILD
#FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS BUILD
#FROM gcr.io/distroless/base-debian12:nonroot-ppc64le

# Set permissions for passwd file
RUN chmod 0644 /etc/passwd
RUN adduser nonroot-user
ARG USERNAME=nonroot-user
ARG USER_UID=1001
ARG USER_GID=$USER_UID

RUN groupmod --gid $USER_GID $USERNAME \
    && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
    && chown -R $USER_UID:$USER_GID /home/$USERNAME

#RUN groupadd --gid 1001 nonroot-user && useradd --uid 1001 --gid 1001 -m nonroot-user
#RUN echo "nonroot-user:x:1001:1001:nonroot-user:/home/nonroot-user:/bin/bash" >> /etc/passwd
COPY virt-api /usr/bin/virt-api
#RUN useradd -ms /bin/bash nonroot-user
ENTRYPOINT [ "/usr/bin/virt-api" ]
LABEL visibility=public
USER 1001
