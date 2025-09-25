#!/bin/bash
set -euo pipefail

echo ">>> Running post-create setup..."

# Execute the CI kernel build script
bash /workspaces/linux-kernel-build/scripts/ci/ci-kernel-build.sh

echo ">>> Post-create setup complete."
