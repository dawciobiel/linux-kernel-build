# How to Install the Custom Kernel RPM

This guide explains how to install the custom kernel and modules packages on a compatible RPM-based Linux distribution (like openSUSE or Fedora).

## Prerequisites

- A running RPM-based Linux system (e.g., openSUSE, Fedora).
- A package manager that can install local RPM files and handle dependencies, such as `zypper` or `dnf`.
- `sudo` or `root` privileges.

## Installation Steps

**WARNING:** Installing a custom kernel is an advanced operation that can potentially leave your system in an unbootable state. Proceed with caution and ensure you have backups of any important data.

1.  **Navigate to the RPMs directory**

    The built kernel and modules packages are located in the `rpms/` directory within the project.

2.  **Install the packages**

    Use your system's package manager to install both RPM files. It is recommended to install them together in a single command to ensure all dependencies are resolved correctly.

    *   **For openSUSE (using `zypper`):**

        ```bash
        sudo zypper install rpms/*.rpm
        ```

    *   **For Fedora/CentOS (using `dnf`):**

        ```bash
        sudo dnf install rpms/*.rpm
        ```

3.  **Reboot your system**

    After the installation is complete, you must reboot your computer for the new kernel to be available.

    ```bash
    sudo reboot
    ```

4.  **Select the new kernel**

    During the boot process, your bootloader (GRUB) will display a menu. Select the newly installed custom kernel from the list to boot into it.
