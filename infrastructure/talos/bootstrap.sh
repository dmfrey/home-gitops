#!/usr/bin/env bash

echo "Applying Node Configs"
# Deploy the configuration to the nodes
talosctl apply-config --insecure -n 10.77.0.11 -f ./clusterconfig/jsdyb-k8s-001-jsdyb-nuc-001.internal.davishaus.dev.yaml
talosctl apply-config --insecure -n 10.77.0.12 -f ./clusterconfig/jsdyb-k8s-001-jsdyb-nuc-002.internal.davishaus.dev.yaml
talosctl apply-config --insecure -n 10.77.0.13 -f ./clusterconfig/jsdyb-k8s-001-jsdyb-nuc-003.internal.davishaus.dev.yaml

echo "Sleeping..."
sleep 120

talosctl config node "10.77.0.11"; talosctl config endpoint 10.77.0.11 10.77.0.12 10.77.0.10
echo "Running bootstrap..."
talosctl bootstrap

echo "Sleeping..."
sleep 180

talosctl kubeconfig -f .
export KUBECONFIG=$(pwd)/kubeconfig

echo kubectl get nodes
kubectl get nodes
