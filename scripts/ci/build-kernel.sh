#!/bin/bash
set -euo pipefail

# Usage: ./build-kernel.sh
# Builds an RPM of Linux kernel 6.16.7 on openSUSE Tumbleweed

KERNEL_VERSION="6.16.7"
KERNEL_TARBALL="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_SRC_DIR="/usr/src/linux-${KERNEL_VERSION}"
RPMBUILD_DIR="/usr/src/packages"
CUSTOM_CONFIG="${RPMBUILD_DIR}/SOURCES/custom.config"

echo ">>> Installing build dependencies..."
zypper --non-interactive ref
zypper --non-interactive install \
    bc bison flex gcc make ncurses-devel perl rpm-build tar xz wget

echo ">>> Downloading kernel sources..."
cd /usr/src
if [ ! -f "$KERNEL_TARBALL" ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TARBALL}
fi

echo ">>> Preparing build directories..."
rm -rf "$KERNEL_SRC_DIR"
tar -xf "$KERNEL_TARBALL"
mv "linux-${KERNEL_VERSION}" "$KERNEL_SRC_DIR"

mkdir -p "$RPMBUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

echo ">>> Copying kernel config to SOURCES..."
# Use default x86_64_defconfig to avoid missing file
cp "$KERNEL_SRC_DIR"/arch/x86/configs/x86_64_defconfig "$CUSTOM_CONFIG"

echo ">>> Creating kernel.spec..."
cat > "$RPMBUILD_DIR/SPECS/kernel.spec" <<EOF
Name: custom-kernel
Version: $KERNEL_VERSION
Release: 1
Summary: Custom Linux kernel $KERNEL_VERSION
License: GPL-2.0
Group: System Environment/Kernel
Source0: $KERNEL_TARBALL
BuildRoot: %{_tmppath}/%{name}-%{version}-build
%description
Custom Linux kernel built via GitHub Actions.

%prep
%setup -q -c -T
cp %{_sourcedir}/custom.config .config
tar -xf %{_sourcedir}/${KERNEL_TARBALL}

%build
make -C linux-${KERNEL_VERSION} O=$(pwd) olddefconfig
make -C linux-${KERNEL_VERSION} O=$(pwd) -j$(nproc)

%install
rm -rf %{buildroot}
make -C linux-${KERNEL_VERSION} O=$(pwd) INSTALL_MOD_PATH=%{buildroot} modules_install
make -C linux-${KERNEL_VERSION} O=$(pwd) INSTALL_PATH=%{buildroot}/boot install

%files
/boot/*
/lib/modules/*

%changelog
* $(date +"%a %b %d %Y") Custom Kernel Builder <you@example.com> - $KERNEL_VERSION-1
- Built via GitHub Actions
EOF

echo ">>> Copying kernel tarball to SOURCES..."
cp "$KERNEL_TARBALL" "$RPMBUILD_DIR/SOURCES/"

echo ">>> Building RPM..."
rpmbuild -bb --define "_topdir $RPMBUILD_DIR" --with baseonly "$RPMBUILD_DIR/SPECS/kernel.spec"

echo ">>> Done. RPMs are in $RPMBUILD_DIR/RPMS/x86_64/"
