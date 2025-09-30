#!/bin/bash
set -euo pipefail
# This is the entry point for CI/Codespaces builds.
# It calls the common build engine with all provided arguments.
SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
exec "$SCRIPT_DIR/../common/build-kernel-rpm.sh" "$@"
