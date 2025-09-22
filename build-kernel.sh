#!/bin/bash
set -euo pipefail

CONFIG_PATH="$1"

if [ -z "$CONFIG_PATH" ]; then
  echo "Usage: $0 <config-path>"
  exit 1
fi

KERNEL_SRC_DIR="/usr/src/linux-6.16.7-1"
BUILD_OBJ_DIR="/usr/src/linux-6.16.7-1-obj"
RPMBUILD_DIR="/usr/src/packages"

echo ">>> Installing build dependencies..."
zypper -n ref
zypper -n in bc bison flex gcc git make ncurses-devel perl \
  rpm-build wget gpg2 libopenssl-devel \
  libelf-devel dwarves

echo ">>> Preparing kernel source..."
zypper -n si kernel-source
zypper -n in kernel-source

mkdir -p "$BUILD_OBJ_DIR/x86_64/default"
cp "$CONFIG_PATH" "$BUILD_OBJ_DIR/x86_64/default/.config"

cd "$KERNEL_SRC_DIR"
make O="$BUILD_OBJ_DIR" oldconfig

echo ">>> Building kernel RPMs..."
make O="$BUILD_OBJ_DIR" -j"$(nproc)" rpm

echo ">>> Checking for RPMs in $RPMBUILD_DIR/RPMS..."
ls -lh "$RPMBUILD_DIR"/RPMS/* || true

# --- GPG signing ---
if [ -f /tmp/gpg-private.key ] && [ -f /tmp/gpg-passphrase.txt ]; then
  echo ">>> Importing GPG key..."
  gpg --batch --import /tmp/gpg-private.key
  PASSPHRASE=$(cat /tmp/gpg-passphrase.txt)
  GPG_KEY_ID=$(gpg --list-keys --with-colons | awk -F: '/^pub/{print $5; exit}')

  echo ">>> Signing RPMs with key: $GPG_KEY_ID"
  for rpm in "$RPMBUILD_DIR"/RPMS/*/*.rpm; do
    if [ -f "$rpm" ]; then
      echo "Signing $rpm"
      expect <<EOF
spawn rpmsign --addsign --define "_gpg_name $GPG_KEY_ID" "$rpm"
expect "Enter pass phrase:"
send "$PASSPHRASE\r"
expect eof
EOF
    fi
  done
else
  echo ">>> No GPG key or passphrase file found, skipping signing."
fi

echo ">>> Build complete!"
