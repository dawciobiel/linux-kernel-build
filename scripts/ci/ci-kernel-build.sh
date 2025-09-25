#!/bin/bash
set -euo pipefail

# Usage: ./build-kernel.sh
# Builds an RPM of Linux kernel 6.16.7 on openSUSE Tumbleweed

KERNEL_VERSION="6.16.7"
KERNEL_TARBALL="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_SRC_DIR="/usr/src/linux-${KERNEL_VERSION}"
RPMBUILD_DIR="/usr/src/packages"
CUSTOM_CONFIG="${RPMBUILD_DIR}/SOURCES/custom.config"



echo ">>> Downloading kernel sources..."
cd /usr/src
if [ ! -f "$KERNEL_TARBALL" ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TARBALL}
fi

echo ">>> Preparing build directories..."
rm -rf "$KERNEL_SRC_DIR"
tar -xf "$KERNEL_TARBALL"


mkdir -p "$RPMBUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

echo ">>> Copying custom kernel config to SOURCES..."
cp "${PWD}/kernel-config/6.16.7-1-default.custom/current" "$CUSTOM_CONFIG"

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
echo ">>> Configuring kernel (olddefconfig)..."
make -C linux-${KERNEL_VERSION} O=$(pwd) olddefconfig
echo ">>> Compiling kernel..."
make -C linux-${KERNEL_VERSION} O=$(pwd) -j$(nproc) 2>&1 | grep -vE "INSTALL|HOSTCC|HOSTLD|WRAP|UPD|CC|AS|AR|CERT|CHKSHA1|LD|LDS|OBJCOPY|VDSO2C|HYPERCALLS|GEN|COPY|MKELF|DESCEND|POLICY"
echo ">>> Kernel compilation complete."

%install
rm -rf %{buildroot}
echo ">>> Installing kernel modules..."
make -C linux-${KERNEL_VERSION} O=$(pwd) INSTALL_MOD_PATH=%{buildroot} modules_install
echo ">>> Installing kernel..."
make -C linux-${KERNEL_VERSION} O=$(pwd) INSTALL_PATH=%{buildroot}/boot install
echo ">>> Kernel installation complete."

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
