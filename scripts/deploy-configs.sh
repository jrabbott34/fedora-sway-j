#!/usr/bin/env bash
# Symlinks dotfiles/.config/* into ~/.config. Ported from jrabbott34/sway-j's
# setup.sh. Run after scripts/setup-sway.sh (and after installing whatever
# manual/COPR/Flatpak packages you chose from README.md's porting notes).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_SRC="$REPO_DIR/dotfiles/.config"
CONFIG_DST="$HOME/.config"

deploy() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "  backing up $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  linked $dst"
}

echo "==> Deploying configs..."

for dir in sway waybar swaylock wofi wlogout swaync gtk-3.0 gtk-4.0 foot \
           alacritty fish starship kanshi yazi cava swappy waypaper \
           fastfetch wob; do
  src="$CONFIG_SRC/$dir"
  dst="$CONFIG_DST/$dir"
  [[ -d "$src" ]] && deploy "$src" "$dst"
done

deploy "$CONFIG_SRC/libinput-gestures.conf" "$CONFIG_DST/libinput-gestures.conf"

mkdir -p "$HOME/Pictures"
echo "  wallpaper folder: ~/Pictures -- drop images there, then Super+Shift+W to pick one"

echo "==> Applying GTK theme, icons, and cursor via gsettings (best-effort)..."
_gs() { gsettings set "$@" 2>/dev/null || true; }
_gs org.gnome.desktop.interface gtk-theme        'Adwaita'
_gs org.gnome.desktop.interface icon-theme       'Papirus-Dark'
_gs org.gnome.desktop.interface cursor-theme     'Bibata-Modern-Ice'
_gs org.gnome.desktop.interface cursor-size      24
_gs org.gnome.desktop.interface font-name        'FiraCode Nerd Font 11'
_gs org.gnome.desktop.interface color-scheme     'prefer-dark'
echo "  (no-ops until the GTK theme / icon theme / cursor theme / font are actually installed -- see README)"

mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" <<'EOF'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Bibata-Modern-Ice
EOF
echo "  linked ~/.icons/default -> Bibata-Modern-Ice (once that theme is installed)"

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"
deploy "$CONFIG_SRC/systemd/user/libinput-gestures.service" \
       "$SYSTEMD_USER_DIR/libinput-gestures.service"
systemctl --user enable --now libinput-gestures.service 2>/dev/null || true

PAM_GDM="/etc/pam.d/gdm-password"
if [[ -f "$PAM_GDM" ]] && ! grep -q "pam_gnome_keyring" "$PAM_GDM"; then
  echo "==> Configuring gnome-keyring PAM integration..."
  printf '\nauth       optional     pam_gnome_keyring.so\nsession    optional     pam_gnome_keyring.so auto_start\n' \
    | sudo tee -a "$PAM_GDM" > /dev/null
  echo "  Done -- keyring will auto-unlock on next GDM login."
fi

if command -v fish &>/dev/null; then
  echo ""
  read -rp "==> Set fish as default shell? [y/N] " ans
  if [[ "${ans,,}" == "y" ]]; then
    chsh -s "$(command -v fish)"
    echo "  fish set as default shell (takes effect on next login)"
  fi
fi

echo ""
echo "==> Done. Log out and select Sway from GDM, or run:"
echo "    dbus-run-session sway"
