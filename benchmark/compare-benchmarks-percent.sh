#!/bin/bash
#
# compare-benchmarks-percent.sh - Compare two benchmark logs with percentage differences
# Author: Dawid Bielecki
# Description:
#   Extracts numeric results from full-benchmark.sh logs and shows difference in %
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
echo "Comparing benchmark numbers:"
echo "  Left = $FILE1"
echo "  Right = $FILE2"
echo "============================================="
echo

# --- CPU (sysbench) ---
CPU1=$(grep -i "events per second" "$FILE1" | awk '{print $4}')
CPU2=$(grep -i "events per second" "$FILE2" | awk '{print $4}')
CPU_DIFF=$(awk -v a="$CPU1" -v b="$CPU2" 'BEGIN{printf "%.2f", (b-a)/a*100}')
echo "CPU (events/sec): $CPU1 | $CPU2 | Diff: $CPU_DIFF%"

# --- Memory (sysbench) ---
MEM1=$(grep -i "transferred" "$FILE1" | grep "MiB" | awk '{print $1}')
MEM2=$(grep -i "transferred" "$FILE2" | grep "MiB" | awk '{print $1}')
MEM_DIFF=$(awk -v a="$MEM1" -v b="$MEM2" 'BEGIN{printf "%.2f", (b-a)/a*100}')
echo "Memory (MiB/sec): $MEM1 | $MEM2 | Diff: $MEM_DIFF%"

# --- Compression (gzip) ---
GZIP1=$(grep "Gzip compression" "$FILE1" | awk '{print $(NF-1)}')
GZIP2=$(grep "Gzip compression" "$FILE2" | awk '{print $(NF-1)}')
GZIP_DIFF=$(awk -v a="$GZIP1" -v b="$GZIP2" 'BEGIN{printf "%.2f", (a-b)/a*100}')
echo "Gzip compression (sec, lower better): $GZIP1 | $GZIP2 | Diff: $GZIP_DIFF%"

# --- Compilation (gcc) ---
COMP1=$(grep "Compilation of linux-hello.c took" "$FILE1" | awk '{print $(NF-1)}')
COMP2=$(grep "Compilation of linux-hello.c took" "$FILE2" | awk '{print $(NF-1)}')
COMP_DIFF=$(awk -v a="$COMP1" -v b="$COMP2" 'BEGIN{printf "%.2f", (a-b)/a*100}')
echo "Compilation (sec, lower better): $COMP1 | $COMP2 | Diff: $COMP_DIFF%"

echo
echo "============================================="
echo "Interpretacja:"
echo "  Dodatnia różnica = drugi kernel jest SZYBSZY (dla czasów odwróconych)"
echo "  Ujemna różnica = drugi kernel jest WOLNIEJSZY"
echo "============================================="

