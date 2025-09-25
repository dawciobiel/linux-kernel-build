#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <kernel-config-path>"
    exit 1
fi

KERNEL_CONFIG_PATH="$1"

echo ">>> Running kernel build inside Docker"
echo ">>> Using kernel config: $KERNEL_CONFIG_PATH"

# Usuń instalację pakietów - powinny być już zainstalowane w obrazie Docker

# Parametry
KERNEL_VERSION="6.16.7"
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"

RPMBUILD_ROOT="/root/rpmbuild"
mkdir -p "$RPMBUILD_ROOT"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Jeśli kernel tarball nie istnieje → pobierz
if [[ ! -f "/workspace/$KERNEL_TAR" ]]; then
    echo ">>> Downloading kernel source..."
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TAR}" -O "/workspace/$KERNEL_TAR"
fi

# Kopiuj źródła do katalogu RPM
cp "/workspace/$KERNEL_TAR" "$RPMBUILD_ROOT/SOURCES/"

# Tworzenie pliku SPEC
RPM_SPEC="$RPMBUILD_ROOT/SPECS/custom-kernel.spec"

cat > "$RPM_SPEC" <<'EOF'
Name:           custom-kernel
Version:        __KERNEL_VERSION__
Release:        1
Summary:        Custom kernel built locally
License:        GPL
Group:          System Environment/Kernel
Source0:        linux-__KERNEL_VERSION__.tar.xz
BuildRoot:      %{_topdir}/BUILD/%{name}-%{version}-build

# SMP build definitions
%define _smp_build 1
%define _smp_build_n 4

%description
Custom Linux kernel built locally.

%prep
%setup -q -n linux-__KERNEL_VERSION__
cp /workspace/__KERNEL_CONFIG_PATH__ .config

# More aggressive disabling of module signing and certificates
echo "CONFIG_MODULE_SIG=n" >> .config
echo "CONFIG_MODULE_SIG_ALL=n" >> .config
echo "CONFIG_MODULE_SIG_KEY=\"\"" >> .config
echo "CONFIG_SYSTEM_TRUSTED_KEYS=\"\"" >> .config
echo "CONFIG_SYSTEM_REVOCATION_KEYS=\"\"" >> .config
echo "CONFIG_SYSTEM_BLACKLIST_KEYRING=n" >> .config
echo "CONFIG_SYSTEM_REVOCATION_LIST=n" >> .config

# Run olddefconfig to apply changes
make olddefconfig > /dev/null 2>&1 || true

# Debug: Check what's actually in the config
echo "=== Module signing config check ==="
grep -E "CONFIG_MODULE_SIG|CONFIG_SYSTEM_TRUSTED_KEYS|CONFIG_SYSTEM_REVOCATION_KEYS" .config || echo "No signing config found"
echo "=================================="

%build
echo ">>> Compiling kernel (silent mode)..."
# Jesteśmy już w katalogu linux-__KERNEL_VERSION__
make -j$(nproc) 2>&1 | grep -vE "AR|AS|BTF|CC|CERT|CHKSHA1|COPY|DESCEND|GEN|HOSTCC|HOSTLD|HYPERCALLS|INSTALL|MKELF|OBJCOPY|POLICY|UPD|VDSO2C|WRAP"
echo ">>> Kernel compilation complete."

%install
echo ">>> Installing kernel..."
mkdir -p %{buildroot}/boot
cp -v arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-%{version}-custom

# Opcjonalnie: skopiuj też System.map i config
cp -v System.map %{buildroot}/boot/System.map-%{version}-custom
cp -v .config %{buildroot}/boot/config-%{version}-custom
echo ">>> Kernel installation complete."

%files
/boot/vmlinuz-%{version}-custom
/boot/System.map-%{version}-custom
/boot/config-%{version}-custom
EOF

# Podmiana wersji i configu
sed -i "s/__KERNEL_VERSION__/$KERNEL_VERSION/g" "$RPM_SPEC"
sed -i "s|__KERNEL_CONFIG_PATH__|$KERNEL_CONFIG_PATH|g" "$RPM_SPEC"

echo ">>> Building RPM..."
rpmbuild -bb --define "_topdir $RPMBUILD_ROOT" "$RPM_SPEC"

echo ">>> Kernel build completed. RPMs are in $RPMBUILD_ROOT/RPMS/"
find "$RPMBUILD_ROOT/RPMS/" -name "*.rpm" -exec ls -lh {} \;

echo ">>> Copying RPMs to workspace..."
mkdir -p /workspace/rpms/
cp -v "$RPMBUILD_ROOT"/RPMS/x86_64/*.rpm /workspace/rpms/
echo ">>> RPMs copied to /workspace/rpms/"

