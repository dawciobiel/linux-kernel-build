# How to Build the Kernel Locally (using Docker)

This guide explains how to build a custom kernel RPM package on your local machine using the provided Docker environment.

## 1. Prerequisites

Before you can build the kernel, you need to have Docker installed and set up. You also need to build the specific Docker image used for the build process.

Run the following script from the repository root to build the `my-kernel-builder` Docker image:

```bash
./docker/build.sh
```

## 2. Building the Kernel

The main script to launch a local build is `scripts/local/local-kernel-build.sh`. This script acts as a wrapper that executes the actual build process inside a Docker container.

### Usage

The script requires one argument and accepts a second, optional one:

```bash
./scripts/local/local-kernel-build.sh <kernel-config-path> [kernel-release-suffix]
```

*   `<kernel-config-path>`: **(Required)** The full path to the kernel configuration file you want to use.
*   `[kernel-release-suffix]`: **(Optional)** A custom suffix to append to the kernel release name. This helps in identifying your custom builds.

### Example

To build the kernel with a specific simplified configuration and add a custom suffix `my-build`, run the following command from the repository root:

```bash
./scripts/local/local-kernel-build.sh kernel-config/6.16.8-1-default.custom/amd-fx8350.simplified my-build
```

The resulting RPM packages will be located in the `rpmbuild/RPMS/` directory within the project structure.
