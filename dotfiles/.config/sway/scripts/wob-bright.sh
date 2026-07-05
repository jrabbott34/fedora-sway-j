#!/bin/sh
brightnessctl set "$1"
brightnessctl | grep -oP '\d+(?=%)' | head -1 > /tmp/wob.sock
