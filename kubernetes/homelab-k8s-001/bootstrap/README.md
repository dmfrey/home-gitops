# Bootstrap

## Flux

### Install Flux

```sh
kubectl apply --server-side --kustomize ./kubernetes/homelab-k8s-001/bootstrap/flux
```

### Apply Cluster Configuration

_These cannot be applied with `kubectl` in the regular fashion due to be encrypted with sops_

```sh
sops --decrypt kubernetes/homelab-k8s-001/bootstrap/flux/secret-flux-gcp-kms.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/homelab-k8s-001/bootstrap/flux/secret-age-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/homelab-k8s-001/bootstrap/flux/secret-github-deploy-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/homelab-k8s-001/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
kubectl apply --server-side -f kubernetes/homelab-k8s-001/flux/vars/cluster-settings.yaml
```

### Kick off Flux applying this repository

```sh
kubectl apply --server-side --kustomize ./kubernetes/homelab-k8s-001/flux/config
```