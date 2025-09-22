#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Custom Kernel RPM Builder
# -----------------------------

# Parametry
CONFIG_PATH="${1:-}"   # np. kernel-config/6.16.7-1-default.custom/current
KERNEL_VERSION="6.16.7"
KERNEL_TARBALL="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_SRC_DIR="/usr/src/linux-${KERNEL_VERSION}"
BUILD_OBJ_DIR="/usr/src/packages/BUILD/custom-kernel-${KERNEL_VERSION}-build"
RPMBUILD_DIR="/usr/src/packages"
CUSTOM_CONFIG="${RPMBUILD_DIR}/SOURCES/custom.config"

# Sprawdzenie configu
if [[ -z "$CONFIG_PATH" ]]; then
    echo "Usage: $0 <path-to-kernel-config>"
    exit 1
fi
if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "Kernel config not found at $CONFIG_PATH"
    exit 1
fi

# -----------------------------
# Instalacja zależności w Tumbleweed
# -----------------------------
echo ">>> Installing build dependencies..."
zypper --non-interactive ref
zypper --non-interactive install -y \
    bc bison flex gcc make ncurses-devel perl rpm-build rpm-sign wget tar xz

# -----------------------------
# Pobranie źródeł jądra
# -----------------------------
echo ">>> Downloading kernel sources..."
cd /usr/src
if [[ ! -f "$KERNEL_TARBALL" ]]; then
    wget -O "$KERNEL_TARBALL" "https://cdn.kernel.org/pub/linux/kernel/v6.x/$KERNEL_TARBALL"
fi

# -----------------------------
# Przygotowanie drzewa RPM
# -----------------------------
echo ">>> Preparing build directories..."
rm -rf "$BUILD_OBJ_DIR"
mkdir -p "$BUILD_OBJ_DIR"
mkdir -p "$RPMBUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Kopiowanie własnego configu
echo ">>> Copying kernel config to SOURCES..."
cp "$CONFIG_PATH" "$CUSTOM_CONFIG"

# -----------------------------
# Tworzenie prostego kernel.spec
# -----------------------------
SPEC_FILE="$RPMBUILD_DIR/SPECS/custom-kernel.spec"
cat > "$SPEC_FILE" <<EOF
Name:           custom-kernel
Version:        $KERNEL_VERSION
Release:        1
Summary:        Custom Linux Kernel
License:        GPL
Source0:        $KERNEL_TARBALL
Source1:        custom.config
BuildRoot:      %{_topdir}/BUILD/%{name}-%{version}-build/BUILDROOT

%description
Custom Linux kernel built with your configuration.

%prep
%setup -q -c -T
cp %{_sourcedir}/custom.config .config
tar -xf %{_sourcedir}/$KERNEL_TARBALL
cd linux-%{version}
# przygotowanie katalogu build obj
mkdir -p $BUILD_OBJ_DIR

%build
cd linux-%{version}
make O=$BUILD_OBJ_DIR olddefconfig
make -j$(nproc) O=$BUILD_OBJ_DIR

%install
mkdir -p %{buildroot}/boot
cp -v $BUILD_OBJ_DIR/arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-%{version}-custom

%files
/boot/vmlinuz-%{version}-custom

%changelog
* $(date +"%a %b %d %Y") Custom Kernel Builder <you@example.com> - $KERNEL_VERSION-1
- Built custom kernel
EOF

# -----------------------------
# Budowanie RPM
# -----------------------------
echo ">>> Building RPM..."
rpmbuild -bb --define "_topdir $RPMBUILD_DIR" "$SPEC_FILE"

echo ">>> RPM build complete. RPMs are in $RPMBUILD_DIR/RPMS"
