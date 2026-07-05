#!/bin/sh
SOCK=$(ls $XDG_RUNTIME_DIR/sway-ipc.*.sock 2>/dev/null | head -1)
CUR=$(swaymsg -s "$SOCK" -t get_workspaces | jq -r '.[] | select(.focused==true) | .num')
NEXT=$(( (CUR % 5) + 1 ))
swaymsg -s "$SOCK" workspace number $NEXT
