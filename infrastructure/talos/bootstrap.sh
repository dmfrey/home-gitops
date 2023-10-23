#!/usr/bin/env bash

echo "Applying Node Configs"
# Deploy the configuration to the nodes
talosctl apply-config --insecure -n 192.168.30.21 -f ./clusterconfig/homelab-k8s-001-dmf-rpi-001.frey.dev.yaml
talosctl apply-config --insecure -n 192.168.30.22 -f ./clusterconfig/homelab-k8s-001-dmf-rpi-002.frey.dev.yaml
talosctl apply-config --insecure -n 192.168.30.23 -f ./clusterconfig/homelab-k8s-001-dmf-rpi-003.frey.dev.yaml

# talosctl apply-config --insecure -n 192.168.30.24 -f ./clusterconfig/homelab-k8s-001-dmf-rpi-004.frey.dev.yaml
talosctl apply-config --insecure -n 192.168.30.31 -f ./clusterconfig/homelab-k8s-001-dmf-amd-001.frey.dev.yaml
talosctl apply-config --insecure -n 192.168.30.41 -f ./clusterconfig/homelab-k8s-001-dmf-nuc-001.frey.dev.yaml

echo "Sleeping..."
sleep 120

talosctl config node "192.168.30.21"; talosctl config endpoint 192.168.30.21 192.168.30.22 192.168.30.23
echo "Running bootstrap..."
talosctl bootstrap

echo "Sleeping..."
sleep 180

talosctl kubeconfig -f .
export KUBECONFIG=$(pwd)/kubeconfig

echo kubectl get nodes
kubectl get nodes
