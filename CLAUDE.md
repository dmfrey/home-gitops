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

**Removing a `components:` entry from `ks.yaml` deletes what it created, not just stops managing it.** `prune: true` treats anything that component previously applied as owned by the Kustomization — remove the reference and Flux deletes those resources on the next reconcile, including PVCs, which cascade-delete their underlying data since the default `ceph-block` StorageClass has `reclaimPolicy: Delete`. Snapshot/back up anything worth keeping first.

**StatefulSet spec changes that need object deletion, not just an upgrade**: most StatefulSet fields (`volumeClaimTemplates` in particular) are immutable after creation — Kubernetes rejects a Helm upgrade that tries to change them, and the failure can cascade into a stuck HelmRelease that keeps retrying a rollback to an already-broken previous release (deleting the `sh.helm.release.v1.<name>.*` Secrets alone won't unstick this — the HelmRelease CR keeps its own `.status.history`). Fix: delete the StatefulSet (`--cascade=orphan` to leave pods/PVCs alone) and, if the HelmRelease is still stuck, delete the HelmRelease object itself — Flux recreates both fresh from git on the next Kustomization reconcile, this time as a clean `install` instead of a `rollback`.

### Secrets Management

- **Kubernetes secrets**: `ExternalSecret` resources pull from 1Password via `ClusterSecretStore: onepassword`. Data keys use `op://` vault paths in template values.
- **Talos machine configs**: Reference 1Password directly with `op://kubernetes/talos/...` syntax in `.j2` templates.
- **Bootstrap secrets**: `bootstrap/resources.yaml.j2` rendered via `minijinja-cli | op inject` at bootstrap time; no SOPS/age encryption used.
- **Cluster-wide substitution**: `postBuild.substituteFrom` in `ks.yaml` pulls from `cluster-secrets` Secret for variables like `${IPV6_IOT_PREFIX}`.

### Storage

- **Rook-Ceph**: Distributed block storage on NVMe SSDs across all 3 nodes. Most stateful apps use `existingClaim: ${VOLSYNC_CLAIM}` backed by Ceph.
- **OpenEBS**: Local storage on M.2 SATA SSDs (in Wi-Fi slot).
- **Garage**: S3-compatible object storage running in-cluster (`garage-system` namespace). Genuine 3-node replicated cluster (`replication_factor=3`, one zone per node, migrated from single-node 2026-07-25). Metadata lives on a per-node Ceph PVC via `statefulset.volumeClaimTemplates`; object data lives on 3 **independent** NFS exports (`nas.internal:/garage`, `/garage-1`, `/garage-2`) — deliberately not one shared export split by subpath, since RF=3 replication would otherwise write 3 copies into the same underlying disk pool. Used for CNPG WAL archiving/base backups and DragonflyDB snapshots, and as **live primary storage** for Loki and Tempo (not just backup — an outage stops log/trace ingestion immediately, not just backups). When growing Garage's node count, its inherited `cluster_layout` file (in `metadata_dir`) still reflects the old `replication_factor` and Garage refuses to start until that file is moved aside — a real safety check, not a bug. **The StatefulSet requires `pod.affinity.podAntiAffinity` (`requiredDuringSchedulingIgnoredDuringExecution` on `kubernetes.io/hostname`, added 2026-07-27)** — without it, Kubernetes can freely co-locate 2+ replicas on one node, which silently defeats RF=3's fault tolerance; a single node hiccup then drops the cluster below quorum. This is exactly how a `barman-cloud` backup's catalog-list step failed with "Could not reach quorum of 2" — `garage-0` and `garage-2` had both landed on `k8s-0`. Note `requiredDuringSchedulingIgnoredDuringExecution` only affects scheduling, not already-running pods — but a Helm-triggered rolling restart (any pod template change) is enough to re-evaluate placement and fix it, no manual pod deletion needed.
  - **Single-node metadata crash recovery** (e.g. a Rust panic in `garage_table::gc` after an abrupt power-cycle of the node it's on): with RF=3 and the other 2 nodes healthy, this is safe to recover by resetting *only that node's* local metadata, not restoring from backup. Scale the StatefulSet down by one replica (`kubectl scale statefulset garage --replicas=2` removes the highest ordinal cleanly, PVCs persist), mount its `meta-*` PVC from a throwaway debug pod, move aside (don't delete) `db.lmdb` only — **preserve `node_key`/`node_key.pub`**, since wiping those would make it rejoin as an unrecognized new node instead of the same cluster member. Scale back to 3; Garage treats the empty metadata store as a normal resync-from-peers case, the same mechanism used when adding a brand new node.
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

**eGPU dock history (k8s-2)**: the original AOOSTAR AG02 (ASMedia ASM2464 bridge) had an unresolved PCIe hotplug link problem independent of GPU vendor/drivers (reproduced with both an RTX 5070 and an RTX 3090) — failure signature varied run-to-run even with identical kernel args (sometimes full PCIe enumeration then `pciehp: Timeout on hotplug command 0x1038` ~9-20s later, sometimes died earlier at Thunderbolt retimer/tunnel negotiation), pointing to hardware-level flakiness on that dock's bridge chip specifically. Replaced 2026-07-28 with a **PELADN Link S-3 (Intel Barlow Ridge JHL9480 TB5 controller)** — link has been fully stable since, zero disconnects across many tests, confirming it was the AG02's bridge chip, not the host/kernel args. `thunderbolt.host_reset=0` and `nvidia.NVreg_OpenRmEnableUnsupportedGpus=1` are currently disabled in `schematic.yaml.j2` (targeted the AG02/older driver builds specifically; not yet proven necessary with this dock) — re-enable only with a clear new hypothesis, per the file's inline history.

**Talos's NVIDIA extensions assume an always-present GPU, not a Thunderbolt-hotplugged one** — `ext-nvidia-persistenced` blocks the entire boot on `/sys/bus/pci/drivers/nvidia` existing, which only appears after a *successful* `nvidia.ko` load, and `nvidia.ko` probes for a GPU at insmod time rather than registering and waiting for one to appear later (hard-fails `ENODEV` if none present yet). The official Talos doc's `machine.kernel.modules` block (`nvidia`, `nvidia_uvm`, `nvidia_drm`, `nvidia_modeset`) is correct for a normal, natively-present GPU, but on k8s-2 it caused two distinct failure modes: an infinite ENODEV retry loop when the dock wasn't connected at boot (which alone destabilized the node after ~2 minutes, even with the GPU never involved), and a hard node hang minutes after a *successful* load whenever `nvidia_drm` was included (suspected conflict with `i915`'s active console/framebuffer ownership — reproduced twice). `machine.kernel.modules` is currently removed entirely from `talos/nodes/192.168.30.12.yaml.j2` pending a `machine.udev.rules` entry that triggers `modprobe` only on the actual PCI hotplug "add" event (`SUBSYSTEM=="pci", ATTR{vendor}=="0x10de"`) instead of any boot-time retry — not yet implemented. Note `talosctl service <name> restart` doesn't work for early-boot-critical services like `udevd`, and `install.image` changes require an actual `talosctl upgrade`/reboot (`apply-config` alone silently no-ops on that field, though it does apply `machine.kernel.modules`/other fields live). This repo doesn't use the NVIDIA GPU Operator — `kube-system/nvidia-gpu-resource-driver` deploys the NVIDIA DRA (Dynamic Resource Allocation) driver chart directly. **This assumption needs re-verification**: per the official Talos DRA doc (confirmed by a Talos maintainer, siderolabs/talos discussion #13896) and NVIDIA's own upstream pattern, the documented install is GPU Operator *plus* DRA layered on top — Operator installed with `devicePlugin.enabled=false` (DRA replaces just that one component), not DRA standalone. The Operator may provide infrastructure (NFD, etc.) the DRA plugin actually depends on, not just redundant driver/toolkit lifecycle management as previously assumed here. Don't trust `nvidia-gpu-resource-driver` as a complete substitute until its current standalone deployment is confirmed fully functional.

**`talosctl get pcidevices` is a boot-time snapshot, not live state** — it won't show a device that was hotplugged after boot (e.g. the eGPU connecting mid-session). Check `talosctl -n <ip> read /sys/bus/pci/devices/<addr>/uevent` instead for genuinely current PCI device presence.

**`just talos upgrade-node`'s `health-check` dependency needs a real TTY for its `gum confirm` prompt** — it fails outright (`could not open a new TTY`) in this non-interactive environment whenever it finds a problem (Ceph not `HEALTH_OK`, a CNPG backup, or *any* active VolSync sync cluster-wide, even on an unrelated node). Verify manually whether the flagged condition actually affects the target node (e.g. `kubectl get pods -A -o wide` to check which node a VolSync mover pod is on) before bypassing — if it's unrelated, call `talosctl -n <ip> upgrade -i "$(just talos machine-image <ip>)" -m powercycle --timeout=10m` directly instead of the `just talos upgrade-node` wrapper.

**etcd defragmentation** (`talosctl -n <ip> etcd defrag`, no `just` recipe exists for this): run one node at a time, followers before the leader (check `talosctl -n <ip1>,<ip2>,<ip3> etcd status` for the `LEADER` column first) — defragging is a blocking operation on that member and doing all 3 simultaneously risks a real quorum gap rather than just a brief leader handoff.

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
