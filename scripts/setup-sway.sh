#!/usr/bin/env bash
# Post-install setup: run inside a fresh Fedora install to bring up the
# sway-j desktop stack, ported from the Arch/AUR build at jrabbott34/sway-j.
#
# Everything in DNF_PKGS below is available from Fedora's official repos.
# Everything sway-j used that Fedora does NOT package is listed in the
# "not available via dnf" section at the bottom instead of guessed at here
# -- installing those is a manual/COPR/Flatpak step, see README.md.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it uses sudo where needed)." >&2
  exit 1
fi

sudo dnf -y upgrade

DNF_PKGS=(
  # sway session (vanilla sway -- see README for the SwayFX caveat)
  sway swaylock swayidle swaybg waybar wofi
  wl-clipboard wlr-randr xdg-desktop-portal-wlr kanshi wob
  grim slurp swappy
  polkit xfce-polkit

  # terminals / shell
  alacritty foot fish starship yazi

  # file management
  thunar thunar-volman thunar-archive-plugin gvfs gvfs-afc gvfs-smb \
  samba xfce4-settings tumbler file-roller gnome-disk-utility dosfstools \
  lxappearance

  # system / shell utilities
  curl git wget \
  htop btop bat eza jq cava fastfetch cmatrix acpi sysstat \
  brightnessctl power-profiles-daemon gnome-keyring seahorse udiskie \
  wlsunset yad timeshift kernel-devel

  # network
  iw network-manager-applet NetworkManager-openvpn openvpn

  # audio / media
  pipewire pipewire-alsa pipewire-pulseaudio wireplumber pavucontrol \
  playerctl mpv yt-dlp

  # appearance (fonts/themes/cursors NOT covered here -- see README)
  qt5-qtwayland qt6ct papirus-icon-theme

  # apps
  firefox libreoffice

  # virtualization / remote
  virt-manager qemu-kvm libvirt edk2-ovmf dnsmasq iptables \
  qemu-guest-agent spice-vdagent virt-viewer remmina freerdp

  # bluetooth
  bluez blueman

  # printing / scanning
  cups cups-pdf system-config-printer ghostscript gsfonts gutenprint \
  foomatic-filters avahi nss-mdns sane-backends sane-airscan ipp-usb simple-scan

  # kernel/firmware (Fedora naming differs from Arch)
  microcode_ctl linux-firmware

  # display manager
  gdm

  # mesa / GPU (for Wayland in the VM)
  mesa-dri-drivers mesa-vulkan-drivers

  # SELinux troubleshooting -- keep this on Fedora, Arch has no equivalent
  setroubleshoot-server policycoreutils-python-utils
)

# A single bad/renamed package name makes `dnf install` fail the whole
# batch and install NOTHING -- so try the fast batch path first, and only
# fall back to installing one at a time (slower, but a bad name only
# costs that one package) if the batch install fails.
if ! sudo dnf -y install "${DNF_PKGS[@]}"; then
  echo "==> Batch install failed -- retrying package-by-package to find the bad name(s)..."
  FAILED_PKGS=()
  for pkg in "${DNF_PKGS[@]}"; do
    sudo dnf -y install "$pkg" || FAILED_PKGS+=("$pkg")
  done
  if [[ ${#FAILED_PKGS[@]} -gt 0 ]]; then
    echo "==> Could not install (check exact name for your Fedora release with: dnf search <name>):"
    printf '    %s\n' "${FAILED_PKGS[@]}"
  fi
fi

# Best-effort extras: package names sway-j used (foomatic-db-engine,
# foomatic-db) or that have shifted/renamed across Fedora releases
# (fontawesome fonts, gedit). Installed one at a time so a name that
# doesn't match your release's repos just gets skipped instead of
# aborting the whole script.
EXTRA_PKGS=(fontawesome-fonts foomatic-db-engine foomatic-db gedit)
for pkg in "${EXTRA_PKGS[@]}"; do
  sudo dnf -y install "$pkg" || echo "  (skipped: $pkg not found -- try: dnf search $pkg)"
done

sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now avahi-daemon.service
sudo systemctl enable --now cups.socket
sudo systemctl enable --now ipp-usb.service
sudo systemctl enable gdm.service

# Fedora Server defaults to multi-user.target (text-mode boot), so enabling
# a display manager alone does nothing at boot -- it only starts once the
# system reaches graphical.target. Without this, you land on a plain TTY
# login every time.
sudo systemctl set-default graphical.target

sudo usermod -aG input "$USER" || true
sudo usermod -aG libvirt "$USER"

cat <<'EOF'

==> Base package set installed. These sway-j components are NOT in
    Fedora's repos and need a manual/COPR/Flatpak install -- see
    README.md "Porting notes" before running deploy-configs.sh:

    swayfx, swaylock-effects, swaync, wlogout, cliphist, awww,
    hyprpicker, libinput-gestures, nwg-look, waypaper, swayimg,
    bibata-cursor-theme, catppuccin-gtk-theme, nerd fonts, gdm-settings,
    trezor-suite-bin

Once those are sorted, run ./scripts/deploy-configs.sh to symlink the
dotfiles, then log in and start Sway with: sway
(software fallback: WLR_RENDERER=pixman sway)
EOF
