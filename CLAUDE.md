# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a GitOps mono-repository for a Kubernetes homelab cluster running on 3x GEEKOM Mini IT13 nodes with Talos Linux. The cluster is managed by Flux CD, with Renovate handling automated dependency updates.

Key tools: `just`, `talosctl`, `kubectl`, `flux`, `helmfile`, `kustomize`, `kubeconform`, `flux-local`, `minijinja-cli` (for `.j2` templates), `op` (1Password CLI).

The root justfile is `.justfile` (hidden), which declares three modules: `bootstrap`, `kube` (`kubernetes`), and `talos`. The internal `just template <file>` recipe renders Jinja2 templates via `minijinja-cli | op inject` (secrets injected from 1Password at render time).

The following environment variables are expected to be set when working with this repo:
- `KUBECONFIG=./kubeconfig`
- `TALOSCONFIG=./talosconfig`
- `MINIJINJA_CONFIG_FILE=./.minijinja.toml`

## Common Commands

### Kubernetes Operations (`just kube <cmd>`)

```sh
just kube apply-ks <namespace> <ks-name>   # Apply a specific Flux Kustomization
just kube delete-ks <namespace> <ks-name>  # Delete a Flux Kustomization
just kube sync-hr                          # Force-sync all HelmReleases
just kube sync-ks                          # Force-sync all Kustomizations
just kube sync-es                          # Force-sync all ExternalSecrets
just kube sync-git                         # Force-sync all GitRepositories
just kube sync-oci                         # Force-sync all OCIRepositories
just kube snapshot                         # Trigger VolSync snapshots on all PVCs
just kube prune-pods                       # Delete Failed/Pending/Succeeded pods
just kube volsync <suspend|resume>         # Suspend or resume VolSync
just kube keda <suspend|resume>            # Suspend or resume KEDA ScaledObjects
just kube node-shell <node>               # Open a debug shell on a node
just kube browse-pvc <namespace> <claim>  # Browse a PVC
just kube view-secret <namespace> <name>  # Decode and view a secret
```

### Talos Operations (`just talos <cmd>`)

```sh
just talos apply-node <ip>                 # Apply Talos config to a node
just talos render-config <ip>              # Render Talos config (dry-run)
just talos upgrade-node <ip>               # Upgrade Talos on a node
just talos upgrade-k8s <version>           # Upgrade Kubernetes version
just talos reboot-node <ip>               # Reboot a node (with confirmation)
just talos reset-node <ip>                # Reset a node (destructive, with confirmation)
just talos shutdown-node <ip>             # Shutdown a node (with confirmation)
just talos gen-schematic-id               # Generate Talos schematic ID
just talos download-image <version> <schematic>  # Download Talos ISO
```

### Manifest Validation

```sh
bash scripts/kubeconform.sh kubernetes   # Validate all manifests with kubeconform
flux-local build ks --namespace <ns> --path kubernetes/flux/cluster <ks>  # Build a local Kustomization
```

### Bootstrap (initial cluster setup only)

```sh
just bootstrap  # Runs: talos → kube → kubeconfig → wait → namespaces → resources → crds → apps → kubeconfig
```

## Architecture

### Directory Structure

```
kubernetes/
├── apps/          # Application namespaces (one dir per namespace)
├── components/    # Reusable Kustomize components (volsync, cnpg, alerts, etc.)
└── flux/
    ├── cluster/   # Flux entrypoint (ks.yaml bootstraps repositories + cluster-apps)
    └── repositories/  # Helm/OCI repository sources

talos/
├── machineconfig.yaml.j2   # Base Talos machine config (Jinja2 template)
├── schematic.yaml.j2       # Talos image schematic template
├── nodes/                  # Per-node overrides (e.g., 192.168.30.10.yaml.j2)
└── clusterconfig/          # Rendered Talos configs (gitignored)

infrastructure/terraform/
├── security/authentik/     # Authentik SSO configuration
├── media/                  # Radarr, Sonarr, Lidarr, Readarr provisioning
└── downloads/prowlarr/     # Prowlarr provisioning

bootstrap/
├── helmfile.d/             # Bootstrap Helm releases (cilium, coredns, spegel, flux, etc.)
├── resources.yaml.j2       # Bootstrap Kubernetes resources (Jinja2)
└── 1password-resources.yaml.j2
```

### Flux Application Pattern

Every application follows this structure:

```
apps/<namespace>/
├── kustomization.yaml  # Namespace-level: lists namespace.yaml + all ks.yaml files
├── namespace.yaml
└── <app-name>/
    ├── ks.yaml         # Flux Kustomization: declares path, dependencies, postBuild substitutions
    └── app/
        ├── kustomization.yaml   # Kustomize manifest
        ├── helmrelease.yaml     # HelmRelease using OCIRepository chartRef
        ├── ocirepository.yaml   # OCI chart source (usually bjw-s app-template)
        ├── externalsecret.yaml  # ExternalSecret pulling from 1Password
        └── ...                  # pvc.yaml, configmap.yaml, etc.
```

**Kustomization dependency chain**: `ks.yaml` declares `dependsOn` for ordering. HelmReleases use `bjw-s/app-template` charts pulled via OCIRepository. The cluster-apps Kustomization injects `deletionPolicy: WaitForTermination` and HelmRelease retry/remediation patches to all child Kustomizations.

### Secrets Management

- **Kubernetes secrets**: `ExternalSecret` resources pull from 1Password via `ClusterSecretStore: onepassword`. Data keys use `op://` vault paths in template values.
- **Talos machine configs**: Reference 1Password directly with `op://kubernetes/talos/...` syntax in `.j2` templates.
- **Bootstrap secrets**: `bootstrap/resources.yaml.j2` rendered via `minijinja-cli | op inject` at bootstrap time; no SOPS/age encryption used.
- **Cluster-wide substitution**: `postBuild.substituteFrom` in `ks.yaml` pulls from `cluster-secrets` Secret for variables like `${IPV6_IOT_PREFIX}`.

### Storage

- **Rook-Ceph**: Distributed block storage on NVMe SSDs across all 3 nodes. Most stateful apps use `existingClaim: ${VOLSYNC_CLAIM}` backed by Ceph.
- **OpenEBS**: Local storage on M.2 SATA SSDs (in Wi-Fi slot).
- **VolSync**: PVC backup/restore to local Restic repository and Cloudflare R2. Apps using VolSync include `components/volsync` in their `ks.yaml` and set `VOLSYNC_CLAIM`, `VOLSYNC_CAPACITY`, `VOLSYNC_CACHE_CAPACITY` substitution variables.
- **NFS**: `nas.internal` (QNAP TS-462) for media files and backups.

### Networking

- **Cilium**: CNI with BGP (AS 64514 peering with UDM-SE at AS 64513). LoadBalancer IPs from `192.168.29.0/24` (VLAN 29).
- **Envoy Gateway**: L7 routing using `HTTPRoute`/`Route` resources. Two gateways: `envoy-external` (Cloudflare tunnel) and `envoy-internal` (UniFi DNS only).
- **ExternalDNS**: Two instances — private DNS to UniFi UDM-SE, public DNS to Cloudflare.
- **Multus**: Used for pods needing IoT VLAN (`192.168.50.0/24`) network access (e.g., Home Assistant).

### Reusable Kustomize Components

Located in `kubernetes/components/`:
- `volsync/` — VolSync ReplicationSource/Destination and PVC resources
- `cnpg/` — CloudNative PG database cluster
- `alerts/` — Prometheus alerting rules
- `common/` — Shared configurations
- `dragonflydb/` — DrangonflyDB instance
- `nfs-scaler/` — NFS volume scaler

### Talos Configuration

Machine configs are rendered from Jinja2 templates using `minijinja-cli`. The `IS_CONTROLLER` environment variable controls whether controller-plane-specific sections are rendered. Node-specific overrides (type, hostname) live in `talos/nodes/<ip>.yaml.j2`. The Talos schematic includes extensions for the Coral TPU and other hardware.

### Schema Validation

YAML files use inline schema comments pointing to `https://kubernetes-schemas.dmfrey.com/` for IDE validation. `kubeconform` uses the same schema server for CI validation. Secrets, ReplicationSource, and ReplicationDestination kinds are skipped during validation.

### CI/CD

GitHub Actions runs `flux-local` validation on PRs touching `kubernetes/**`. Renovate monitors the entire repository for dependency updates and auto-creates PRs.
