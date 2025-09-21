#!/bin/bash
set -eux

# -------------------------
# Incremental kernel build script
# -------------------------
# Użycie: ./build-kernel.sh <ścieżka_do_configu>
# -------------------------

CONFIG_PATH="$1"

if [ -z "$CONFIG_PATH" ]; then
    echo "Usage: $0 <config-file>"
    exit 1
fi

# Katalog buildowy kernela
KERNEL_OBJ_DIR=/usr/src/linux-6.16.7-1-obj

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

# Odświeżanie repozytoriów
zypper ref

# Instalacja pakietów do builda kernela
zypper -n in -t pattern devel_basis
zypper -n in bc bison flex gcc git make ncurses-devel perl rpm-build wget libelf-devel

# Kopiowanie customowego .config
mkdir -p "$KERNEL_OBJ_DIR/x86_64/default"
cp -u "$CONFIG_PATH" "$KERNEL_OBJ_DIR/x86_64/default/.config"

# Incremental build RPM
cd "$KERNEL_OBJ_DIR"
yes "" | make oldconfig || true
make -j$(nproc) rpm

# Podpisywanie RPM
echo "$GPG_PRIVATE_KEY" > /tmp/private.key
gpg --batch --import /tmp/private.key

for rpm in x86_64/RPMS/*.rpm; do
    rpmsign --addsign --passphrase "$GPG_PASSPHRASE" "$rpm"
done

rm -f /tmp/private.key

echo "Incremental Kernel RPMs build complete for $CONFIG_PATH"
