#FROM quay.io/centos/centos:stream9
FROM quay.io/fedora/fedora:39-ppc64le AS BUILD
#FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS BUILD

#RUN groupadd -g 0 root
RUN groupadd -g 107 qemu
RUN echo "root:x:0:0:root:/root:/bin/bash" >> /etc/passwd
RUN echo "qemu:x:107:107:qemu:/:/bin/bash" >> /etc/passwd
COPY virt-handler /usr/bin/virt-handler
COPY virt-chroot /usr/bin/virt-chroot
COPY nsswitch.conf /etc/nsswitch.conf
COPY virt_launcher.cil /root/virt_launcher.cil

RUN dnf install -y acl \
		alternatives \
		audit-libs \
		basesystem \
		bash \
		bzip2-libs \
		ca-certificates \
		coreutils \
		cracklib \
		cracklib-dicts \
		crypto-policies \
		curl \
		diffutils \
		elfutils-libelf \
		filesystem \
		findutils \
		gawk \
		glib2 \
		glibc \
		glibc-common \
		glibc-minimal-langpack \
		gmp \
		gnutls \
		grep \
		gzip \
		iproute \
		iptables \
		jansson \
		keyutils-libs \
		krb5-libs \
		libacl \
		libaio \
		libarchive \
		libattr \
		libblkid \
		libbpf \
		libburn \
		libcap \
		libcap-ng \
		libcom_err \
		libcurl \
		libdb \
		libeconf \
		libfdisk \
		libffi \
		libgcc \
		libgcrypt \
		libgpg-error \
		libibverbs \
		libidn2 \
		libisoburn \
		libisofs \
		libmnl \
		libmount \
		libnetfilter_conntrack \
		libnfnetlink \
		libnftnl \
		libnghttp2 \
		libnl3 \
		libpwquality \
		libselinux \
		libselinux-utils \
		libsemanage \
		libsepol \
		libsigsegv \
		libsmartcols \
		libtasn1 \
		libunistring \
		liburing \
		libutempter \
		libuuid \
		libverto \
		libxcrypt \
		libxml2 \
		libzstd \
		lua-libs \
		lz4-libs \
		mpfr \
		ncurses-base \
		ncurses-libs nettle \
		nftables \
		numactl-libs \
		openssl \
		openssl-libs \
		p11-kit \
		p11-kit-trust \
		pam \
		pcre \
		pcre2 \
		pcre2-syntax \
		policycoreutils \
		popt procps-ng \
		psmisc \
		qemu-img \
		readline \
		rpm rpm-libs \
		rpm-plugin-selinux \
		sed selinux-policy \
		selinux-policy-targeted \
		setup shadow-utils \
		sqlite-libs \
		systemd-libs \
		tar tzdata \
		util-linux util-linux-core \
		vim-minimal xorriso \
		xz-libs zlib

ENTRYPOINT [ "/usr/bin/virt-handler" ]
