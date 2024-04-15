#!/usr/bin/env bash

talosctl reset --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --reboot -n 192.168.30.31,192.168.30.32,192.168.30.33


talosctl reset --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --user-disks-to-wipe /dev/nvme0n1 --wipe-mode user-disks --reboot -n 192.168.30.33