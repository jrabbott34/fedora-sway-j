#!/bin/sh
pactl set-sink-volume @DEFAULT_SINK@ "$1"
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -c "yes")
[ "$MUTED" -gt 0 ] && echo 0 > /tmp/wob.sock || echo "$VOL" > /tmp/wob.sock
