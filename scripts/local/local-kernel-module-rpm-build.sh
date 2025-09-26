#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <kernel-version> <build-timestamp>"
    exit 1
fi

KERNEL_VERSION="$1"
BUILD_TIMESTAMP="$2"

echo ">>> Generating and building custom-kernel-modules RPM..."

RPMBUILD_ROOT="/root/rpmbuild"
mkdir -p "$RPMBUILD_ROOT"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Tworzenie pliku SPEC dla modułów
RPM_MODULES_SPEC="$RPMBUILD_ROOT/SPECS/custom-kernel-modules.spec"

cat > "$RPM_MODULES_SPEC" <<'EOF'
Name:           custom-kernel-modules
Version:        __KERNEL_VERSION__
Release:        1.__BUILD_TIMESTAMP__
Summary:        Custom kernel modules
License:        GPL
Group:          System Environment/Kernel
BuildArch:      x86_64
Requires:       custom-kernel = %{version}-%{release}

# Define kernel release suffix for module paths (must match main kernel)
%define _kernel_release_suffix 1-default

%description
Custom Linux kernel modules built locally.

%install
# Moduły są już zainstalowane w %{buildroot} przez make modules_install
# w procesie budowania głównego jądra.
# Wystarczy je skopiować do odpowiedniego miejsca w RPMBUILD_ROOT/BUILDROOT
# (które jest %{buildroot} dla tego RPM)

# Tworzymy katalog docelowy dla modułów
mkdir -p %{buildroot}/lib/modules/%{version}-%{_kernel_release_suffix}/

# Kopiujemy moduły z miejsca, gdzie zostały zainstalowane przez make modules_install
# w procesie budowania głównego jądra.
# Zakładamy, że make modules_install zainstalował je do /root/rpmbuild/BUILDROOT/custom-kernel-<version>-build/lib/modules/<version>/
# Musimy znaleźć dokładną ścieżkę do BUILDROOT głównego jądra.
# Najprościej jest skopiować z /root/rpmbuild/BUILDROOT/<nazwa_pakietu_jadra>-<wersja_jadra>-<release_jadra>/lib/modules/<wersja_jadra>/
# Ale to jest problematyczne, bo nazwa pakietu i release są dynamiczne.

# Lepszym podejściem jest założenie, że ten skrypt jest uruchamiany w tym samym środowisku
# gdzie make modules_install już umieścił moduły w /root/rpmbuild/BUILDROOT/custom-kernel-<version>-<release>/lib/modules/<version>/
# i po prostu skopiować je odtamtąd.

# Znajdź katalog BUILDROOT głównego jądra
KERNEL_BUILDROOT_DIR=$(find /root/rpmbuild/BUILDROOT/ -maxdepth 1 -type d -name "custom-kernel-*" ! -name "custom-kernel-modules-*" | head -n 1)

if [ -z "$KERNEL_BUILDROOT_DIR" ]; then
    echo "Error: Could not find kernel BUILDROOT directory."
    exit 1
fi

# Kopiujemy zawartość katalogu modułów z głównego BUILDROOT jądra
cp -a "$KERNEL_BUILDROOT_DIR"/lib/modules/%{version}-%{_kernel_release_suffix}/. %{buildroot}/lib/modules/%{version}-%{_kernel_release_suffix}/

%files
/lib/modules/%{version}-%{_kernel_release_suffix}/**

EOF

# Podmiana wersji i timestampu
sed -i "s/__KERNEL_VERSION__/$KERNEL_VERSION/g" "$RPM_MODULES_SPEC"
sed -i "s/__BUILD_TIMESTAMP__/$BUILD_TIMESTAMP/g" "$RPM_MODULES_SPEC"

echo ">>> Building custom-kernel-modules RPM..."
rpmbuild -bb --define "_topdir ${RPMBUILD_ROOT}" "${RPM_MODULES_SPEC}"

echo ">>> Custom kernel modules build completed. RPMs are in $RPMBUILD_ROOT/RPMS/"
find "$RPMBUILD_ROOT/RPMS/" -name "custom-kernel-modules-*.rpm" -exec ls -lh {} \;

echo ">>> Copying custom-kernel-modules RPMs to workspace..."
mkdir -p /workspace/rpms/
cp -v "$RPMBUILD_ROOT"/RPMS/x86_64/custom-kernel-modules-*.rpm /workspace/rpms/
echo ">>> Custom kernel modules RPMs copied to /workspace/rpms/"