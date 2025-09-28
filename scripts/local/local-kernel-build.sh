#!/bin/bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <kernel-config-path> [kernel-release-suffix]"
    exit 1
fi

KERNEL_CONFIG_PATH="$1"
CUSTOM_KERNEL_RELEASE_SUFFIX="${2:-}"

# Repo root (2 poziomy wyżej niż ten plik)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

DOCKER_IMAGE="kernel-builder"
BUILD_SCRIPT="/workspace/scripts/local/_local-kernel-build-in-docker"

echo ">>> Building kernel in Docker (openSUSE Tumbleweed base)..."

# Remove existing container if it's still around
docker rm -f kernel-builder-container >/dev/null 2>&1 || true

docker run --name kernel-builder-container \
    -v "$REPO_ROOT:/workspace" \
    -w /workspace \
    "$DOCKER_IMAGE" \
    bash "$BUILD_SCRIPT" "$KERNEL_CONFIG_PATH" "$CUSTOM_KERNEL_RELEASE_SUFFIX"
