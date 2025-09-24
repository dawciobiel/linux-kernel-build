#!/bin/bash
set -euo pipefail

# Check for kernel config argument
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <kernel-config-path>"
    echo "Example: $0 kernel-config/6.16.7-1-default.custom/current"
    exit 1
fi
KERNEL_CONFIG_PATH="$1"

DOCKER_IMAGE="my-kernel-builder"
# Assuming 'docker/build.sh' is the correct script to build the main image
BUILDER_IMAGE_SCRIPT="./docker/build.sh"
LAUNCH_SCRIPT="./scripts/local/launch-docker.sh"

echo ">>> Starting kernel build process..."
echo "----------------------------------------"

# 1. Build the Docker builder image if it doesn't exist
if [[ "$(docker images -q ${DOCKER_IMAGE} 2> /dev/null)" == "" ]]; then
    echo ">>> Builder image '${DOCKER_IMAGE}' not found. Building it now..."
    if [ -f "$BUILDER_IMAGE_SCRIPT" ]; then
        bash "$BUILDER_IMAGE_SCRIPT"
    else
        echo "Error: Builder script '$BUILDER_IMAGE_SCRIPT' not found."
        exit 1
    fi
    echo ">>> Builder image built successfully."
else
    echo ">>> Builder image '${DOCKER_IMAGE}' already exists. Skipping build."
fi

echo "----------------------------------------"
# 2. Run the kernel build process inside the container
echo ">>> Launching kernel build using config: ${KERNEL_CONFIG_PATH}"
bash "$LAUNCH_SCRIPT" "$KERNEL_CONFIG_PATH"

echo "----------------------------------------"
echo ">>> Build process finished."
echo ">>> RPMs should be available in the 'rpms/' directory."
