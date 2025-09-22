#!/bin/bash
set -euo pipefail

CONFIG_PATH="$1"

if [ -z "$CONFIG_PATH" ]; then
  echo "Usage: $0 <path-to-kernel-config>"
  exit 1
fi

# Paths
KERNEL_SRC_DIR="/usr/src/linux-6.16.7-1"
BUILD_OBJ_DIR="/usr/src/linux-6.16.7-1-obj"
RPMBUILD_DIR="/usr/src/packages"

# Install required tools
zypper -n in --no-recommends \
  bc bison flex gcc git make ncurses-devel perl \
  rpm-build wget kernel-source

# Prepare directories
mkdir -p "$BUILD_OBJ_DIR/x86_64/default"
mkdir -p "$RPMBUILD_DIR/BUILD" "$RPMBUILD_DIR/RPMS" "$RPMBUILD_DIR/SOURCES" "$RPMBUILD_DIR/SPECS" "$RPMBUILD_DIR/SRPMS"

# Copy config
cp -u "$CONFIG_PATH" "$BUILD_OBJ_DIR/x86_64/default/.config"

# Prepare kernel config
make -C "$KERNEL_SRC_DIR" O="$BUILD_OBJ_DIR" olddefconfig

# Locate kernel.spec from kernel-source
KERNEL_SPEC=$(rpm -ql kernel-source | grep 'kernel.spec$' | head -n1)

if [ -z "$KERNEL_SPEC" ]; then
  echo "ERROR: kernel.spec not found in kernel-source package"
  exit 1
fi

# Copy spec to rpmbuild tree
cp "$KERNEL_SPEC" "$RPMBUILD_DIR/SPECS/kernel.spec"

# Copy .config to SOURCES (needed by rpmbuild)
cp "$CONFIG_PATH" "$RPMBUILD_DIR/SOURCES/.config"

# Build RPMs
rpmbuild -bb --define "_topdir $RPMBUILD_DIR" --with baseonly "$RPMBUILD_DIR/SPECS/kernel.spec"

echo "✅ Kernel RPM build finished. Find packages in: $RPMBUILD_DIR/RPMS/"
