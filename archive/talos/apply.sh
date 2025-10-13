#!/usr/bin/env bash

# Deploy the configuration to the nodes
talosctl apply-config -n 192.168.30.31 -f ./clusterconfig/homelab-k8s-001-dmf-amd-001.yaml --dry-run
talosctl apply-config -n 192.168.30.32 -f ./clusterconfig/homelab-k8s-001-dmf-amd-002.yaml --dry-run
talosctl apply-config -n 192.168.30.33 -f ./clusterconfig/homelab-k8s-001-dmf-amd-003.yaml --dry-run
talosctl apply-config -n 192.168.30.41 -f ./clusterconfig/homelab-k8s-001-dmf-intel-001.yaml
talosctl apply-config -n 192.168.30.42 -f ./clusterconfig/homelab-k8s-001-dmf-intel-002.yaml
