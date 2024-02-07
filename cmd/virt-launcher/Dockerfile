#FROM quay.io/centos/centos:stream9
FROM quay.io/fedora/fedora:39-ppc64le AS BUILD
#FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS BUILD
RUN chmod 0644 /etc/passwd
RUN echo "nonroot-user:x:1001:1001:nonroot-user:/home/nonroot-user:/bin/bash" >> /etc/passwd
RUN groupadd -g 107 qemu
RUN echo "root:x:0:0:root:/root:/bin/bash" >> /etc/passwd
RUN echo "qemu:x:107:107:qemu:/home/qemu:/bin/bash" >> /etc/passwd

RUN dnf install -y libvirt-devel qemu
COPY virt-launcher /usr/bin/virt-launcher
COPY virt-launcher-monitor /usr/bin/virt-launcher-monitor
COPY virt-tail /usr/bin/virt-tail
COPY virt-probe /usr/bin/virt-probe
COPY virt-freezer /usr/bin/virt-freezer
COPY node-labeller.sh /usr/bin/node-labeller.sh
COPY container-disk /usr/bin/container-disk

COPY qemu.conf /etc/libvirt/qemu.conf
COPY virtqemud.conf /etc/libvirt/virtqemud.conf
COPY --chmod=0644 nsswitch.conf /etc/nsswitch.conf
WORKDIR /usr/lib64/qemu-kvm
RUN chmod 0755 /usr/lib64/qemu-kvm

RUN dnf install -y acl \
		alternatives \
		audit-libs \
		basesystem \
		bash \
  		bzip2 \
		bzip2-libs \
		ca-certificates \
		capstone \
		cracklib \
		cracklib-dicts \
		crypto-policies \
		cyrus-sasl \
 		cyrus-sasl-gssapi \
		cyrus-sasl-lib \
		daxctl-libs \
		dbus \
		dbus-broker \
		dbus-common \
		diffutils \
		elfutils-libelf \
		ethtool \
		expat \
		filesystem \
		findutils \
		gawk \
		gdbm-libs \
		gettext \
		gettext-libs \
		glib2 \
		glibc \
		glibc-common \
		glibc-minimal-langpack \
		gmp \
		gnutls \
		gnutls-dane \
		gnutls-utils \
		grep \
		gzip \
		iproute \
		iproute-tc \
		iptables \
		iptables-libs \
		ipxe-roms-qemu \
		jansson \
		json-glib \
		keyutils-libs \
		kmod-libs \
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
		libdb \
		libeconf \
		libevent \
		libfdisk \
		libfdt \
		libffi \
		libgcc \
		libgcrypt \
		libgomp \
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
		libpcap \
		libpmem \
		libpng \
		libpwquality \
		librdmacm \
		libseccomp \
		libselinux \
		libselinux-utils \
		libsemanage \
		libsepol \
		libsigsegv \
		libslirp \
		libsmartcols \
		libssh \
		libssh-config \
		libtasn1 \
		libtirpc \
		libtpms \
		libunistring \
		liburing \
		libusbx \
		libutempter \
		libuuid \
		libverto \
		libvirt-client \
		libvirt-daemon-common \
		libvirt-daemon-driver-qemu \
		libvirt-daemon-log \
		libvirt-libs \
		libxcrypt \
		libxml2 \
		libzstd \
		lua-libs \
		lz4-libs \
		lzo \
		lzop \
		mpfr \
		ncurses-base \
		ncurses-libs \
		ndctl-libs \
		nettle \
		nftables \
		nmap-ncat \
		numactl-libs \
		numad \
		openldap \
		openssl \
		openssl-libs \
		p11-kit \
		p11-kit-trust \
		pam \
		passt \
		pcre \
		pcre2 \
		pcre2-syntax \
		pixman \
		policycoreutils \
		polkit \
		polkit-libs \
		polkit-pkla-compat \
		popt procps-ng \
		psmisc \
		qemu-img \
		qemu-kvm-core \
		readline \
		rpm rpm-libs \
		rpm-plugin-selinux \
		sed selinux-policy \
		seabios seabios-bin \
		seavgabios-bin \
		selinux-policy-targeted \
		setup shadow-utils \
		snappy \
		sqlite-libs \
		swtpm swtpm-libs \
		swtpm-tools \
		systemd \
		systemd-container \
		systemd-libs \
		systemd-pam \
		systemd-rpm-macros \
		tar tzdata \
		unbound-libs \
		usbredir \
		libstdc++ \
		qemu-device-usb-host \
		qemu-device-usb-redirect \
		qemu-common \
		util-linux util-linux-core \
		vim-minimal \
		virtiofsd xz \
		xorriso yajl \
		xz-libs zlib
#USER 1001
ENTRYPOINT [ "/usr/bin/virt-launcher" ]
