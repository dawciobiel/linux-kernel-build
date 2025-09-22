#!/bin/bash
set -euo pipefail

CONFIG_PATH="$1"

if [[ -z "$CONFIG_PATH" ]]; then
    echo "Usage: $0 <path-to-kernel-config>"
    exit 1
fi

KERNEL_VERSION="6.16.7"
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_SRC_DIR="/usr/src/linux-${KERNEL_VERSION}"
BUILD_OBJ_DIR="/usr/src/linux-${KERNEL_VERSION}-obj"
RPM_DIR="/usr/src/packages"

echo ">>> Installing build dependencies..."
zypper -n ref
zypper -n in -t pattern devel_C_C++
zypper -n in bc bison flex gcc make ncurses-devel perl rpm-build wget xz tar

echo ">>> Downloading kernel sources..."
cd /usr/src
if [[ ! -f "$KERNEL_TAR" ]]; then
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/$KERNEL_TAR"
fi

echo ">>> Extracting kernel sources..."
tar -xf "$KERNEL_TAR"

echo ">>> Preparing build directories..."
mkdir -p "$BUILD_OBJ_DIR/x86_64/default"

echo ">>> Preparing RPM build tree..."
mkdir -p "$RPM_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

echo ">>> Copying kernel config to SOURCES..."
cp "$CONFIG_PATH" "$RPM_DIR/SOURCES/custom.config"

echo ">>> Creating kernel.spec..."
cat > "$RPM_DIR/SPECS/kernel.spec" <<'EOF'
Name: custom-kernel
Version: 6.16.7
Release: 1
Summary: Custom Linux Kernel
License: GPL-2.0
Source0: %{_sourcedir}/linux-6.16.7.tar.xz
Source1: %{_sourcedir}/custom.config
BuildRequires: bc, bison, flex, gcc, make, ncurses-devel, perl
%description
Custom-built Linux kernel.

%prep
%setup -q -c -T
cp %{_sourcedir}/custom.config .config
tar -xf %{_sourcedir}/linux-6.16.7.tar.xz
cd linux-6.16.7

%build
make O=$RPM_DIR/BUILD olddefconfig
make O=$RPM_DIR/BUILD -j$(nproc)

%install
mkdir -p %{buildroot}/boot
cp -v $RPM_DIR/BUILD/arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-%{version}

%files
/boot/vmlinuz-%{version}

%changelog
* Thu Sep 22 2025 Custom Kernel Builder <you@example.com> - 6.16.7-1
- Initial build
EOF

echo ">>> Copying kernel tarball to SOURCES..."
cp "$KERNEL_TAR" "$RPM_DIR/SOURCES/"

echo ">>> Building RPM..."
rpmbuild -bb --define "_topdir $RPM_DIR" --with baseonly "$RPM_DIR/SPECS/kernel.spec"

echo ">>> Build complete. RPMs are in $RPM_DIR/RPMS/"
