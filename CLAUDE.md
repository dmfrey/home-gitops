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
just kube sync <hr|ks|es|gitrepo|ocirepo>  # Force-sync all resources of a given type
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

- **Kubernetes secrets**: `ExternalSecret` resources pull from 1Password via `ClusterSecretStore: onepassword-connect`. Data keys use `op://` vault paths in template values.
- **Talos machine configs**: Reference 1Password directly with `op://kubernetes/talos/...` syntax in `.j2` templates.
- **Bootstrap secrets**: `bootstrap/resources.yaml.j2` rendered via `minijinja-cli | op inject` at bootstrap time; no SOPS/age encryption used.
- **Cluster-wide substitution**: `postBuild.substituteFrom` in `ks.yaml` pulls from `cluster-secrets` Secret for variables like `${IPV6_IOT_PREFIX}`.
- **1Password Connect** (`kubernetes/apps/external-secrets/onepassword-connect/`): 2026-08-03, migrated from a hand-rolled `bjw-s app-template` deployment to 1Password's own official chart (`oci://ghcr.io/1password/connect`), matching `oneDr0p/home-ops`'s pattern. The `ClusterSecretStore` was renamed from `onepassword` to `onepassword-connect` — this is referenced by essentially every `ExternalSecret`/`PushSecret` in the repo (apps directly, plus the shared `components/volsync`, `components/cnpg`, `components/common`, `components/alerts/github-status` templates), so any future rename of this store needs a repo-wide `secretStoreRef.name` sweep across both `kubernetes/apps` **and** `kubernetes/components`, not just one. Credentials are now split into two secrets to match the chart's native shape: `onepassword-connect-credentials-secret` (key `1password-credentials.json`) and `onepassword-connect-vault-secret` (key `OP_CONNECT_TOKEN`) — both created by their own `ExternalSecret` in `app/externalsecret.yaml`, which is self-referential (they authenticate via the same `onepassword-connect` store they help populate) by design, same as the old setup; this is why a from-scratch bootstrap seeds them once directly in `bootstrap/resources.yaml.j2` before Flux/external-secrets ever runs.
    - **The `OP_CREDENTIALS_JSON` 1Password field stores the raw decoded credentials JSON directly, not base64.** It used to be base64-encoded (the format the old `OP_SESSION` env-var mechanism expected), which broke the official chart's file-mount of `1password-credentials.json` — Connect failed to start with `invalid character 'e' looking for beginning of value` (the literal base64 text being fed to its JSON parser), and `bootstrap/resources.yaml.j2` couldn't work around it either (`op inject` does dumb text substitution after minijinja renders, no filter pipeline available there to decode inline). Fixed 2026-08-03 by changing the stored field value itself rather than patching around it in every consumer — both the live `ExternalSecret` template and `op inject` now get the same raw JSON with no decode step needed anywhere. If this field ever gets re-populated from an `OP_SESSION`-style source again, re-decode it before saving.
    - The bootstrap-time path (before Flux exists) deploys Connect via `helmfile` (`bootstrap/helmfile.d/01-apps.yaml`, release name `onepassword-connect`) — its values are _not_ duplicated in the helmfile; `templates/values.yaml.gotmpl` dynamically reads `spec.values` straight out of `kubernetes/apps/external-secrets/onepassword-connect/app/helmrelease.yaml`, keyed by the helmfile release name matching the app directory name. Keep those names in sync or bootstrap silently reads the wrong (or a missing) values file.
    - On a live cluster (not a fresh bootstrap), renaming/re-pointing this store is a real cutover, not just a git change — Flux may reconcile the new `ClusterSecretStore`/Connect deployment before the rest of the app tree picks up the renamed `secretStoreRef`s (each app's `Kustomization` reconciles on its own interval, not all on the git-push webhook), producing a window of cluster-wide `ExternalSecret` failures. Force a full `just kube sync ks` immediately after pushing a store rename to close that window rather than waiting on individual reconcile timers.

### Storage

- **Rook-Ceph**: Distributed block storage on NVMe SSDs across all 3 nodes. Most stateful apps use `existingClaim: ${VOLSYNC_CLAIM}` backed by Ceph.
- **OpenEBS**: Local storage on M.2 SATA SSDs (in Wi-Fi slot).
- **Garage**: S3-compatible object storage running in-cluster (`garage-system` namespace). Genuine 3-node replicated cluster (`replication_factor=3`, one zone per node, migrated from single-node 2026-07-25). Metadata lives on a per-node Ceph PVC via `statefulset.volumeClaimTemplates`; object data lives on 3 **independent** NFS exports (`nas.internal:/garage`, `/garage-1`, `/garage-2`) — deliberately not one shared export split by subpath, since RF=3 replication would otherwise write 3 copies into the same underlying disk pool. Used for CNPG WAL archiving/base backups and DragonflyDB snapshots, and as **live primary storage** for Loki and Tempo (not just backup — an outage stops log/trace ingestion immediately, not just backups). When growing Garage's node count, its inherited `cluster_layout` file (in `metadata_dir`) still reflects the old `replication_factor` and Garage refuses to start until that file is moved aside — a real safety check, not a bug. **The StatefulSet requires `pod.affinity.podAntiAffinity` (`requiredDuringSchedulingIgnoredDuringExecution` on `kubernetes.io/hostname`, added 2026-07-27)** — without it, Kubernetes can freely co-locate 2+ replicas on one node, which silently defeats RF=3's fault tolerance; a single node hiccup then drops the cluster below quorum. This is exactly how a `barman-cloud` backup's catalog-list step failed with "Could not reach quorum of 2" — `garage-0` and `garage-2` had both landed on `k8s-0`. Note `requiredDuringSchedulingIgnoredDuringExecution` only affects scheduling, not already-running pods — but a Helm-triggered rolling restart (any pod template change) is enough to re-evaluate placement and fix it, no manual pod deletion needed.
    - **Before a full-cluster planned shutdown, scale `garage` (StatefulSet) to 0 replicas first**, and `kopia` (Deployment, `volsync-system`) too — releases their NFS mounts on `nas.internal` cleanly while the NAS is still fully responsive, before any node shutdown begins. Added to the outage runbook 2026-08-04 after node shutdowns hung with NFS mounts stuck in uninterruptible D-state once the NAS also went down concurrently; see the Talos Configuration section for the fuller finding. Kopia's own nfs-scaler HPA may flap it back to 1 shortly after; harmless since node shutdown follows immediately.
    - **Single-node metadata crash recovery** (e.g. a Rust panic in `garage_table::gc` after an abrupt power-cycle of the node it's on): with RF=3 and the other 2 nodes healthy, this is safe to recover by resetting _only that node's_ local metadata, not restoring from backup. Scale the StatefulSet down by one replica (`kubectl scale statefulset garage --replicas=2` removes the highest ordinal cleanly, PVCs persist), mount its `meta-*` PVC from a throwaway debug pod, move aside (don't delete) `db.lmdb` only — **preserve `node_key`/`node_key.pub`**, since wiping those would make it rejoin as an unrecognized new node instead of the same cluster member. Scale back to 3; Garage treats the empty metadata store as a normal resync-from-peers case, the same mechanism used when adding a brand new node.
- **VolSync**: PVC backup/restore via Kopia to a local repository (NFS `nas.internal:/Kopia`, browsable via the `kopia` web UI pod in `volsync-system`). Apps using VolSync include `components/volsync` in their `ks.yaml` and set `APP`, `VOLSYNC_CAPACITY`, `VOLSYNC_CACHE_CAPACITY` substitution variables. This component assumes **one PVC per app** (`existingClaim` named after the release) and hardcodes the snapshot-clone StorageClass to `ceph-block-ext4` — it doesn't fit apps with per-replica `volumeClaimTemplates` (StatefulSets with >1 replica) or PVCs on a non-ext4 StorageClass; use standalone `ReplicationSource`/`ExternalSecret` manifests instead in those cases.
- **NFS**: `nas.internal` (QNAP TS-462) for media files and backups.
- **RBD recovery caution**: if a pod is stuck because its Ceph RBD volume went read-only (ext4 `remount-ro` after a Ceph/network blip), do not immediately delete the pod to force a remount — a second RBD hiccup mid-write during that remount can corrupt the filesystem (happened to Garage's metadata DB, 2026-07-23, recovered from a Kopia snapshot). Check `ceph -s` and `ceph osd blocklist ls` first. If a node keeps throwing RBD ESHUTDOWN errors across multiple unrelated volumes, the actual fix is `talosctl -n <ip> reboot -m powercycle` on that node, not cycling individual pods.

### Networking

- **Cilium**: CNI with BGP (AS 64514 peering with UDM-SE at AS 64513). LoadBalancer IPs from `192.168.29.0/24` (VLAN 29). Requires `socketLB.hostNamespaceOnly: false` — DSR mode has a same-node hairpin bug where ClusterIP connections to a backend pod on the same node fail (EADDRNOTAVAIL/ECONNABORTED); this setting moves ClusterIP resolution to `connect()` time for all pod namespaces, bypassing the buggy path. Do not revert it. (Headless Services were never affected — they resolve directly to pod IPs with no ClusterIP/NAT step.)
- **Envoy Gateway**: L7 routing using `HTTPRoute`/`Route` resources. Two gateways: `envoy-external` (Cloudflare tunnel) and `envoy-internal` (UniFi DNS only).
- **ExternalDNS**: Two instances — private DNS to UniFi UDM-SE, public DNS to Cloudflare.
- **Multus**: Used for pods needing IoT VLAN (`192.168.50.0/24`) network access (e.g., Home Assistant).
- **Physical NIC naming (`net0`/`bond0`)**: all 3 nodes use a Talos `LinkAliasConfig` (`talos/machineconfig.yaml.j2`) matching `link.driver == "igc" && mac(link.permanent_addr).startsWith("38:f7:cd:")` to alias the onboard NIC as `net0`, wrapped in a single-link `BondConfig` (`bond0`) for a stable name downstream (`bond0.50`/`bond0.90` VLANs, referenced by both Multus `NetworkAttachmentDefinition`s). `net.ifnames=0` (classic `eth0` naming, boot-order dependent) was removed from `schematic.yaml.j2` 2026-07-29 in favor of this — the alias is driver+MAC based, not name based, so it's immune either way to what a hotplugged device (e.g. an eGPU dock's own NIC) happens to enumerate as or get named. Cilium's `devices` value is `bond+` (not `eth+`) to match — **if this is ever reverted, Cilium's `devices` must be reverted too, or endpoint BPF regeneration breaks fleet-wide** (confirmed: 73/348 controllers failed on the one node migrated before the matching Cilium fix landed). Physical interface now gets a systemd-predictable name (e.g. `enp87s0`) instead of `eth0` — this is expected and correct, not a regression.

### Reusable Kustomize Components

Located in `kubernetes/components/`:

- `volsync/` — VolSync ReplicationSource/Destination and PVC resources
- `cnpg/` — CloudNative PG database cluster. **`Cluster.spec.imageName` PostgreSQL major-version bumps are held via Renovate** (`.renovate/overrides.json5`, `allowedVersions: "<18.0.0"` on `ghcr.io/cloudnative-pg/postgresql`), same pattern as the existing Rook-Ceph/OrcaSlicer/multus holds. 2026-08-03: adopting the shared `home-operations/renovate-presets` config picked up its `managers/cnpg.json5` custom manager, which — for the first time in this repo — started tracking `imageName` and immediately proposed a single PR bumping all 13 CNPG-backed databases from PG 17 to 18 at once. That's a real major-version upgrade, not a routine image swap: PG data files aren't binary-compatible across majors, so it needs a planned per-database migration (CNPG's online logical-replication upgrade, or a backup/restore) rather than a blind Renovate merge. The PR was closed; patch/minor bumps within 17.x still flow through normally. Lift the hold only once there's an actual per-database upgrade plan.
    - **Ceph `volumeSnapshot` backups were deliberately removed fleet-wide 2026-07-15** (commit `dccc8fd27`) — CNPG's `retentionPolicy` only prunes `barmanObjectStore`/plugin backups, not `volumeSnapshot` ones, so the daily volumeSnapshot `ScheduledBackup`s (added incrementally through Jul 1-3 with staggered schedules to avoid overwhelming the single-replica Ceph RBD ctrlplugin) had been accumulating unbounded since October 2025 — ~4,900 orphaned VolumeSnapshots, driving Ceph raw usage to 75%. Every app already had a working barman-cloud/Garage backup with real 7d retention, so the volumeSnapshot layer was redundant; it was removed, not left broken. A 2026-08-03 `flux-pr-reviewer` review flagged `Cluster.status.lastSuccessfulBackupByMethod.volumeSnapshot` being stale and `lastFailedBackup` entries running through 7/24-7/29 as an apparent "silent failure" — that's a false alarm from reading live status without git history: those are frozen leftover fields from the pre-removal `ScheduledBackup`s and the multi-day backlog of orphaned-snapshot cleanup afterward, not evidence of an active problem. No Cluster currently has any `volumeSnapshot`-method backup or `ScheduledBackup` configured (confirmed via live query); barman-cloud/Garage is the sole backup layer by design. No alert rule reads these fields, so there's nothing paging on it either.
- `alerts/` — Prometheus alerting rules
- `common/` — Shared configurations
- `dragonflydb/` — DragonflyDB instance. Includes a `${APP}-dragonfly-unstick` CronJob (every 5m, added 2026-08-04) that deletes any `app=${APP}-dragonflydb` pod stuck `Running` but not `Ready` for more than 3 minutes — added after `immich-dragonflydb-0` hung indefinitely on cold power-on (started the instant before Garage reached S3 quorum, then never restarted on its own; readiness/liveness kept failing but kubelet never intervened). This is a **third DragonflyDB failure mode**, distinct from the missing-`role=master`-label and corrupted-snapshot-crash-loop cases already known — see memory `feedback_dragonflydb_role_label`. The 7 `*-kv` Kustomizations that include this component (`authentik-kv`, `openweb-kv`, `affine-kv`, `excalidraw-kv`, `immich-kv`, `romm-kv`, `pinepods-kv`) each need `postBuild.substitute.APP` set to the app name — check this first if a new `*-kv` app doesn't get the CronJob correctly.
- `nfs-scaler/` — NFS volume scaler

### Talos Configuration

Machine configs are rendered from Jinja2 templates using `minijinja-cli`. The `IS_CONTROLLER` environment variable controls whether controller-plane-specific sections are rendered. Node-specific overrides (type, hostname) live in `talos/nodes/<ip>.yaml.j2`. The Talos schematic includes extensions for the Coral TPU and other hardware.

**eGPU dock history (k8s-2)**: the original AOOSTAR AG02 (ASMedia ASM2464 bridge) had an unresolved PCIe hotplug link problem independent of GPU vendor/drivers (reproduced with both an RTX 5070 and an RTX 3090) — failure signature varied run-to-run even with identical kernel args (sometimes full PCIe enumeration then `pciehp: Timeout on hotplug command 0x1038` ~9-20s later, sometimes died earlier at Thunderbolt retimer/tunnel negotiation), pointing to hardware-level flakiness on that dock's bridge chip specifically. Replaced 2026-07-28 with a **PELADN Link S-3 (Intel Barlow Ridge JHL9480 TB5 controller, PCI `0x8087:0x1234`, retimer `0x8087:0x15ee`)** — link has been fully stable since, zero disconnects across many tests, confirming it was the AG02's bridge chip, not the host/kernel args. `thunderbolt.host_reset=0` and `nvidia.NVreg_OpenRmEnableUnsupportedGpus=1` are currently disabled in `schematic.yaml.j2` (targeted the AG02/older driver builds specifically; not yet proven necessary with this dock) — re-enable only with a clear new hypothesis, per the file's inline history. **The dock also exposes a USB-attached Realtek NIC** (driver `r8152`, MAC `00:e0:4c:*`, off the Thunderbolt controller's own USB port) alongside GPU passthrough — confirmed present via `talosctl get links`, currently blacklisted (`module_blacklist=r8152` in `schematic.yaml.j2`, unconditional/all 3 nodes) so it can never appear as a network device regardless of cable state; this turned out _not_ to be the cause of the boot hangs below, but is worth keeping blacklisted regardless as good hygiene.

**Talos's NVIDIA extensions assume an always-present GPU, not a Thunderbolt-hotplugged one** — `ext-nvidia-persistenced` blocks the entire boot on `/sys/bus/pci/drivers/nvidia` existing, which only appears after a _successful_ `nvidia.ko` load, and `nvidia.ko` probes for a GPU at insmod time rather than registering and waiting for one to appear later (hard-fails `ENODEV` if none present yet). **2026-07-29: exhausted the testing matrix on k8s-2 — every combination of driver flavor (open `nvidia-open-gpu-kernel-modules-production` and proprietary `nonfree-kmod-nvidia`), boot method (warm kexec reboot with dock pre-connected, and a genuine full cold boot — power off, connect dock, power on), and dock NIC state (present vs. blacklisted) produced the same node hard-lock** (network goes fully unreachable — ARP-level `Destination Host Unreachable`, not just Kubernetes-level `NotReady` — needs a manual power cycle; Talos's own hardware watchdog, see below, will also auto-reset it after 5 minutes if left unattended). None of driver flavor, dock NIC presence, or cold-vs-warm boot changed the outcome. Leading theory is a `nvidia_drm`/`i915` conflict specific to this host (GEEKOM Mini IT13, active `i915` iGPU console) — the clearest single data point is from an earlier proprietary-driver attempt that loaded cleanly (NVRM init logged, DRM recognized the GPU ID, `ext-nvidia-persistenced` came up) and then hard-hung the whole node a couple of minutes later, specifically when `nvidia_drm` was in the `machine.kernel.modules` list; dropping `nvidia_drm` avoided _that_ hang once, but the `KernelModuleSpecController` ENODEV-retry-loop alone (independent of `nvidia_drm`, triggered whenever the modules are configured but the dock isn't yet connected) turned out to be enough to destabilize the node on its own regardless. At the time, current state was **`machine.kernel.modules` removed entirely from `talos/nodes/192.168.30.12.yaml.j2`, node back on the true baseline schematic** (zero NVIDIA extensions) — not safe to leave any eGPU schematic running unattended on this node given how consistent the failure was across every tested confound. Filed as [siderolabs/talos discussion #13896](https://github.com/siderolabs/talos/discussions/13896) with the full testing matrix and hardware IDs; no further leads from maintainers as of that point. An earlier version of this file claimed a `machine.udev.rules` PCI-hotplug-triggered `modprobe` was "the correct fix" — **that was this project's own unverified speculation, not documented Talos guidance**, and untested; don't treat it as settled. Note `talosctl service <name> restart` doesn't work for early-boot-critical services like `udevd`, and `install.image` changes require an actual `talosctl upgrade`/reboot (`apply-config` alone silently no-ops on that field, though it does apply `machine.kernel.modules`/other fields live) — **always regenerate the schematic ID fresh (`just talos gen-schematic-id[-egpu[-proprietary]]`) before reusing one in a revert; reusing a stale ID from an earlier point in the same session silently drops any schematic changes made since** (happened once 2026-07-29 — a "revert to baseline" accidentally reused an ID that predated the r8152 blacklist).

**RESOLVED 2026-07-30**: root cause found via a physical console screenshot of the hang for the first time (previously only visible via dmesg after reboot, which loses the exact failure point) — a genuine hard lock (keyboard fully unresponsive), occurring right after `ext-nvidia-cdi-gen` starts successfully (a GPU probe/query), not during module load or `ext-nvidia-persistenced` startup. The RTX 3090's driver (580.173.02, Ampere) uses GSP (GPU System Processor) firmware by default — an async RPC channel to a separate on-GPU microcontroller, a known source of driver hangs when that RPC deadlocks, and hotplugged/docked GPUs are a much less-tested scenario for GSP than natively-present ones. Fix: `machine.kernel.modules[nvidia].parameters: [NVreg_EnableGpuFirmware=0]` in `talos/nodes/192.168.30.12.yaml.j2`, forcing the older non-GSP init path. `ext-nvidia-cdi-gen` completed successfully for the first time ever, full boot completed, `gpu.nvidia.com` ResourceSlice registered correctly (RTX 3090, Ampere, cudaComputeCapability 8.6.0). Confirmed end-to-end with `ollama-gpu` (`kubernetes/apps/ai/ollama-gpu`) scheduled and `nvidia-smi` working inside the pod. The `nvidia_drm`/`i915` conflict theory above was never the actual cause — GSP firmware was. Two physical Thunderbolt ports on this node were also tested (asymmetric BIOS-reserved PCIe windows, Root Port #2 vs #1) and ruled out as a factor; both enumerate the GPU cleanly, port choice wasn't the fix.

**GPU Operator + DRA**: per the official Talos DRA doc (confirmed by a Talos maintainer, siderolabs/talos discussion #13896), the documented install is GPU Operator _plus_ DRA layered on top, not DRA standalone. `kube-system/gpu-operator` (first `HelmRepository`-based app in this repo — NVIDIA only publishes this chart classically via `helm.ngc.nvidia.com`, no OCI artifact exists) is now installed underneath the pre-existing `kube-system/nvidia-gpu-resource-driver` (`dependsOn: gpu-operator`), with `driver.enabled=false`, `toolkit.enabled=false`, `devicePlugin.enabled=false` (Talos's own extensions provide the driver/toolkit; DRA replaces the device plugin role), `hostPaths.driverInstallDir=/usr/local` (matches the DRA driver's existing `nvidiaDriverRoot`), and `nfd.enabled=false` (this repo already runs standalone `kube-system/node-feature-discovery`; GPU Operator bundles its own NFD subchart by default, which would run as a second, competing controller otherwise). GPU Operator only orchestrates Kubernetes-level plumbing around an _already-loaded_ driver; it didn't by itself fix the boot-blocking/hard-lock issue above — that turned out to be a separate GSP firmware problem, see the RESOLVED note above.

**`talosctl get pcidevices` is a boot-time snapshot, not live state** — it won't show a device that was hotplugged after boot (e.g. the eGPU connecting mid-session). Check `talosctl -n <ip> read /sys/bus/pci/devices/<addr>/uevent` instead for genuinely current PCI device presence.

**`just talos upgrade-node`'s `health-check` dependency needs a real TTY for its `gum confirm` prompt** — it fails outright (`could not open a new TTY`) in this non-interactive environment whenever it finds a problem (Ceph not `HEALTH_OK`, a CNPG backup, or _any_ active VolSync sync cluster-wide, even on an unrelated node). Verify manually whether the flagged condition actually affects the target node (e.g. `kubectl get pods -A -o wide` to check which node a VolSync mover pod is on) before bypassing — if it's unrelated, call `talosctl -n <ip> upgrade -i "$(just talos machine-image <ip>)" -m powercycle --timeout=10m` directly instead of the `just talos upgrade-node` wrapper. **`upgrade-node` still has no bypass** (it never prompted directly, only via `health-check`), but `shutdown-node`/`reboot-node` and `health-check` itself now accept `FORCE=1` in the environment (added 2026-08-04) to skip their `gum confirm` prompts entirely — e.g. `FORCE=1 just talos shutdown-node <ip>` runs fully non-interactively. Default (no `FORCE`) behavior is unchanged; only set it deliberately, since it also skips the health-check's own safety confirmation.

**Full-cluster planned shutdown (e.g. for a power outage), lesson from 2026-08-04**: graceful `talosctl shutdown --force` reliably works for the _first_ node shut down (Ceph mon quorum still intact, 3/3) but tends to hang indefinitely (stuck at `unmountPodMounts`/`unmountBind`) for the 2nd and 3rd — pod teardown blocks on Ceph mon quorum degrading as more nodes go down, compounded if the NAS is also down and NFS mounts (Garage/Kopia → `nas.internal`) go into uninterruptible D-state. When this happens, Talos's watchdog aborts the stuck shutdown and the node returns to `RUNNING` rather than powering off. **Treat physical power-off as the expected standard method for the 2nd/3rd node in a full-cluster shutdown, not a last-resort fallback** — don't burn time retrying graceful shutdown multiple times once it's stalled past a few minutes. Scaling `garage` (StatefulSet) and `kopia` (Deployment, `volsync-system`) to 0 replicas _before_ touching any node's power — while the NAS is still fully responsive — releases their NFS mounts cleanly and removes one trigger for the D-state hang; see also the Garage/Kopia note under Storage below.

**etcd defragmentation** (`talosctl -n <ip> etcd defrag`, no `just` recipe exists for this): run one node at a time, followers before the leader (check `talosctl -n <ip1>,<ip2>,<ip3> etcd status` for the `LEADER` column first) — defragging is a blocking operation on that member and doing all 3 simultaneously risks a real quorum gap rather than just a brief leader handoff.

### Schema Validation

YAML files use inline schema comments pointing to `https://kubernetes-schemas.dmfrey.com/` for IDE validation. Secrets, ReplicationSource, and ReplicationDestination kinds are skipped during validation.

### CI/CD

GitHub Actions runs the `Flate` workflow (`.github/workflows/flate.yaml`) on PRs touching `kubernetes/**` — it diffs/tests rendered `HelmRelease`/`Kustomization` output for changed files. `flux-local` and `kubeconform` are dev-time tools invoked via `just` recipes (`kubernetes/mod.just`), not part of CI. Renovate monitors the entire repository for dependency updates and auto-creates PRs.

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
