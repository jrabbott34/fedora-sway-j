#!/usr/bin/env bash
# Provision a Fedora Server VM for Sway testing via QEMU/KVM (virt-install).
# Repeatable alternative to clicking through the virt-manager GUI wizard.
set -euo pipefail

VM_NAME="${VM_NAME:-fedora-sway}"
VCPUS="${VCPUS:-2}"
RAM_MB="${RAM_MB:-4096}"
DISK_GB="${DISK_GB:-25}"
DISK_POOL_DIR="${DISK_POOL_DIR:-$HOME/.local/share/libvirt/images}"
ISO_PATH="${ISO_PATH:?Set ISO_PATH to the path of the Fedora Server netinst/DVD ISO}"
ENABLE_3D="${ENABLE_3D:-0}"   # set to 1 to request virgl/venus 3D acceleration

DISK_PATH="${DISK_POOL_DIR}/${VM_NAME}.qcow2"
mkdir -p "$DISK_POOL_DIR"

VIDEO_ARGS=(--video virtio)
GRAPHICS_ARGS=(--graphics spice,gl.enable=no)
if [[ "$ENABLE_3D" == "1" ]]; then
  VIDEO_ARGS=(--video virtio,accel3d=yes)
  GRAPHICS_ARGS=(--graphics spice,gl.enable=yes,listen=none)
fi

virt-install \
  --name "$VM_NAME" \
  --vcpus "$VCPUS" \
  --memory "$RAM_MB" \
  --disk path="$DISK_PATH",size="$DISK_GB",format=qcow2 \
  --cdrom "$ISO_PATH" \
  --os-variant fedora-unknown \
  --network network=default,model=virtio \
  "${VIDEO_ARGS[@]}" \
  "${GRAPHICS_ARGS[@]}" \
  --channel spicevmc \
  --boot uefi

# Notes:
# - Re-run with ENABLE_3D=1 if your host's virt-install/qemu build supports
#   virgl/venus and you want GPU-accelerated Wayland in the guest.
# - If 3D accel misbehaves, Sway falls back to software rendering; you can
#   force it in the guest with: WLR_RENDERER=pixman sway
# - SPICE is used over VNC for better dynamic-resolution behavior with Sway.
