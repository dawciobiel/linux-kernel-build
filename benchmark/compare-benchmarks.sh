#!/bin/bash
#
# compare-benchmarks.sh - Compare two benchmark result files
# Author: Dawid Bielecki
# Description:
#   Compares two benchmark result log files (from full-benchmark.sh)
#   and shows differences in a readable format.
#

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <benchmark-file-1> <benchmark-file-2>"
    exit 1
fi

FILE1="$1"
FILE2="$2"

if [ ! -f "$FILE1" ] || [ ! -f "$FILE2" ]; then
    echo "Error: one or both files do not exist"
    exit 1
fi

echo "============================================="
echo "Comparing benchmark results:"
echo "  File 1: $FILE1"
echo "  File 2: $FILE2"
echo "============================================="
echo

# Use diff with context to show differences
diff -y --suppress-common-lines "$FILE1" "$FILE2" || true

echo
echo "============================================="
echo "Summary:"
echo "Values that differ are shown side-by-side."
echo "Left = $FILE1"
echo "Right = $FILE2"
echo "============================================="

