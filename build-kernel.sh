#!/bin/bash
set -eux

# -------------------------
# Kernel RPM build script for Tumbleweed Docker
# Usage: ./build-kernel.sh <ścieżka_do_configu>
# -------------------------

CONFIG_PATH="$1"

if [ -z "$CONFIG_PATH" ]; then
    echo "Usage: $0 <config-file>"
    exit 1
fi

KERNEL_SRC_DIR=/usr/src/linux-6.16.7-1
BUILD_OBJ_DIR=/usr/src/linux-6.16.7-1-obj
RPMBUILD_DIR=/usr/src/packages

# Przygotowanie katalogów buildowych i rpmbuild
mkdir -p "$BUILD_OBJ_DIR/x86_64/default"
mkdir -p $RPMBUILD_DIR/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Kopiujemy config do katalogu buildowego
cp "$CONFIG_PATH" "$BUILD_OBJ_DIR/x86_64/default/.config"

# Instalacja pakietów potrzebnych do builda kernela w Dockerze
zypper -n in -t pattern devel_basis
zypper -n in bc bison flex gcc git make ncurses-devel perl rpm-build libelf-devel kernel-devel wget

# Pobranie oficjalnego kernel.spec z OBS
# Jeśli wget nie działa, można użyć curl
wget -O $RPMBUILD_DIR/SPECS/kernel.spec \
     https://build.opensuse.org/package/view_file/openSUSE:Factory:Kernel/linux/kernel.spec
# Alternatywnie:
# curl -L -o $RPMBUILD_DIR/SPECS/kernel.spec \
#      https://build.opensuse.org/package/view_file/openSUSE:Factory:Kernel/linux/kernel.spec

# Kopiowanie custom config do SOURCES
cp "$CONFIG_PATH" $RPMBUILD_DIR/SOURCES/.config

# Build RPM kernela
rpmbuild -bb --define "_topdir $RPMBUILD_DIR" --with baseonly $RPMBUILD_DIR/SPECS/kernel.spec

# Podpisanie RPM
echo "$GPG_PRIVATE_KEY" > /tmp/private.key
gpg --batch --import /tmp/private.key

for rpm in $RPMBUILD_DIR/RPMS/x86_64/*.rpm; do
    rpmsign --addsign --passphrase "$GPG_PASSPHRASE" "$rpm"
done

rm -f /tmp/private.key

echo "Kernel RPM build complete. RPMs available in $RPMBUILD_DIR/RPMS/x86_64/"
