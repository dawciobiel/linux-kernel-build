#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-}"
KERNEL_VERSION="6.16.7"
KERNEL_SRC_DIR="/usr/src/linux-${KERNEL_VERSION}"
BUILD_OBJ_DIR="/usr/src/linux-${KERNEL_VERSION}-obj"
RPMBUILD_DIR="/usr/src/packages"
ARCH="x86_64"

echo ">>> Installing build dependencies..."
zypper --non-interactive ar -f http://download.opensuse.org/tumbleweed/repo/oss/ repo-oss || true
zypper --non-interactive ar -f http://download.opensuse.org/tumbleweed/repo/non-oss/ repo-non-oss || true
zypper --non-interactive ar -f http://download.opensuse.org/update/tumbleweed/ repo-update || true
zypper --non-interactive ref

zypper --non-interactive in \
  bc bison flex gcc make ncurses-devel perl rpm-build wget

echo ">>> Downloading kernel sources..."
if [ ! -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz
fi

echo ">>> Extracting kernel sources..."
rm -rf "${KERNEL_SRC_DIR}" "${BUILD_OBJ_DIR}"
tar -xf linux-${KERNEL_VERSION}.tar.xz
mkdir -p "${BUILD_OBJ_DIR}/${ARCH}/default"

echo ">>> Copying kernel config..."
if [ ! -f "${CONFIG_PATH}" ]; then
    echo "ERROR: Kernel config not found at ${CONFIG_PATH}"
    exit 1
fi
cp "${CONFIG_PATH}" "${BUILD_OBJ_DIR}/${ARCH}/default/.config"

echo ">>> Preparing RPM build tree..."
mkdir -p ${RPMBUILD_DIR}/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

echo ">>> Creating kernel.spec"
cat > ${RPMBUILD_DIR}/SPECS/kernel.spec <<'EOF'
# Minimal kernel.spec for building custom kernel RPM
Name:           custom-kernel
Version:        6.16.7
Release:        1
Summary:        Custom Linux Kernel
License:        GPL-2.0-or-later
Group:          System/Kernel
Source0:        %{_sourcedir}/linux-6.16.7.tar.xz
BuildRoot:      %{_tmppath}/%{name}-%{version}-buildroot
BuildRequires:  bc, bison, flex, gcc, make, ncurses-devel, perl
%description
Custom Linux kernel built from source.
%prep
%setup -q -c -T
%build
make O=${BUILD_OBJ_DIR} olddefconfig
make -C ${KERNEL_SRC_DIR} O=${BUILD_OBJ_DIR} -j$(nproc)
%install
mkdir -p %{buildroot}/boot
cp ${BUILD_OBJ_DIR}/arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-custom
%files
/boot/vmlinuz-custom
EOF

echo ">>> Copying kernel source to SOURCES..."
cp linux-${KERNEL_VERSION}.tar.xz ${RPMBUILD_DIR}/SOURCES/

echo ">>> Building RPM..."
rpmbuild -bb --define "_topdir ${RPMBUILD_DIR}" --with baseonly ${RPMBUILD_DIR}/SPECS/kernel.spec

echo ">>> Kernel RPM build complete. RPMS are in ${RPMBUILD_DIR}/RPMS/${ARCH}/"
