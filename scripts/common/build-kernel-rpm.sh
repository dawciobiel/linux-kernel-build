#!/bin/bash
set -euo pipefail

# This script is the universal "engine" for building the kernel RPM.
# It is designed to be run inside a container (e.g., local Docker, CI, Codespaces).
#
# Usage: ./ci-kernel-build.sh <kernel-config-path> [kernel-release-suffix]

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <kernel-config-path> [kernel-release-suffix]"
    echo "Example: $0 kernel-config/host-config/host-config.config my-build"
    exit 1
fi

KERNEL_CONFIG_PATH="$1"
# Use provided suffix or default to 'dev' if not provided
CUSTOM_KERNEL_RELEASE_SUFFIX_BASE="${2:-dev}"

# --- Build Parameters ---
KERNEL_VERSION="6.16.8"
MAKE_JOBS="4" # Use 4 cores to prevent system instability on machines with < 32GB RAM
export MAKE_JOBS
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"
REPO_ROOT="/workspace" # Assumes the script runs in a container where the repo is mounted at /workspace
RPMBUILD_ROOT="/root/rpmbuild"
BUILD_TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
# Append timestamp to the suffix for unique build versions
CUSTOM_KERNEL_RELEASE_SUFFIX="${CUSTOM_KERNEL_RELEASE_SUFFIX_BASE}"

# --- Logging ---
LOG_DIR="$REPO_ROOT/log/${BUILD_TIMESTAMP}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/build.log"

# Redirect all output to log file and stdout
exec > >(tee -a "$LOG_FILE") 2>&1

echo ">>> Build started at: $(date)"
echo ">>> Kernel Config: $KERNEL_CONFIG_PATH"
echo ">>> Custom Suffix: $CUSTOM_KERNEL_RELEASE_SUFFIX"
echo ">>> Full build log will be available at: $LOG_FILE"

# --- Environment Setup ---
mkdir -p "$RPMBUILD_ROOT"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Ensure kernel source tarball is available
mkdir -p "$REPO_ROOT/kernel-sources"
if [[ ! -f "$REPO_ROOT/kernel-sources/$KERNEL_TAR" ]]; then
    echo ">>> Downloading kernel source..."
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TAR}" -O "$REPO_ROOT/kernel-sources/$KERNEL_TAR"
fi
ls -ld "$RPMBUILD_ROOT/SOURCES"
cp "$REPO_ROOT/kernel-sources/$KERNEL_TAR" "$RPMBUILD_ROOT/SOURCES/"

# --- Dynamic .spec File Generation ---
echo ">>> Generating dynamic .spec file..."

cd "$RPMBUILD_ROOT/BUILD"
tar -xf "$RPMBUILD_ROOT/SOURCES/$KERNEL_TAR"
cd "linux-$KERNEL_VERSION"

cp "$REPO_ROOT/$KERNEL_CONFIG_PATH" .config
make olddefconfig

FINAL_KERNEL_RELEASE=$(make -s kernelrelease LOCALVERSION=-$CUSTOM_KERNEL_RELEASE_SUFFIX)
RPM_RELEASE_STRING=$(echo "${FINAL_KERNEL_RELEASE}" | sed "s/^${KERNEL_VERSION}-//" | tr '-' '.')

echo ">>> Final kernel release string (for uname -r): $FINAL_KERNEL_RELEASE"
echo ">>> RPM Release string (for spec file): $RPM_RELEASE_STRING"

RPM_SPEC="$RPMBUILD_ROOT/SPECS/kernel.spec"

# Create the .spec file
cat > "$RPM_SPEC" <<EOF
# Global definitions
%global final_krelease ${FINAL_KERNEL_RELEASE}
%global custom_suffix ${CUSTOM_KERNEL_RELEASE_SUFFIX}
%global _build_id_links %{nil}

# --- Main Package (kernel) ---
Name:           kernel
Version:        ${KERNEL_VERSION}
Release:        ${RPM_RELEASE_STRING}
Summary:        Custom kernel for this project
License:        GPLv2
Group:          System/Kernel
Source0:        ${KERNEL_TAR}
# Using the more comprehensive list of build dependencies from the old CI script
BuildRequires:  bc, rsync, openssl, openssl-devel, elfutils, rpm-build, dwarves, \
                bison, flex, gcc, make, ncurses-devel, perl, xz, \
                libelf-devel, libuuid-devel, libblkid-devel, libselinux-devel, \
                zlib-devel, libopenssl-devel, libcap-devel, libattr-devel, \
                libseccomp-devel, gettext-runtime, python3, python314-devel, \
                fakeroot, gawk, file, kmod

%description
Custom kernel for this project (%{final_krelease}).

# --- Sub-package for modules ---
%package modules
Summary:        Kernel modules for the custom kernel
Group:          System/Kernel
Requires:       kernel = %{version}-%{release}
Provides:       kernel-modules = %{version}-%{release}

%description modules
Kernel modules for the custom kernel (%{final_krelease}).

# --- Build Process ---
%prep
%setup -q -n linux-%{version}
cp "$REPO_ROOT/$KERNEL_CONFIG_PATH" .config
make olddefconfig

%build
make -j\${MAKE_JOBS} LOCALVERSION=-%{custom_suffix}

%install
# Install kernel
mkdir -p %{buildroot}/boot
cp -v arch/x86/boot/bzImage %{buildroot}/boot/vmlinuz-%{final_krelease}
cp -v System.map %{buildroot}/boot/System.map-%{final_krelease}
cp -v .config %{buildroot}/boot/config-%{final_krelease}

# Install modules
make modules_install INSTALL_MOD_PATH=%{buildroot} LOCALVERSION=-%{custom_suffix} DEPMOD=/bin/true

# --- File Definitions ---
%files
/boot/vmlinuz-%{final_krelease}
/boot/System.map-%{final_krelease}
/boot/config-%{final_krelease}

%files modules
# Corrected path for modules
/lib/modules/%{final_krelease}/

%changelog
* $(date "+%a %b %d %Y") User - %{version}-%{release}
- Automated RPM build.
EOF

# --- Run RPM Build ---
echo ">>> Starting RPM build..."
rpmbuild -bb --define "_topdir $RPMBUILD_ROOT" "$RPM_SPEC"
RPMBUILD_EXIT_CODE=$?

if [ $RPMBUILD_EXIT_CODE -ne 0 ]; then
    echo ">>> ERROR: RPM build failed with exit code $RPMBUILD_EXIT_CODE."
    exit $RPMBUILD_EXIT_CODE
fi

# --- Finalization ---
echo ">>> RPM build finished successfully."
echo ">>> RPMs are available in $RPMBUILD_ROOT/RPMS/x86_64/"
find "$RPMBUILD_ROOT/RPMS/x86_64" -name "*.rpm" -exec ls -lh {} +

echo ">>> Copying RPMs to artifacts directory..."
mkdir -p "$REPO_ROOT/artifacts/rpms/"
cp -v "$RPMBUILD_ROOT"/RPMS/x86_64/*.rpm "$REPO_ROOT/artifacts/rpms/"

echo ">>> Build finished at: $(date)"