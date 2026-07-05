# fedora-sway-j

Testing a Fedora + Sway build in a QEMU/KVM VM, as a possible mid-ground
between the existing Debian/Sway build and Arch/AUR (after the AUR
supply-chain incident). VM-first so the current Debian/Sway setup isn't
touched.

## Why Fedora

- **Package management**: `dnf` + repos, smaller and more curated than the
  AUR. Niche tools (specific Waybar modules, Eww themes, obscure status bar
  plugins) may need COPR, Flatpak, or building from source instead of a
  one-line AUR install.
- **SELinux**: enforcing by default. Sway/Waybar/etc. generally run fine;
  unexplained permission-denied errors are usually SELinux, not a real bug.
  `setup-sway.sh` installs `setroubleshoot-server` and
  `policycoreutils-python-utils` so `audit2allow` is available.
- **Wayland**: Fedora has been Wayland-first for years, so Sway support is
  current — arguably more so than Debian stable's older portal/session
  stack. Xorg/X11 (e.g. DWM) is still fully supported if that's ever wanted
  instead.
- **Release cadence**: ~6-month cycle, tracks upstream much closer than
  Debian stable, so newer Sway/Wayland/Mesa without needing backports or
  building from source.

## VM setup

Using local QEMU/KVM via `virt-manager`/`virt-install` (not Proxmox, this is
laptop-local).

- Fedora **Server** netinst ISO — minimal base, add Sway manually rather
  than stripping a DE back out.
- Sizing: 2 vCPUs, 4GB RAM, 25GB disk.
- Display: **virtio** video model, not QXL — QXL is X11-oriented and rougher
  under Wayland.
- 3D acceleration (virgl/venus) is optional and depends on the host's
  qemu build supporting it. If it's not available or misbehaves, Sway
  falls back to software rendering (`WLR_RENDERER=pixman`) — slower, fine
  for a test VM.
- SPICE over VNC for the display — better dynamic resolution/resize
  behavior for a Sway session.

### Provisioning the VM

```sh
ISO_PATH=/path/to/Fedora-Server-netinst.iso ./scripts/create-vm.sh
```

Optional env vars: `VM_NAME`, `VCPUS`, `RAM_MB`, `DISK_GB`, `DISK_POOL_DIR`,
`ENABLE_3D=1` (to request virgl/venus 3D acceleration).

### Setting up Sway after Fedora is installed

Copy `scripts/setup-sway.sh` into the guest (or clone this repo there) and
run it as your normal user:

```sh
./scripts/setup-sway.sh
```

Installs Sway, Waybar, a terminal (foot), a launcher (wofi), Wayland
portals, audio (pipewire), screenshot/clipboard tools, and SELinux
troubleshooting tools. Then log in and run `sway`.

## Open items

- Decide whether to port over Waybar config/dotfiles from the Debian build,
  or start fresh.
- If any AUR-sourced tool has no Fedora/COPR/Flatpak equivalent, note it
  here and decide: build from source, skip, or find an alternative.
- Once the VM build is validated, decide whether to move to bare metal.
