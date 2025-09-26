#!/bin/bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
    echo "Usage: $0 [kernel-config-path]"
    exit 1
fi

KERNEL_CONFIG_PATH="${1:-kernel-config/6.16.7-1-default.custom/amd-fx8350.simplified}"

BUILD_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="/workspace/log/${BUILD_TIMESTAMP}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/build.log"

echo ">>> Build output redirected to: $LOG_FILE"

( # Start of subshell to redirect all output

echo ">>> Running kernel build inside Docker"
echo ">>> Using kernel config: $KERNEL_CONFIG_PATH"

# Usuń instalację pakietów - powinny być już zainstalowane w obrazie Docker

# Parametry
KERNEL_VERSION="6.16.7"
MAKE_JOBS="9" # Optimal jobs for make -j on AMD FX-8350 (cores + 1 heuristic)
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
Release:        1.__BUILD_TIMESTAMP__
Summary:        Custom kernel built locally
License:        GPL
Group:          System Environment/Kernel
Source0:        linux-__KERNEL_VERSION__.tar.xz
BuildRoot:      %{_topdir}/BUILD/%{name}-%{version}-build

# Define build timestamp macro for log paths (raw timestamp for directory matching)
%define _build_timestamp_raw __BUILD_TIMESTAMP__

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
echo ">>> Compiling kernel (detailed output to kernel-compile.log)..."
# Jesteśmy już w katalogu linux-__KERNEL_VERSION__
# Define kernel compile log file path
KERNEL_COMPILE_LOG_FILE="/workspace/log/%{_build_timestamp_raw}/kernel-compile.log"
mkdir -p $(dirname "$KERNEL_COMPILE_LOG_FILE")
make -j__MAKE_JOBS__ > "$KERNEL_COMPILE_LOG_FILE" 2>&1
echo ">>> Kernel compilation complete."

%install
echo ">>> Installing kernel..."
mkdir -p %{buildroot}/boot
cp -v arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-%{version}-custom

# Opcjonalnie: skopiuj też System.map i config
cp -v System.map %{buildroot}/boot/System.map-%{version}-custom
cp -v .config %{buildroot}/boot/config-%{version}-custom

MODULES_INSTALL_LOG_FILE="/workspace/log/%{_build_timestamp_raw}/modules-install.log"
mkdir -p $(dirname "$MODULES_INSTALL_LOG_FILE")
echo ">>> Installing kernel modules (detailed output to modules-install.log)..."
make -j__MAKE_JOBS__ modules_install INSTALL_MOD_PATH=%{buildroot} > "$MODULES_INSTALL_LOG_FILE" 2>&1

echo ">>> Kernel and modules installation complete."

%files
/boot/vmlinuz-%{version}-custom
/boot/System.map-%{version}-custom
/boot/config-%{version}-custom

# Define kernel release suffix for module paths
%define _kernel_release_suffix 1-default

# Kernel modules and related files
/lib/modules/%{version}-%{_kernel_release_suffix}/build
/lib/modules/%{version}-%{_kernel_release_suffix}/kernel/**
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.builtin
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.builtin.modinfo
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.builtin.ranges
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.order
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.alias
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.alias.bin
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.builtin.alias.bin
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.builtin.bin
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.dep
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.dep.bin
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.devname
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.softdep
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.symbols
/lib/modules/%{version}-%{_kernel_release_suffix}/modules.symbols.bin
EOF

# Podmiana wersji i configu
sed -i "s/__KERNEL_VERSION__/$KERNEL_VERSION/g" "$RPM_SPEC"
sed -i "s|__KERNEL_CONFIG_PATH__|$KERNEL_CONFIG_PATH|g" "$RPM_SPEC"
sed -i "s/__BUILD_TIMESTAMP__/$BUILD_TIMESTAMP/g" "$RPM_SPEC"
sed -i "s/__MAKE_JOBS__/$MAKE_JOBS/g" "$RPM_SPEC"

    # Output is already being redirected by the parent subshell's tee.

    echo ">>> Starting RPM build at $BUILD_TIMESTAMP"
    echo ">>> Full script output (including setup) redirected to: $LOG_FILE"
    echo ">>> Detailed kernel compilation output will be in: $LOG_DIR/kernel-compile.log"

    # Run rpmbuild in background
    rpmbuild -bb --noclean --define "_topdir $RPMBUILD_ROOT" "$RPM_SPEC" &
    RPMBUILD_PID=$!

    # Spinner function (outputs to current stdout, which is now tee'd to MAIN_BUILD_LOG_FILE and console)
    spinner() {
        local chars='-\|/'
        local i=0
        while kill -0 $RPMBUILD_PID 2>/dev/null; do
            i=$(( (i+1) % ${#chars} ))
            echo -ne "\r${chars:$i:1} Building RPM..."
            sleep 0.1
        done
        echo -ne "\r" # Clear spinner line
    }

    spinner

    # Wait for rpmbuild to finish and capture its exit code
    wait $RPMBUILD_PID
    RPMBUILD_EXIT_CODE=$?

    if [ $RPMBUILD_EXIT_CODE -eq 0 ]; then
        echo ">>> RPM build finished successfully."
    else
        echo ">>> ERROR: RPM build failed with exit code $RPMBUILD_EXIT_CODE."
        echo ">>> Check the main build log for details: $MAIN_BUILD_LOG_FILE"
        exit $RPMBUILD_EXIT_CODE
    fi

echo ">>> Kernel build completed. RPMs are in $RPMBUILD_ROOT/RPMS/"
find "$RPMBUILD_ROOT/RPMS/" -name "*.rpm" -exec ls -lh {} \;

echo ">>> Copying RPMs to workspace..."
mkdir -p /workspace/rpms/
cp -v "$RPMBUILD_ROOT"/RPMS/x86_64/*.rpm /workspace/rpms/
echo ">>> RPMs copied to /workspace/rpms/"

# Build kernel modules RPM
/workspace/scripts/local/local-kernel-module-rpm-build.sh "$KERNEL_VERSION" "$BUILD_TIMESTAMP"

) 2>&1 | tee "$LOG_FILE"

