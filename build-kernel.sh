#!/bin/bash
set -euo pipefail

CONFIG_PATH="$1"

if [[ -z "$CONFIG_PATH" ]]; then
  echo "Usage: $0 <kernel-config-path>"
  exit 1
fi

KERNEL_VERSION="6.16.7"
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_DIR="linux-${KERNEL_VERSION}"
BUILD_DIR="/usr/src/packages/BUILD/custom-kernel-${KERNEL_VERSION}-build"
RPM_DIR="/usr/src/packages"

echo ">>> Installing build dependencies..."
zypper -n refresh
zypper -n install --capability bc bison flex gcc make ncurses-devel perl rpm-build wget tar xz

echo ">>> Downloading kernel sources..."
wget -q --show-progress -O "$KERNEL_TAR" "https://cdn.kernel.org/pub/linux/kernel/v6.x/$KERNEL_TAR"

echo ">>> Preparing build directories..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RPM_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

echo ">>> Extracting kernel sources..."
tar -xf "$KERNEL_TAR" -C "$BUILD_DIR"

echo ">>> Copying kernel config..."
cp "$CONFIG_PATH" "$BUILD_DIR/$KERNEL_DIR/.config"

echo ">>> Creating kernel.spec..."
cat > "$RPM_DIR/SPECS/kernel.spec" <<'EOF'
Name:           custom-kernel
Version:        6.16.7
Release:        1
Summary:        Custom built Linux kernel
License:        GPL-2.0
Source0:        %{_sourcedir}/linux-6.16.7.tar.xz
BuildRequires:  bc, bison, flex, gcc, make, ncurses-devel, perl
%description
Custom Linux kernel built from sources.

%prep
%setup -q -c -T
cp %{_sourcedir}/linux-6.16.7.tar.xz ./
tar -xf linux-6.16.7.tar.xz
cd linux-6.16.7
cp ../../../../workspace/kernel-config/6.16.7-1-default.custom/current .config

%build
cd linux-6.16.7
make olddefconfig
make -j$(nproc)

%install
cd linux-6.16.7
mkdir -p %{buildroot}/boot
cp -v arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-%{version}
mkdir -p %{buildroot}/usr/src/kernels/%{version}
cp -r * %{buildroot}/usr/src/kernels/%{version}

%files
/boot/vmlinuz-%{version}
/usr/src/kernels/%{version}

%changelog
* Thu Sep 22 2025 Custom Kernel Builder <you@example.com> - 6.16.7-1
- Initial build
EOF

echo ">>> Copying kernel source to SOURCES..."
cp "$KERNEL_TAR" "$RPM_DIR/SOURCES/"

echo ">>> Building RPM..."
rpmbuild -bb --define "_topdir $RPM_DIR" --with baseonly "$RPM_DIR/SPECS/kernel.spec"

echo ">>> Build finished. RPMs are in $RPM_DIR/RPMS/"
