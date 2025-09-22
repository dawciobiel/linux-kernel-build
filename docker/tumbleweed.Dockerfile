# Dockerfile for local kernel build on openSUSE Tumbleweed
FROM opensuse/tumbleweed:latest

# Update repositories and install all required build dependencies
RUN zypper --non-interactive ref && \
    zypper --non-interactive --gpg-auto-import-keys install \
        bash \
        bc \
        bison \
        flex \
        gcc \
        make \
        ncurses-devel \
        perl \
        rpm-build \
        tar \
        xz \
        wget \
        curl \
        libelf-devel \
        libuuid-devel \
        libblkid-devel \
        libselinux-devel \
        zlib-devel \
        libopenssl-devel \
        libcap-devel \
        libattr-devel \
        libseccomp-devel \
        gettext-tools \
        elfutils \
        gnu_parallel \
        python3 \
        python3-devel \
        git \
        fakeroot

# Set working directory inside container
WORKDIR /workspace

# Default command: bash shell
CMD ["/bin/bash"]
