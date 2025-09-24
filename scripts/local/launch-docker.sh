#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <kernel-config-path>"
    exit 1
fi

KERNEL_CONFIG_PATH="$1"

# Repo root (2 poziomy wyżej niż ten plik)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

DOCKER_IMAGE="my-kernel-builder"
BUILD_SCRIPT="/workspace/scripts/local/docker-build-kernel.sh"

echo ">>> Building kernel in Docker (openSUSE Tumbleweed)..."

docker run --name kernel-builder-container -it \
    -v "$REPO_ROOT:/workspace" \
    -w /workspace \
    "$DOCKER_IMAGE" \
    bash "$BUILD_SCRIPT" "$KERNEL_CONFIG_PATH"
