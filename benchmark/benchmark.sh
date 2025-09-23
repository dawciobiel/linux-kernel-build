#!/bin/bash
#
# benchmark.sh - simple benchmark runner for kernel comparison
#
# Runs a set of tests (CPU, memory, disk I/O, stress-ng, perf)
# and saves results into ~/benchmark-<kernel-version>.log
#
# Requirements:
#   zypper install sysbench stress-ng perf
#

set -e

KERNEL_VERSION=$(uname -r)
OUTFILE="./benchmark-$KERNEL_VERSION.log"

echo "Running benchmarks for kernel: $KERNEL_VERSION"
echo "Results will be saved in: $OUTFILE"
echo "============================================="

{
  echo "### Benchmark results for kernel $KERNEL_VERSION"
  echo "### Date: $(date)"
  echo "============================================="
  echo

  echo ">>> CPU test (sysbench)"
  sysbench cpu --threads=$(nproc) run
  echo

  echo ">>> Memory test (sysbench)"
  sysbench memory --memory-total-size=4G run
  echo

  echo ">>> Disk I/O test (sysbench)"
  sysbench fileio --file-total-size=2G --file-test-mode=rndrw prepare
  sysbench fileio --file-total-size=2G --file-test-mode=rndrw run
  sysbench fileio --file-total-size=2G --file-test-mode=rndrw cleanup
  echo

  echo ">>> Stress test (stress-ng, 60s)"
  stress-ng --cpu 4 --io 2 --vm 2 --vm-bytes 1G --timeout 60s --metrics-brief
  echo

  echo ">>> perf stat (10s system activity)"
  perf stat -a sleep 10
  echo

} | tee "$OUTFILE"

echo "============================================="
echo "Benchmark finished. Results saved in: $OUTFILE"

