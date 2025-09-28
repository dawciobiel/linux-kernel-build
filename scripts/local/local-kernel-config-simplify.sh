#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <input-config-path> <output-config-path>"
    echo "Example: $0 kernel-config/6.16.8-1-default/amd-fx8350.default kernel-config/6.16.8-1-default/custom.config"
    exit 1
fi

INPUT_CONFIG="$1"
OUTPUT_CONFIG="$2"
KERNEL_VERSION="6.16.8"
KERNEL_DIR="linux-${KERNEL_VERSION}"
KERNEL_TAR="${KERNEL_DIR}.tar.xz"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Sprawdź, czy jesteśmy w głównym katalogu repozytorium
cd "$REPO_ROOT"

# 1. Pobierz źródła jądra, jeśli nie istnieją
if [[ ! -f "$KERNEL_TAR" ]]; then
    echo ">>> Downloading kernel source (${KERNEL_TAR})..."
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TAR}" -O "$KERNEL_TAR"
fi

# 2. Rozpakuj źródła jądra
if [[ -d "$KERNEL_DIR" ]]; then
    echo ">>> Removing existing kernel directory..."
    rm -rf "$KERNEL_DIR"
fi
echo ">>> Unpacking kernel source..."
tar -xf "$KERNEL_TAR"

# 3. Uprość konfigurację
cd "$KERNEL_DIR"
echo ">>> Creating simplified config from ${INPUT_CONFIG}"

# Sprawdzenie, czy plik konfiguracyjny istnieje
if [[ ! -f "$REPO_ROOT/$INPUT_CONFIG" ]]; then
    echo "Error: Input config file not found at ${REPO_ROOT}/${INPUT_CONFIG}"
    exit 1
fi

cp "$REPO_ROOT/$INPUT_CONFIG" .config

# Uruchomienie localmodconfig
# To polecenie użyje `lsmod` do wykrycia używanych modułów
echo ">>> Running 'make localmodconfig'"
make localmodconfig

# 4. Zapisz nową konfigurację
echo ">>> Saving new config to ${OUTPUT_CONFIG}"
cp .config "$REPO_ROOT/$OUTPUT_CONFIG"

# 5. Sprzątanie
cd "$REPO_ROOT"
rm -rf "$KERNEL_DIR"

echo ">>> Done. Simplified config saved to: $OUTPUT_CONFIG"