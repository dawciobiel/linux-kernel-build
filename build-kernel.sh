#!/bin/bash
set -euo pipefail

# === Variables ===
CONFIG_PATH="${1:-kernel-config/6.16.7-1-default.custom/current}"
KERNEL_VERSION="6.16.7"
KERNEL_SRC_DIR="/usr/src/linux-$KERNEL_VERSION"
BUILD_OBJ_DIR="/usr/src/linux-$KERNEL_VERSION-obj"
RPMBUILD_DIR="/usr/src/packages"

# === Install dependencies ===
zypper -n ref
zypper -n in -t pattern devel_C_C++ \
    bc bison flex gcc make ncurses-devel perl rpm-build wget

# === Download kernel sources if not exists ===
if [ ! -f "$KERNEL_VERSION.tar.xz" ]; then
    wget -O "linux-$KERNEL_VERSION.tar.xz" "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz"
fi

# === Extract sources ===
mkdir -p "$KERNEL_SRC_DIR"
tar -xf "linux-$KERNEL_VERSION.tar.xz" -C /usr/src
mv /usr/src/linux-$KERNEL_VERSION "$KERNEL_SRC_DIR" || true

# === Prepare build directories ===
mkdir -p "$BUILD_OBJ_DIR/x86_64/default"
cp -u "$CONFIG_PATH" "$BUILD_OBJ_DIR/x86_64/default/.config"

mkdir -p "$RPMBUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# === Kernel build ===
make -C "$KERNEL_SRC_DIR" O="$BUILD_OBJ_DIR" olddefconfig
make -C "$KERNEL_SRC_DIR" O="$BUILD_OBJ_DIR" -j"$(nproc)"

# === Create RPM ===
cp "$CONFIG_PATH" "$RPMBUILD_DIR/SOURCES/.config"
# Create a minimal kernel.spec if not exists
if [ ! -f "$RPMBUILD_DIR/SPECS/kernel.spec" ]; then
cat > "$RPMBUILD_DIR/SPECS/kernel.spec" <<'EOF'
Name: kernel-custom
Version: 6.16.7
Release: 1
Summary: Custom Linux kernel
License: GPL
Source0: .config
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
%description
Custom Linux kernel built via GitHub Actions.
%prep
%build
make -C /usr/src/linux-6.16.7-1-obj -j$(nproc)
%install
mkdir -p %{buildroot}/boot
cp /usr/src/linux-6.16.7-1-obj/arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-%{version}-custom
%files
/boot/vmlinuz-%{version}-custom
EOF
fi

rpmbuild -bb --define "_topdir $RPMBUILD_DIR" "$RPMBUILD_DIR/SPECS/kernel.spec"

echo "Kernel RPM build complete."
