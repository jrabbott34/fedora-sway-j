# fedora-sway-j

Testing a Fedora + Sway build in a QEMU/KVM VM, as a possible mid-ground
between Arch/AUR (after the AUR supply-chain incident) and something more
curated. Dotfiles are ported from the existing Arch/AUR build at
[jrabbott34/sway-j](https://github.com/jrabbott34/sway-j). VM-first so that
build isn't touched.

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

Clone this repo into the guest, then run the two scripts in order:

```sh
sudo dnf -y install git
git clone <this-repo-url>
cd fedora-sway-j
./scripts/setup-sway.sh          # installs the dnf-available package set
./scripts/install-nerd-fonts.sh  # every config below references FiraCode Nerd Font
# ...install the other manual/COPR/Flatpak packages below if you want the full stack...
./scripts/deploy-configs.sh      # symlinks dotfiles/.config/* into ~/.config
```

Then log out and select Sway from GDM, or run `dbus-run-session sway`.

## Porting notes (sway-j -> Fedora)

`dotfiles/` is a straight copy of sway-j's `.config` — the configs
themselves aren't Arch-specific, so they're used unmodified.
`scripts/setup-sway.sh` reimplements sway-j's `install.sh` using `dnf`
instead of `yay`/`pacman`. Most of the stack maps over cleanly, but a
chunk of what sway-j pulled from the AUR has no Fedora repo equivalent.
These need a manual call before running `deploy-configs.sh`, or the
corresponding config just won't have anything to launch:

| Component | sway-j (AUR) | Fedora status | Suggested route |
|---|---|---|---|
| Compositor | `swayfx` | not packaged | build from source, or check COPR for your release; **or** fall back to vanilla `sway` (already installed by `setup-sway.sh`) and strip the `blur`/`corner_radius`/`shadow*`/`default_dim_inactive` lines from `dotfiles/.config/sway/config` — vanilla Sway doesn't understand SwayFX's extra directives |
| Lock screen | `swaylock-effects` | not packaged | build from source, or COPR; falls back to plain `swaylock` (already installed) with no blur effect |
| Notifications | `swaync` | not packaged | COPR (search "SwayNotificationCenter") or build from source |
| Logout menu | `wlogout` | not packaged | COPR or build from source |
| Clipboard manager | `cliphist` | not packaged | COPR, `go install`, or build from source |
| Wallpaper daemon | `awww` | not packaged | build from source: [codeberg.org/LGFae/awww](https://codeberg.org/LGFae/awww) (`dnf install cargo rust`, `cargo build --release`, install `awww`/`awww-daemon` to `~/.local/bin`). Until built, `dotfiles/.config/waypaper/config.ini` and the sway autostart/keybind default to `swaybg` instead (already installed, no fade transitions) |
| Color picker | `hyprpicker` | not packaged | COPR or build from source |
| Touchpad gestures | `libinput-gestures` | not packaged | `pip install --user libinput-gestures`, or COPR |
| GTK/theme tool | `nwg-look` | not packaged | COPR (nwg-shell tooling) |
| Wallpaper picker | `waypaper` | not packaged | `sudo dnf -y install pipx gcc python3-devel cairo-devel cairo-gobject-devel gobject-introspection-devel gtk3-devel gtk4-devel && pipx install waypaper` (the dev headers are needed to build PyGObject; plain `pipx install waypaper` fails without them) |
| Image viewer | `swayimg` | not packaged | COPR or build from source |
| Cursor theme | `bibata-cursor-theme` | not packaged | manual install from upstream GitHub releases |
| GTK theme | `catppuccin-gtk-theme-mocha` | not packaged | manual install script from the Catppuccin GTK repo. Default is currently `Adwaita` with `gtk-application-prefer-dark-theme=true` (ships with Fedora, no install needed) so Thunar/GTK apps are dark out of the box until/unless Catppuccin is installed |
| Nerd Fonts | `ttf-firacode-nerd`, `powerline-fonts` | not packaged | `./scripts/install-nerd-fonts.sh` (downloads FiraCode Nerd Font from upstream releases into `~/.local/share/fonts`) |
| MS-compatible fonts | `ttf-ms-fonts` | not packaged | RPM Fusion nonfree's `mscore-fonts-installer` |
| GDM theming GUI | `gdm-settings` | not packaged | Flatpak: `io.github.realmazharhussain.GdmSettings` |
| Trezor Suite | `trezor-suite-bin` | not packaged | Flatpak: `io.trezor.trezor-suite`, or manual download |

Everything else in sway-j's package list (Waybar, wofi, kanshi, wob,
Alacritty, foot, fish, starship, yazi, Thunar, virt-manager/libvirt, cups,
bluez, pipewire, etc.) is in Fedora's official repos and handled by
`setup-sway.sh`.

## Open items

- Decide per-item above: build from source, use COPR, use Flatpak, or drop
  the feature (e.g. run vanilla Sway without blur/shadows instead of
  chasing SwayFX).
- Once the VM build is validated, decide whether to move to bare metal.
