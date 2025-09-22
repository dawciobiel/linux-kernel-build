#!/bin/bash
set -euo pipefail

KERNEL_CONFIG_PATH=${1:-}
KERNEL_VERSION="6.16.7"
RPMBUILD_ROOT="/root/rpmbuild"
SOURCES_DIR="$RPMBUILD_ROOT/SOURCES"
BUILD_DIR="$RPMBUILD_ROOT/BUILD"
BUILDROOT_DIR="$RPMBUILD_ROOT/BUILDROOT"

echo '>>> Refreshing repositories and installing build dependencies...'
zypper --non-interactive ref
zypper --non-interactive --gpg-auto-import-keys install \
    bc bison flex gcc make ncurses-devel perl rpm-build tar xz wget
zypper clean -a

echo '>>> Preparing build directories...'
mkdir -p $SOURCES_DIR $BUILD_DIR $BUILDROOT_DIR

echo '>>> Downloading kernel sources...'
cd $SOURCES_DIR
if [[ ! -f linux-$KERNEL_VERSION.tar.xz ]]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz
fi

echo '>>> Extracting sources...'
cd $BUILD_DIR
rm -rf linux-$KERNEL_VERSION
tar -xf $SOURCES_DIR/linux-$KERNEL_VERSION.tar.xz

echo '>>> Copying kernel config...'
cp "$KERNEL_CONFIG_PATH" linux-$KERNEL_VERSION/.config

echo '>>> Preparing RPM spec file...'
RPMBUILD_SPEC=$SOURCES_DIR/custom-kernel.spec
cat > $RPMBUILD_SPEC <<'EOF'
Name:           custom-kernel
Version:        6.16.7
Release:        1
Summary:        Custom kernel built locally
License:        GPL
Group:          System Environment/Kernel
Source0:        linux-6.16.7.tar.xz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
%description
Custom Linux kernel built locally.
%prep
%setup -q
%build
make olddefconfig
make -j$(nproc)
%install
mkdir -p %{buildroot}/boot
cp -v arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-%{version}-custom
EOF

echo '>>> Building RPM...'
rpmbuild -bb --define "_topdir /root/rpmbuild" $RPMBUILD_SPEC

echo ">>> Kernel build finished. RPMs are in $RPMBUILD_ROOT/RPMS/"
