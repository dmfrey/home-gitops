#!/usr/bin/env bash

talosctl -n 192.168.30.31 reset --user-disks-to-wipe /dev/nvme0n1 --wipe-mode user-disks
talosctl -n 192.168.30.32 reset --user-disks-to-wipe /dev/nvme0n1 --wipe-mode user-disks
talosctl -n 192.168.30.33 reset --user-disks-to-wipe /dev/nvme0n1 --wipe-mode user-disks