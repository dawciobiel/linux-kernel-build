#!/bin/bash
set -euo pipefail

# ---- CONFIGURATION ----
CONFIG_PATH="$1"

if [ -z "$CONFIG_PATH" ]; then
  echo "Usage: $0 <config-path>"
  exit 1
fi

# Kernel version
KERNEL_VERSION="6.16.7"
KERNEL_SRC_DIR="/usr/src/linux-${KERNEL_VERSION}"
BUILD_OBJ_DIR="/usr/src/linux-${KERNEL_VERSION}-obj"
RPMBUILD_DIR="/usr/src/packages"

echo ">>> Installing build dependencies..."
zypper -n ref
zypper -n in bc bison flex gcc git make ncurses-devel perl \
  rpm-build wget libopenssl-devel libelf-devel dwarves xz

echo ">>> Downloading kernel sources..."
cd /usr/src
if [ ! -d "$KERNEL_SRC_DIR" ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz
    tar -xf linux-${KERNEL_VERSION}.tar.xz
    mv linux-${KERNEL_VERSION} "$KERNEL_SRC_DIR"
fi

echo ">>> Preparing build directories..."
mkdir -p "$BUILD_OBJ_DIR/x86_64/default"
mkdir -p "$RPMBUILD_DIR/BUILD" "$RPMBUILD_DIR/RPMS" "$RPMBUILD_DIR/SOURCES" "$RPMBUILD_DIR/SPECS" "$RPMBUILD_DIR/SRPMS"

# Copy custom config to build object directory
cp "$CONFIG_PATH" "$BUILD_OBJ_DIR/x86_64/default/.config"

echo ">>> Running olddefconfig..."
make -C "$KERNEL_SRC_DIR" O="$BUILD_OBJ_DIR" olddefconfig

echo ">>> Building kernel RPMs..."
make -C "$KERNEL_SRC_DIR" O="$BUILD_OBJ_DIR" -j"$(nproc)" rpm

echo ">>> Build finished. RPMs are in $RPMBUILD_DIR/RPMS/"
ls -lh "$RPMBUILD_DIR"/RPMS/* || true
