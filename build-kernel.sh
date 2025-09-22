#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="$1"

# Kernel source & build dirs
KERNEL_SRC_DIR=/usr/src/linux-6.16.7-1
BUILD_OBJ_DIR=/usr/src/linux-6.16.7-1-obj
RPMBUILD_DIR=/usr/src/packages

echo ">>> Refreshing repositories..."
zypper --non-interactive refresh

echo ">>> Installing required packages..."
zypper --non-interactive install \
    bc \
    bison \
    elfutils \
    elfutils-devel \
    flex \
    gcc \
    git \
    make \
    ncurses-devel \
    perl \
    rpm-build \
    rpm-sign \
    wget

echo ">>> Preparing build directories..."
mkdir -p "$BUILD_OBJ_DIR/x86_64/default"
mkdir -p "$RPMBUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

echo ">>> Copying kernel config..."
cp -u "$CONFIG_PATH" "$BUILD_OBJ_DIR/x86_64/default/.config"
cp "$CONFIG_PATH" "$RPMBUILD_DIR/SOURCES/.config"

echo ">>> Downloading kernel sources..."
if [ ! -f linux-6.16.7.tar.xz ]; then
    wget -O linux-6.16.7.tar.xz https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.16.7.tar.xz
fi

echo ">>> Extracting kernel sources..."
tar -xf linux-6.16.7.tar.xz -C /usr/src/
mv /usr/src/linux-6.16.7 "$KERNEL_SRC_DIR"

echo ">>> Building kernel RPM..."
make -C "$KERNEL_SRC_DIR" O="$BUILD_OBJ_DIR" olddefconfig
make -C "$KERNEL_SRC_DIR" O="$BUILD_OBJ_DIR" -j"$(nproc)" rpm

echo ">>> Kernel RPM build complete."
