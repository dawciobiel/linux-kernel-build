#!/bin/bash
#
# full-benchmark.sh - Full system benchmark (CPU, RAM, Disk, Compression, Compilation)
# Author: Dawid Bielecki
# Description:
#   Runs a set of benchmarks to compare performance between kernels.
#   Results are stored in a timestamped log file for later comparison.
#

set -euo pipefail

# Create results directory
RESULTS_DIR="$HOME/bench-results"
mkdir -p "$RESULTS_DIR"

# Output file
LOG_FILE="$RESULTS_DIR/benchmark-$(uname -r)-$(date +%F_%H-%M-%S).log"

echo "========================================" | tee "$LOG_FILE"
echo "Benchmark started on kernel: $(uname -r)" | tee -a "$LOG_FILE"
echo "Date: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

############################################
# CPU test (sysbench)
############################################
echo -e "\n[CPU TEST]" | tee -a "$LOG_FILE"
sysbench cpu --threads="$(nproc)" run | tee -a "$LOG_FILE"

############################################
# Memory test (sysbench memory)
############################################
echo -e "\n[MEMORY TEST]" | tee -a "$LOG_FILE"
sysbench memory --memory-total-size=4G run | tee -a "$LOG_FILE"

############################################
# Disk test (fio)
############################################
echo -e "\n[DISK TEST]" | tee -a "$LOG_FILE"
DISK_FILE="$RESULTS_DIR/testfile"
fio --name=randrw --rw=randrw --size=512M --bs=4k --numjobs=2 --runtime=60 --group_reporting --filename="$DISK_FILE" | tee -a "$LOG_FILE"
rm -f "$DISK_FILE"

############################################
# Compression test (gzip)
############################################
echo -e "\n[COMPRESSION TEST]" | tee -a "$LOG_FILE"
dd if=/dev/zero of="$RESULTS_DIR/compression-test.dat" bs=1M count=1024 status=none
TIME_START=$(date +%s)
gzip -c "$RESULTS_DIR/compression-test.dat" > "$RESULTS_DIR/compression-test.gz"
TIME_END=$(date +%s)
ELAPSED=$((TIME_END - TIME_START))
echo "Gzip compression of 1GB file took: ${ELAPSED} seconds" | tee -a "$LOG_FILE"
rm -f "$RESULTS_DIR/compression-test.dat" "$RESULTS_DIR/compression-test.gz"

############################################
# Compilation test
############################################
echo -e "\n[COMPILATION TEST]" | tee -a "$LOG_FILE"
cat > "$RESULTS_DIR/linux-hello.c" <<'EOF'
#include <stdio.h>
int main() {
    for (long i = 0; i < 100000000; i++);
    printf("Hello Kernel Benchmark!\n");
    return 0;
}
EOF

TIME_START=$(date +%s)
gcc "$RESULTS_DIR/linux-hello.c" -o "$RESULTS_DIR/linux-hello"
TIME_END=$(date +%s)
ELAPSED=$((TIME_END - TIME_START))
echo "Compilation of linux-hello.c took: ${ELAPSED} seconds" | tee -a "$LOG_FILE"
"$RESULTS_DIR/linux-hello" >> "$LOG_FILE"

############################################
# Done
############################################
echo -e "\nBenchmark finished. Results saved to: $LOG_FILE"

