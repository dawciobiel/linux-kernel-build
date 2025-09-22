#!/usr/bin/env bash
set -euo pipefail

# =========================
# User-configurable variables
# =========================
CONFIG_PATH="${1:-kernel-config/6.16.7-1-default.custom/current}"  # path to your kernel config
KERNEL_VERSION="6.16.7"
KERNEL_SRC_DIR="/usr/src/linux-${KERNEL_VERSION}-1"
BUILD_OBJ_DIR="${KERNEL_SRC_DIR}-obj"
RPMBUILD_DIR="/usr/src/packages"
ARCH="x86_64"

# =========================
# Prepare build environment
# =========================
echo ">>> Installing build dependencies..."
zypper -n refresh
zypper -n install -t pattern devel_C_C++ devel_basis \
    bc bison elfutils-devel flex gcc git make ncurses-devel perl rpm-build wget rpm-sign

# =========================
# Download and extract kernel sources
# =========================
echo ">>> Downloading kernel sources..."
wget -O "linux-${KERNEL_VERSION}.tar.xz" "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"

echo ">>> Preparing build directories..."
mkdir -p "$KERNEL_SRC_DIR"
mkdir -p "$BUILD_OBJ_DIR/$ARCH/default"
mkdir -p "$RPMBUILD_DIR/BUILD" "$RPMBUILD_DIR/RPMS" "$RPMBUILD_DIR/SOURCES" "$RPMBUILD_DIR/SPECS" "$RPMBUILD_DIR/SRPMS"

# Rozpakowanie źródeł bez podkatalogu linux-6.16.7
tar -xf "linux-${KERNEL_VERSION}.tar.xz" -C "$KERNEL_SRC_DIR" --strip-components=1

# Skopiowanie customowego configa
if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "ERROR: Custom config not found at $CONFIG_PATH"
    exit 1
fi
cp -u "$CONFIG_PATH" "$BUILD_OBJ_DIR/$ARCH/default/.config"
cp "$CONFIG_PATH" "$RPMBUILD_DIR/SOURCES/.config"

# =========================
# Prepare kernel build
# =========================
echo ">>> Running kernel olddefconfig..."
make -C "$KERNEL_SRC_DIR" O="$BUILD_OBJ_DIR" olddefconfig

# =========================
# Create kernel.spec if not exist
# =========================
KERNEL_SPEC="$RPMBUILD_DIR/SPECS/kernel.spec"
if [[ ! -f "$KERNEL_SPEC" ]]; then
    echo ">>> Downloading openSUSE kernel.spec..."
    wget -O "$KERNEL_SPEC" "https://build.opensuse.org/projects/openSUSE:Factory:Kernel/packages/linux/files/kernel.spec"
fi

# =========================
# Import GPG key for signing RPMs
# =========================
if [[ -n "${GPG_PRIVATE_KEY:-}" ]]; then
    echo "$GPG_PRIVATE_KEY" | gpg --batch --import
fi

# =========================
# Build RPMs
# =========================
echo ">>> Building RPMs..."
rpmbuild -bb --define "_topdir $RPMBUILD_DIR" --with baseonly "$KERNEL_SPEC"

# =========================
# Sign RPMs if GPG passphrase is provided
# =========================
if [[ -n "${GPG_PASSPHRASE:-}" ]]; then
    echo ">>> Signing RPMs with passphrase..."
    for rpm in "$RPMBUILD_DIR/RPMS/$ARCH"/*.rpm; do
        if [[ -f "$rpm" ]]; then
            rpmsign --addsign --passphrase "$GPG_PASSPHRASE" "$rpm"
        fi
    done
fi

echo ">>> Kernel RPMs build complete!"
echo ">>> Output directory: $RPMBUILD_DIR/RPMS/$ARCH/"
