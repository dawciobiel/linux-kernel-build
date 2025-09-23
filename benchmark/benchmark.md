
# Launch benchmark
    ```bash
        sysbench cpu --threads=$(nproc) run | tee ./benchmark-$(uname -r).log
    ```

# Diff
    ```bash
        diff -u ./benchmark-6.16.7.log ~/benchmark-6.12.0.log | less
    ```

