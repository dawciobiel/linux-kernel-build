#!/bin/bash
set -euo pipefail

# Usage: ./build-kernel-local-docker.sh <kernel-config-path> [kernel-version]
KERNEL_CONFIG_PATH=${1:-}
KERNEL_VERSION=${2:-6.16.7}   # default kernel version

if [[ ! -f "$KERNEL_CONFIG_PATH" ]]; then
    echo 'ERROR: Kernel config file not found:' "$KERNEL_CONFIG_PATH"
    exit 1
fi

# Katalog na RPM-y po stronie hosta
HOST_RPM_DIR="$PWD/host_rpms"
mkdir -p "$HOST_RPM_DIR"

echo '>>> Building kernel in Docker (openSUSE Tumbleweed)...'
echo '>>> Kernel config:' "$KERNEL_CONFIG_PATH"

docker run --rm -it \
    -v "$PWD/$KERNEL_CONFIG_PATH":/workspace/kernel.config:ro \
    -v "$HOST_RPM_DIR":/root/rpmbuild/RPMS \
    tumbleweed-kernel:latest \
    bash -c "
set -euo pipefail

KERNEL_VERSION='$KERNEL_VERSION'

echo '>>> Using kernel config: /workspace/kernel.config'

# Build directories inside container
BUILD_DIR=/root/rpmbuild/BUILD/custom-kernel-\$KERNEL_VERSION-build
SOURCES_DIR=/root/rpmbuild/SOURCES
mkdir -p \$BUILD_DIR \$SOURCES_DIR /root/rpmbuild/BUILDROOT

echo '>>> Downloading kernel sources (cached if exists)...'
cd \$SOURCES_DIR
wget -nc https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-\$KERNEL_VERSION.tar.xz

echo '>>> Extracting sources...'
cd \$BUILD_DIR
if [[ ! -d linux-\$KERNEL_VERSION ]]; then
    tar -xf \$SOURCES_DIR/linux-\$KERNEL_VERSION.tar.xz
fi

echo '>>> Copying kernel config...'
cp /workspace/kernel.config linux-\$KERNEL_VERSION/.config

echo '>>> Preparing RPM spec file...'
RPMBUILD_SPEC=\$SOURCES_DIR/custom-kernel.spec
cat > \$RPMBUILD_SPEC <<'EOF'
Name:           custom-kernel
Version:        __KERNEL_VERSION__
Release:        1
Summary:        Custom kernel built locally
License:        GPL
Group:          System Environment/Kernel
Source0:        linux-__KERNEL_VERSION__.tar.xz
BuildRoot:      %{_topdir}/BUILD/%{name}-%{version}-build
%description
Custom Linux kernel built locally.
%prep
%setup -q -n linux-__KERNEL_VERSION__
%build
make O=%{_builddir}/linux-__KERNEL_VERSION__ olddefconfig
make -j\$(nproc) O=%{_builddir}/linux-__KERNEL_VERSION__
%install
mkdir -p %{buildroot}/boot
cp -v arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-%{version}-custom
%files
/boot/vmlinuz-%{version}-custom
EOF

sed -i \"s/__KERNEL_VERSION__/\$KERNEL_VERSION/g\" \$RPMBUILD_SPEC

echo '>>> Building RPM...'
rpmbuild -bb --define '_topdir /root/rpmbuild' \$RPMBUILD_SPEC

echo '>>> Kernel build completed. RPMs are in /root/rpmbuild/RPMS/'
"

echo '>>> Done. Host RPMs are in:' "$HOST_RPM_DIR"
