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

3.  **Create Module Dependencies**

    The RPM package does not automatically run `depmod`, a tool that creates a list of module dependencies. This list is required by `dracut` in the next step. 

    Run the command using the same kernel version string you identified earlier:

    ```bash
    sudo depmod YOUR_KERNEL_VERSION
    ```

4.  **Generate Initial Ramdisk (initrd)**

    The custom RPM does not automatically generate an `initrd` (Initial Ramdisk), which is essential for the kernel to load drivers and mount the root filesystem. You must create it manually.

    First, determine your exact kernel version string. You can find it from the name of the RPM you installed, or by looking for the new directory created in `/lib/modules/`.

    Then, run `dracut` with the following command, replacing `YOUR_KERNEL_VERSION` with the string you found:

    ```bash
    sudo dracut -f /boot/initrd-YOUR_KERNEL_VERSION.img YOUR_KERNEL_VERSION
    ```

5.  **Update Bootloader (GRUB)**

    After installing the RPM packages, you must manually update your bootloader configuration to make it aware of the new kernel. If you skip this step, the new kernel will not appear in the boot menu.

    *   **For openSUSE and Fedora (BIOS or UEFI in legacy mode):**

        ```bash
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg
        ```

    *   **For Fedora (UEFI):**

        Check for your GRUB configuration file path, as it may vary. A common path is:
        ```bash
        sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
        ```

    This command will scan for installed kernels and regenerate the GRUB menu.

6.  **Reboot your system**

    After the installation is complete, you must reboot your computer for the new kernel to be available.

    ```bash
    sudo reboot
    ```

7.  **Select the new kernel**

    During the boot process, your bootloader (GRUB) will display a menu. Select the newly installed custom kernel from the list to boot into it.
