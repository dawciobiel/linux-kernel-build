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

# katalog źródeł kernela
KERNEL_SRC_DIR=/usr/src/linux-6.16.7-1

# Dodawanie repozytoriów Tumbleweed jeśli brak
for repo in repo-oss repo-non-oss repo-update; do
    if ! zypper lr | grep -q "$repo"; then
        case $repo in
            repo-oss)
                zypper ar -f http://download.opensuse.org/tumbleweed/repo/oss/ $repo
                ;;
            repo-non-oss)
                zypper ar -f http://download.opensuse.org/tumbleweed/repo/non-oss/ $repo
                ;;
            repo-update)
                zypper ar -f http://download.opensuse.org/update/tumbleweed/ $repo
                ;;
        esac
    fi
done

# Odświeżanie repo
zypper ref

# Instalacja pakietów potrzebnych do builda kernela
zypper -n in -t pattern devel_basis
zypper -n in bc bison flex gcc git make ncurses-devel perl rpm-build wget libelf-devel kernel-source kernel-devel

# katalog buildowy (incremental build)
BUILD_OBJ_DIR=/usr/src/linux-6.16.7-1-obj
mkdir -p "$BUILD_OBJ_DIR/x86_64/default"
cp -u "$CONFIG_PATH" "$BUILD_OBJ_DIR/x86_64/default/.config"

# nieinteraktywny build configu
make -C "$KERNEL_SRC_DIR" O="$BUILD_OBJ_DIR" olddefconfig

# przygotowanie katalogów rpmbuild
RPMBUILD_DIR=/usr/src/packages
mkdir -p $RPMBUILD_DIR/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# kopiowanie custom config do SOURCES
cp "$CONFIG_PATH" $RPMBUILD_DIR/SOURCES/.config

# build RPM
rpmbuild -bb --define "_topdir $RPMBUILD_DIR" --with baseonly $KERNEL_SRC_DIR/kernel.spec

# podpisanie RPM
echo "$GPG_PRIVATE_KEY" > /tmp/private.key
gpg --batch --import /tmp/private.key

for rpm in $RPMBUILD_DIR/RPMS/x86_64/*.rpm; do
    rpmsign --addsign --passphrase "$GPG_PASSPHRASE" "$rpm"
done

rm -f /tmp/private.key

echo "Kernel RPM build complete for $CONFIG_PATH"
