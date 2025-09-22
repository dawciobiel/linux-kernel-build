#!/bin/bash
set -euo pipefail

# build-kernel.sh
# Usage: ./build-kernel.sh <path-to-config>
#
# Script will:
#  - prepare build dirs
#  - copy provided .config into build tree
#  - run olddefconfig (non-interactive)
#  - generate kernel.spec using rpm/mkspec (from kernel-source) if available
#  - rpmbuild -bb using _topdir mapped to /usr/src/packages (mounted from host)
#  - sign resulting RPMs with GPG key from env GPG_PRIVATE_KEY and passphrase GPG_PASSPHRASE
#  - write a verbose log to /workspace/build.log (workspace is mounted by workflow)

LOGFILE="/workspace/build.log"
mkdir -p "$(dirname "$LOGFILE")"
# tee all output to log (and to console)
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== build-kernel.sh start ==="
CONFIG_PATH="${1:-}"

if [ -z "$CONFIG_PATH" ]; then
  echo "Usage: $0 <path-to-kernel-config-in-repo>"
  exit 1
fi

if [ ! -f "$CONFIG_PATH" ]; then
  echo "Config file not found: $CONFIG_PATH"
  exit 1
fi

# Paths (inside container)
KERNEL_SRC_DIR="/usr/src/linux-6.16.7-1"
BUILD_OBJ_DIR="/usr/src/linux-6.16.7-1-obj"
RPMBUILD_DIR="/usr/src/packages"   # **should be mounted from host (repo)/packages -> /usr/src/packages

echo "CONFIG_PATH: $CONFIG_PATH"
echo "KERNEL_SRC_DIR: $KERNEL_SRC_DIR"
echo "BUILD_OBJ_DIR: $BUILD_OBJ_DIR"
echo "RPMBUILD_DIR: $RPMBUILD_DIR"

# Ensure required packages (kernel-source + build tools)
zypper -n ref || true
zypper -n in --no-recommends \
  bc bison flex gcc git make ncurses-devel perl rpm-build libelf-devel kernel-devel kernel-source wget tar gzip

# Prepare directories
mkdir -p "$BUILD_OBJ_DIR/x86_64/default"
mkdir -p "$RPMBUILD_DIR/BUILD" "$RPMBUILD_DIR/RPMS" "$RPMBUILD_DIR/SOURCES" "$RPMBUILD_DIR/SPECS" "$RPMBUILD_DIR/SRPMS"

# Copy config to build-tree (incremental)
echo "Copying config to build obj dir..."
cp -u "$CONFIG_PATH" "$BUILD_OBJ_DIR/x86_64/default/.config"

# Non-interactive update to accept defaults for new options
echo "Running non-interactive olddefconfig..."
make -C "$KERNEL_SRC_DIR" O="$BUILD_OBJ_DIR" olddefconfig

# Generate kernel.spec via rpm/mkspec (preferred)
echo "Looking for rpm/mkspec to generate kernel.spec..."
if [ -x "$KERNEL_SRC_DIR/rpm/mkspec" ]; then
  echo "Found $KERNEL_SRC_DIR/rpm/mkspec, generating spec..."
  (cd "$KERNEL_SRC_DIR" && ./rpm/mkspec > "$RPMBUILD_DIR/SPECS/kernel.spec")
else
  # Try to find mkspec via rpm -ql kernel-source
  MKSPEC_PATH=$(rpm -ql kernel-source 2>/dev/null | grep '/rpm/mkspec$' | head -n1 || true)
  if [ -n "$MKSPEC_PATH" ]; then
    MKSPEC_DIR="$(dirname "$MKSPEC_PATH")"
    # MKSPEC_DIR typically is /usr/src/linux-XXXX/rpm
    echo "Found mkspec at $MKSPEC_PATH, running it..."
    (cd "$MKSPEC_DIR/.." && ./rpm/mkspec > "$RPMBUILD_DIR/SPECS/kernel.spec")
  else
    echo "ERROR: rpm/mkspec not found in kernel-source. Cannot generate kernel.spec."
    echo "Possible fixes:"
    echo " - Ensure kernel-source package is installed and matches kernel version you want to build"
    echo " - OR add an appropriate kernel.spec into the repo at packages/SPECS/kernel.spec"
    exit 1
  fi
fi

# Copy custom .config to rpmbuild SOURCES (many spec files expect it there)
cp "$CONFIG_PATH" "$RPMBUILD_DIR/SOURCES/.config"

# (Optional) inspect generated spec for debugging
echo "Generated spec head (first 40 lines):"
head -n 40 "$RPMBUILD_DIR/SPECS/kernel.spec" || true

# Run rpmbuild
echo "Running rpmbuild..."
rpmbuild -bb --define "_topdir $RPMBUILD_DIR" --with baseonly "$RPMBUILD_DIR/SPECS/kernel.spec"

# Sign RPMs (if any)
if [ -n "${GPG_PRIVATE_KEY:-}" ] && [ -n "${GPG_PASSPHRASE:-}" ]; then
  echo "Importing GPG key and signing RPMs..."
  echo "$GPG_PRIVATE_KEY" > /tmp/private.key
  gpg --batch --import /tmp/private.key

  for rpm in "$RPMBUILD_DIR"/RPMS/x86_64/*.rpm; do
    if [ -f "$rpm" ]; then
      echo "Signing $rpm"
      rpmsign --addsign --passphrase "$GPG_PASSPHRASE" "$rpm"
    fi
  done

  rm -f /tmp/private.key
else
  echo "GPG_PRIVATE_KEY or GPG_PASSPHRASE not provided; skipping signing."
fi

echo "=== build-kernel.sh finished ==="
echo "Built RPMs (if successful) are in: $RPMBUILD_DIR/RPMS/x86_64/"
