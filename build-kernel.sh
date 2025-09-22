#!/bin/bash
set -eux

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

# Pobieramy oficjalny kernel.spec z OBS
wget -O $RPMBUILD_DIR/SPECS/kernel.spec \
     https://build.opensuse.org/package/view_file/openSUSE:Factory:Kernel/linux/kernel.spec

# Opcjonalnie można zmienić w spec file BUILDOBJ_DIR, ale w większości działa tak jak jest

# Kopiujemy config do SOURCES, aby rpmbuild mógł go wykorzystać
cp "$CONFIG_PATH" $RPMBUILD_DIR/SOURCES/.config

# Instalacja paczek potrzebnych do builda kernela w Dockerze
zypper -n in -t pattern devel_basis
zypper -n in bc bison flex gcc git make ncurses-devel perl rpm-build wget libelf-devel kernel-devel

# Build RPM
rpmbuild -bb --define "_topdir $RPMBUILD_DIR" --with baseonly $RPMBUILD_DIR/SPECS/kernel.spec

# Podpisanie RPM
echo "$GPG_PRIVATE_KEY" > /tmp/private.key
gpg --batch --import /tmp/private.key

for rpm in $RPMBUILD_DIR/RPMS/x86_64/*.rpm; do
    rpmsign --addsign --passphrase "$GPG_PASSPHRASE" "$rpm"
done

rm -f /tmp/private.key

echo "Kernel RPM build complete. RPMs available in $RPMBUILD_DIR/RPMS/x86_64/"
