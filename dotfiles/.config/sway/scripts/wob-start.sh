#!/bin/sh
rm -f /tmp/wob.sock
mkfifo /tmp/wob.sock
tail -f /tmp/wob.sock | wob
