#!/bin/bash
set -euo pipefail

# ---- CONFIGURATION ----
CONFIG_PATH="$1"

if [ -z "$CONFIG_PATH" ]; then
  echo "Usage: $0 <config-path>"
  exit 1
fi

KERNEL_SRC_DIR="/usr/src/linux-6.16.7-1"
BUILD_OBJ_DIR="/usr/src/linux-6.16.7-1-obj"
RPMBUILD_DIR="/usr/src/packages"

echo ">>> Installing build dependencies..."
zypper -n ref
zypper -n in bc bison flex gcc git make ncurses-devel perl \
  rpm-build wget libopenssl-devel libelf-devel dwarves

echo ">>> Installing kernel source..."
zypper -n si kernel-source
zypper -n in kernel-source

echo ">>> Preparing build directories..."
mkdir -p "$BUILD_OBJ_DIR/x86_64/default"
mkdir -p "$RPMBUILD_DIR/BUILD" "$RPMBUILD_DIR/RPMS" "$RPMBUILD_DIR/SOURCES" "$RPMBUILD_DIR/SPECS" "$RPMBUILD_DIR/SRPMS"

cp "$CONFIG_PATH" "$BUILD_OBJ_DIR/x86_64/default/.config"

echo ">>> Running olddefconfig..."
cd "$KERNEL_SRC_DIR"
make O="$BUILD_OBJ_DIR" olddefconfig

echo ">>> Building kernel RPMs..."
make O="$BUILD_OBJ_DIR" -j"$(nproc)" rpm

echo ">>> Build finished. RPMs are in $RPMBUILD_DIR/RPMS/"
ls -lh "$RPMBUILD_DIR"/RPMS/* || true
