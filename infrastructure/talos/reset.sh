#!/usr/bin/env bash
#
# Reset the talos cluster
#   - Wipe the disks
#   - Leave etcd

talosctl -n 192.168.30.32,192.168.30.33 reset --reboot --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL

talosctl -n 192.168.30.31 reset --reboot --graceful=false --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL
