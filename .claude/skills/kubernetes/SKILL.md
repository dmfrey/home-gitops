---
name: kubernetes
description: Kubernetes operations for the homelab cluster. Use when the user asks to check pod status, view logs, troubleshoot apps, inspect resources, manage HelmReleases/Kustomizations, or perform any kubectl/flux operations against the cluster.
argument-hint: [namespace] [resource] [command]
---

You are assisting with a Kubernetes homelab cluster (Talos Linux, Flux CD, 3-node GEEKOM Mini IT13). The cluster uses GitOps via this repository.

## Environment

- `KUBECONFIG=./kubeconfig` must be set (already configured in this repo's environment)
- Apps live under `kubernetes/apps/<namespace>/`
- Use `just kube <cmd>` for common operations (see CLAUDE.md for full list)

## Common Operations

### Check resource status
```bash
kubectl -n <namespace> get pods
kubectl -n <namespace> get helmrelease
kubectl -n <namespace> get kustomization -A
```

### View logs
```bash
kubectl -n <namespace> logs <pod> --since=10m
kubectl -n <namespace> logs <pod> -f   # follow
```

### Force-sync Flux resources
```bash
just kube sync-hr    # all HelmReleases
just kube sync-ks    # all Kustomizations
just kube sync-oci   # all OCIRepositories
just kube sync-es    # all ExternalSecrets
```

### Apply a specific Kustomization
```bash
just kube apply-ks <namespace> <ks-name>
```

### Decode and view a secret
```bash
just kube view-secret <namespace> <name>
```

### Fix stale HelmRelease state
If a HelmRelease fails with "unable to build kubernetes objects from current release manifest":
```bash
kubectl -n <ns> delete secret -l name=<release-name>,owner=helm
kubectl -n <ns> annotate helmrelease <name> reconcile.fluxcd.io/forceAt="$(date +%s)" --overwrite
```

### CNPG database clusters
```bash
just kube cnpg suspend    # pause all clusters for node drain
just kube cnpg resume     # resume all clusters
```

### VolSync PVC management
```bash
just kube snapshot             # trigger snapshots on all PVCs
just kube volsync suspend      # pause VolSync
just kube volsync resume       # resume VolSync
just kube browse-pvc <namespace> <claim>   # browse PVC contents
```

## Namespaces

Key namespaces: `flux-system`, `network`, `kube-system`, `self-hosted`, `home`, `media`, `downloads`, `database`, `monitoring`, `security`

## Troubleshooting Approach

1. Check pod status and events: `kubectl -n <ns> describe pod <pod>`
2. Check HelmRelease status: `kubectl -n <ns> describe helmrelease <name>`
3. Check Kustomization status: `kubectl -n flux-system get ks -A`
4. Check ExternalSecret sync: `kubectl -n <ns> get externalsecret`
5. Pull logs from the failing pod
6. If Flux resource is stuck, force-sync with `just kube sync-hr` or `just kube apply-ks`

When diagnosing issues, pull logs and resource descriptions in parallel to be efficient.
