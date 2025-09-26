#!/bin/bash

CONTAINER_NAME=$1
DOCKER_FILE=$2

BUILD_SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
docker build -t "$1" -f "$BUILD_SCRIPT_DIR/$DOCKER_FILE" "$BUILD_SCRIPT_DIR"
