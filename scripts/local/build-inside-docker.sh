#!/bin/bash
set -euo pipefail

KERNEL_CONFIG_PATH="$1"
KERNEL_VERSION="6.16.7"
RPMBUILD_ROOT="/root/rpmbuild"
SOURCES_DIR="$RPMBUILD_ROOT/SOURCES"
BUILD_DIR="$RPMBUILD_ROOT/BUILD"
BUILDROOT_DIR="$RPMBUILD_ROOT/BUILDROOT"

echo ">>> Refreshing repositories and accepting GPG keys..."
zypper --non-interactive --gpg-auto-import-keys ref

echo ">>> Installing build dependencies..."
zypper --non-interactive install \
    bc bison flex gcc make ncurses-devel perl rpm-build tar xz wget

echo ">>> Preparing build directories..."
mkdir -p "$SOURCES_DIR" "$BUILD_DIR" "$BUILDROOT_DIR"

echo ">>> Downloading kernel sources..."
cd "$SOURCES_DIR"
if [[ ! -f linux-$KERNEL_VERSION.tar.xz ]]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz
fi

echo ">>> Extracting sources..."
cd "$BUILD_DIR"
rm -rf custom-kernel-$KERNEL_VERSION
mkdir -p custom-kernel-$KERNEL_VERSION
cd custom-kernel-$KERNEL_VERSION
tar -xf "$SOURCES_DIR/linux-$KERNEL_VERSION.tar.xz"
cd linux-$KERNEL_VERSION

echo ">>> Copying kernel config..."
cp "/workspace/$KERNEL_CONFIG_PATH" .config

echo ">>> Preparing RPM build tree..."
RPMBUILD_SPEC="$SOURCES_DIR/custom-kernel.spec"
cat > "$RPMBUILD_SPEC" <<'EOF'
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
make -s -j$(nproc)
%install
mkdir -p %{buildroot}/boot
cp -v arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-%{version}-custom
EOF

echo ">>> Building RPM..."
rpmbuild -bb --define "_topdir $RPMBUILD_ROOT" "$RPMBUILD_SPEC"

echo ">>> Build finished. RPMs located in $RPMBUILD_ROOT/RPMS/"
