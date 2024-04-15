#!/usr/bin/env bash

echo "Applying Node Configs"
# Deploy the configuration to the nodes
talosctl apply-config --insecure -n 192.168.30.31 -f ./clusterconfig/homelab-k8s-001-dmf-amd-001.homelab.frey.home.yaml
talosctl apply-config --insecure -n 192.168.30.32 -f ./clusterconfig/homelab-k8s-001-dmf-amd-002.homelab.frey.home.yaml
talosctl apply-config --insecure -n 192.168.30.33 -f ./clusterconfig/homelab-k8s-001-dmf-amd-003.homelab.frey.home.yaml

echo "Sleeping..."
sleep 120

talosctl config node "192.168.30.31"; talosctl config endpoint 192.168.30.31 192.168.30.32 192.168.30.33
echo "Running bootstrap..."
talosctl bootstrap

echo "Sleeping..."
sleep 180

talosctl kubeconfig -f .
export KUBECONFIG=$(pwd)/kubeconfig

echo kubectl get nodes
kubectl get nodes

./deploy-integrations.sh