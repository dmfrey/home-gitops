#!/usr/bin/env bash

# Deploy the configuration to the nodes
# talosctl apply-config -n 192.168.30.5 -f ./clusterconfig/homelab-k8s-001-dmf-amd-001.frey.dev.yaml
# talosctl apply-config -n 192.168.30.6 -f ./clusterconfig/homelab-k8s-001-dmf-nuc-001.frey.dev.yaml
talosctl apply-config -n 192.168.30.21 -f ./clusterconfig/homelab-k8s-001-dmf-rpi-001.frey.dev.yaml
talosctl apply-config -n 192.168.30.22 -f ./clusterconfig/homelab-k8s-001-dmf-rpi-002.frey.dev.yaml
talosctl apply-config -n 192.168.30.23 -f ./clusterconfig/homelab-k8s-001-dmf-rpi-003.frey.dev.yaml
# talosctl apply-config -n 192.168.30.13 -f ./clusterconfig/homelab-k8s-001-dmf-rpi-004.frey.dev.yaml
