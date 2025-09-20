#!/bin/bash
# Script: gen-kernel-config.sh
# Purpose: Generate custom kernel .config for AMD FX-8350 + NVIDIA GTX 1050 Ti + SUSE Tumbleweed
# Author: Dawid Bielecki

set -e

# Go to kernel source directory
cd "linux-${KERNEL_VERSION:-$(make kernelversion 2>/dev/null || echo '')}" || cd .

# Start from defconfig (x86_64 default)
make x86_64_defconfig

# Ensure scripts/config is available
if [ ! -x scripts/config ]; then
    make scripts
fi

# -------------------------------
# CPU & Performance
# -------------------------------
scripts/config --enable CONFIG_MCORE2
scripts/config --enable CONFIG_SMP
scripts/config --enable CONFIG_X86_AMD_PLATFORM_DEVICE

# -------------------------------
# Filesystems
# -------------------------------
scripts/config --enable CONFIG_EXT4_FS
scripts/config --enable CONFIG_BTRFS_FS
scripts/config --enable CONFIG_VFAT_FS
scripts/config --enable CONFIG_NTFS3_FS   # modern NTFS driver

# -------------------------------
# Encryption (LUKS, dm-crypt)
# -------------------------------
scripts/config --enable CONFIG_DM_CRYPT
scripts/config --enable CONFIG_CRYPTO_XTS
scripts/config --enable CONFIG_CRYPTO_AES_NI_INTEL
scripts/config --enable CONFIG_BLK_DEV_DM

# -------------------------------
# USB support (2.0, 3.0)
# -------------------------------
scripts/config --enable CONFIG_USB_XHCI_HCD
scripts/config --enable CONFIG_USB_EHCI_HCD
scripts/config --enable CONFIG_USB_OHCI_HCD
scripts/config --enable CONFIG_USB_UHCI_HCD

# -------------------------------
# NVIDIA GPU (nouveau or proprietary)
# -------------------------------
scripts/config --enable CONFIG_DRM
scripts/config --enable CONFIG_DRM_NOUVEAU
scripts/config --module CONFIG_DRM_KMS_HELPER
scripts/config --module CONFIG_DRM_TTM

# If you prefer NVIDIA proprietary driver, keep nouveau as module:
# scripts/config --module CONFIG_DRM_NOUVEAU

# -------------------------------
# Sound (USB headsets, ALSA, PulseAudio/PIPEWIRE)
# -------------------------------
scripts/config --enable CONFIG_SND
scripts/config --enable CONFIG_SND_USB_AUDIO
scripts/config --enable CONFIG_SND_HDA_INTEL

# -------------------------------
# Input devices (Razer mouse, keyboards, HID)
# -------------------------------
scripts/config --enable CONFIG_HID
scripts/config --enable CONFIG_HID_GENERIC
scripts/config --enable CONFIG_HID_RAZER
scripts/config --enable CONFIG_INPUT_MOUSEDEV
scripts/config --enable CONFIG_INPUT_EVDEV

# -------------------------------
# Networking (basic + Wine/SC2)
# -------------------------------
scripts/config --enable CONFIG_NETFILTER
scripts/config --enable CONFIG_INET
scripts/config --enable CONFIG_IPV6

# -------------------------------
# Development & Debug
# -------------------------------
scripts/config --enable CONFIG_GDB_SCRIPTS
scripts/config --enable CONFIG_KALLSYMS
scripts/config --enable CONFIG_KALLSYMS_ALL

# -------------------------------
# Save final config
# -------------------------------
make olddefconfig

echo "✅ Custom .config generated successfully."
