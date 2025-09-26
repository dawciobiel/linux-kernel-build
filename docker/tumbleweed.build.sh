#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
"$SCRIPT_DIR/build.sh" my-kernel-builder tumbleweed.Dockerfile
