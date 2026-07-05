#!/bin/sh
cat << 'BINDS' | wofi --dmenu --prompt "  Keybinds" --width 650 --height 720 --no-actions --insensitive
 APPLICATIONS
  Super + Return            Terminal
  Super + Space             App launcher
  Super + E                 File manager (Thunar)
  Super + Shift + Y         Yazi (TUI file manager)
  Super + Shift + A         Cava visualizer
  Super + B                 Firefox
  Super + Ctrl + L          Lock screen

 SCREENSHOTS
  Print                     Full screenshot → ~/Pictures
  Super + Print             Area → swappy annotate
  Super + Shift + Print     Area → clipboard

 UTILITIES
  Super + V                 Clipboard history
  Super + C                 Color picker
  Super + N                 Notification center
  Super + Shift + B         Toggle Waybar
  Super + Shift + E         Logout menu
  Super + Shift + W         Random wallpaper
  Super + Shift + H         This cheat sheet

 WINDOWS
  Super + Q                 Close window
  Super + F                 Fullscreen
  Super + Shift + Space     Toggle floating
  Super + A                 Focus parent
  Super + \                 Split horizontal
  Super + -                 Split vertical

 LAYOUTS
  Super + S                 Stacking
  Super + W                 Tabbed
  Super + T                 Toggle split

 FOCUS
  Super + H / J / K / L    Focus left / down / up / right
  Super + Arrow keys        Focus (arrows)

 MOVE
  Super + Shift + Arrows    Move window

 RESIZE MODE  (Super + R to enter)
  H / J / K / L            Resize
  Return or Escape          Exit resize

 WORKSPACES
  Super + 1 – 5            Switch workspace
  Super + Shift + 1 – 5   Move window to workspace

 SCRATCHPAD
  Super + Shift + ~         Send to scratchpad
  Super + ~                 Show scratchpad

 MEDIA KEYS
  XF86AudioRaiseVolume      Volume +5%
  XF86AudioLowerVolume      Volume -5%
  XF86AudioMute             Toggle mute
  XF86MonBrightnessUp       Brightness +5%
  XF86MonBrightnessDown     Brightness -5%
  XF86AudioPlay             Play / pause
  XF86AudioNext             Next track
  XF86AudioPrev             Previous track

 SWAY
  Super + Shift + R         Reload config
BINDS
