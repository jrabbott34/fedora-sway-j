#!/bin/sh
SOCK=$(ls $XDG_RUNTIME_DIR/sway-ipc.*.sock 2>/dev/null | head -1)
CUR=$(swaymsg -s "$SOCK" -t get_workspaces | jq -r '.[] | select(.focused==true) | .num')
PREV=$(( CUR <= 1 ? 5 : CUR - 1 ))
swaymsg -s "$SOCK" workspace number $PREV
