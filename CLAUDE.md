# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a GitOps mono-repository for a Kubernetes homelab cluster running on 3x GEEKOM Mini IT13 nodes with Talos Linux. The cluster is managed by Flux CD, with Renovate handling automated dependency updates.

Key tools: `just`, `talosctl`, `kubectl`, `flux`, `helmfile`, `kustomize`, `kubeconform`, `flux-local`, `minijinja-cli` (for `.j2` templates), `op` (1Password CLI).

The root justfile is `justfile`, which declares three modules: `bootstrap`, `kube` (`kubernetes`), and `talos`. The internal `just template <file>` recipe renders Jinja2 templates via `minijinja-cli | op inject` (secrets injected from 1Password at render time).

The following environment variables are expected to be set when working with this repo:
- `KUBECONFIG=./kubeconfig`
- `TALOSCONFIG=./talosconfig`
- `MINIJINJA_CONFIG_FILE=./.minijinja.toml`

## Preferred Tooling (use these FIRST — they save tool calls and tokens)

### Observability queries — use Grafana MCP, not port-forwards
Never use `kubectl port-forward` + Python to query Prometheus or Loki. Use the MCP tools directly:
- **Metrics**: `mcp__grafana__query_prometheus` / `mcp__grafana__query_prometheus_histogram`
- **Logs**: `mcp__grafana__query_loki_logs` / `mcp__grafana__list_loki_label_values`
- **Dashboards**: `mcp__grafana__search_dashboards` / `mcp__grafana__get_dashboard_by_uid`
- **Alerts**: `mcp__grafana__alerting_manage_rules`

### Flux operations — use flux-operator MCP, not CLI
Prefer MCP tools over `flux` CLI for reconcile and status checks:
- `mcp__flux-operator-mcp__reconcile_flux_helmrelease` / `reconcile_flux_kustomization`
- `mcp__flux-operator-mcp__get_kubernetes_resources` for status checks
- `mcp__flux-operator-mcp__suspend_flux_reconciliation` / `resume_flux_reconciliation`

### PR reviews — use the flux-pr-reviewer subagent
For Renovate PRs, spawn the `flux-pr-reviewer` agent (defined in `.claude/agents/flux-pr-reviewer.md`). For batches, spawn in parallel — one agent per PR. Do not do inline risk assessment in the main context.

### Home Assistant — use Home Assistant MCP
For HA automations, states, services, and config: use `mcp__home-assistant__*` tools directly instead of reading config files or using kubectl exec.

### Post-merge reconcile ordering
After pushing a change, always reconcile in this order to avoid stale manifest issues:
```sh
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization <name> -n <namespace>   # applies updated HR manifest
flux reconcile helmrelease <name> -n <namespace>     # then upgrades with new values
```
Reconciling the HelmRelease before the Kustomization re-applies old values from the previous manifest.

## Tech Stack
- Kubernetes
- helm
- kustomize
- Talos Linux (https://www.talos.dev/)
- talosctl (https://docs.siderolabs.com/talos/v1.12/reference/cli)
- fluxcd (https://fluxcd.io/)
- git
- GitHub
- GitHub Actions
- Jinja2
- 1Password

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
just kube cnpg <suspend|resume>            # Suspend or resume CNPG Databases (enter or leave Maintenance Mode)
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
    └── cluster/   # Flux entrypoint (ks.yaml bootstraps cluster-apps)

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
└── resources.yaml.j2       # Bootstrap Kubernetes resources (Jinja2)
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

Always try to push changes to git to allow fluxcd to affect the state of the server. Only attempt to interact with the cluster directly to make changes if fluxcd does not resolve the changes. Accessing logs with kubectl or forcing a terraform to proceed is fine. Occasionally, you might need to reconcile a flux helmrelease or kustomization, but it shouldn't be the norm.

**Kustomization dependency chain**: `ks.yaml` declares `dependsOn` for ordering. HelmReleases use `bjw-s/app-template` charts pulled via OCIRepository. The cluster-apps Kustomization injects `deletionPolicy: WaitForTermination` and HelmRelease retry/remediation patches to all child Kustomizations.

### Secrets Management

- **Kubernetes secrets**: `ExternalSecret` resources pull from 1Password via `ClusterSecretStore: onepassword`. Data keys use `op://` vault paths in template values.
- **Talos machine configs**: Reference 1Password directly with `op://kubernetes/talos/...` syntax in `.j2` templates.
- **Bootstrap secrets**: `bootstrap/resources.yaml.j2` rendered via `minijinja-cli | op inject` at bootstrap time; no SOPS/age encryption used.
- **Cluster-wide substitution**: `postBuild.substituteFrom` in `ks.yaml` pulls from `cluster-secrets` Secret for variables like `${IPV6_IOT_PREFIX}`.

### Storage

- **Rook-Ceph**: Distributed block storage on NVMe SSDs across all 3 nodes. Most stateful apps use `existingClaim: ${VOLSYNC_CLAIM}` backed by Ceph.
- **OpenEBS**: Local storage on M.2 SATA SSDs (in Wi-Fi slot).
- **Garage**: S3-compatible object storage running in-cluster (`garage-system` namespace). Object data is stored on NFS (`nas.internal:/garage`), metadata on a Ceph PVC. Used for CNPG WAL archiving/base backups and DragonflyDB snapshots, and as **live primary storage** for Loki and Tempo (not just backup — an outage stops log/trace ingestion immediately, not just backups). Currently single-replica with no redundancy (`replication_factor=1`); a 3-node hardening plan exists as a draft PR.
- **VolSync**: PVC backup/restore via Kopia to a local repository (NFS `nas.internal:/Kopia`, browsable via the `kopia` web UI pod in `volsync-system`). Apps using VolSync include `components/volsync` in their `ks.yaml` and set `APP`, `VOLSYNC_CAPACITY`, `VOLSYNC_CACHE_CAPACITY` substitution variables. This component assumes **one PVC per app** (`existingClaim` named after the release) and hardcodes the snapshot-clone StorageClass to `ceph-block-ext4` — it doesn't fit apps with per-replica `volumeClaimTemplates` (StatefulSets with >1 replica) or PVCs on a non-ext4 StorageClass; use standalone `ReplicationSource`/`ExternalSecret` manifests instead in those cases.
- **NFS**: `nas.internal` (QNAP TS-462) for media files and backups.
- **RBD recovery caution**: if a pod is stuck because its Ceph RBD volume went read-only (ext4 `remount-ro` after a Ceph/network blip), do not immediately delete the pod to force a remount — a second RBD hiccup mid-write during that remount can corrupt the filesystem (happened to Garage's metadata DB, 2026-07-23, recovered from a Kopia snapshot). Check `ceph -s` and `ceph osd blocklist ls` first. If a node keeps throwing RBD ESHUTDOWN errors across multiple unrelated volumes, the actual fix is `talosctl -n <ip> reboot -m powercycle` on that node, not cycling individual pods.

### Networking

- **Cilium**: CNI with BGP (AS 64514 peering with UDM-SE at AS 64513). LoadBalancer IPs from `192.168.29.0/24` (VLAN 29). Requires `socketLB.hostNamespaceOnly: false` — DSR mode has a same-node hairpin bug where ClusterIP connections to a backend pod on the same node fail (EADDRNOTAVAIL/ECONNABORTED); this setting moves ClusterIP resolution to `connect()` time for all pod namespaces, bypassing the buggy path. Do not revert it. (Headless Services were never affected — they resolve directly to pod IPs with no ClusterIP/NAT step.)
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

YAML files use inline schema comments pointing to `https://kubernetes-schemas.dmfrey.com/` for IDE validation. Secrets, ReplicationSource, and ReplicationDestination kinds are skipped during validation.

### CI/CD

GitHub Actions runs `flux-local` validation on PRs touching `kubernetes/**`. Renovate monitors the entire repository for dependency updates and auto-creates PRs.

## Home Assistant
Home Assistant is setup as fluxcd HelmRelease and maintains local configuration for configuration, automations and dashboards. These 3 items are never checked into git since I have to manually update them on the home assistant server.

### Configuration
location: /kubernetes/apps/home/home-assistant/app/configuration/
          |- groups/people.yaml
          |- themes/
          |- configuration.yaml
          |- automations.yaml
          |- notify.yaml
          |- scripts.yaml

### Automations
location: /kubernetes/apps/home/home-assistant/app/configuration/automations.yaml

### Dashboards
location: /kubernetes/apps/home/home-assistant/app/dashboards/

### Details
Useful developer tools templates and results for diagnosing issues in home assistant.

location: /kubernetes/apps/home/home-assistant/app/dashboards/
          |- developer_tools_templates.yaml
