---
name: talos-node
description: Talos Linux node operations for the homelab cluster — apply config, upgrade Talos/Kubernetes, reboot, reset, render config. Use when working with node-level operations rather than Kubernetes workloads.
argument-hint: <node-ip> [operation]
---

You are assisting with Talos Linux node operations on a 3-node homelab cluster. All operations use `just talos <cmd>` which wraps `talosctl` with Jinja2 config rendering via `minijinja-cli | op inject`.

## Environment

- `TALOSCONFIG=./talosconfig` (set automatically by .mise.toml)
- All `just talos` commands must be run from the repo root
- Secrets injected at render time from 1Password via `op inject`

## Cluster nodes

| IP            | Hostname | Role         |
| ------------- | -------- | ------------ |
| 192.168.30.10 | k8s-0    | controlplane |
| 192.168.30.11 | k8s-1    | controlplane |
| 192.168.30.12 | k8s-2    | controlplane |

All three nodes are controlplane nodes (HA control plane). Node configs live in `talos/nodes/<ip>.yaml.j2`.

## Common operations

### Apply config to a node

```bash
just talos apply-node <ip>
```

Renders the Jinja2 template for that node and applies it via `talosctl apply-config`. Use after editing `talos/machineconfig.yaml.j2` or `talos/nodes/<ip>.yaml.j2`.

### Render config (dry run)

```bash
just talos render-config <ip>
```

Prints the rendered config without applying — useful for review before applying.

### Upgrade Talos on a node

```bash
just talos upgrade-node <ip>
```

Upgrades using the image defined in `machineconfig.yaml.j2`. Upgrade one node at a time. The node reboots using `powercycle` mode.

**Upgrade sequence**: upgrade each node individually, waiting for it to rejoin before proceeding. Check node health with `kubectl get nodes` between upgrades.

### Upgrade Kubernetes version

```bash
just talos upgrade-k8s <version>   # e.g. v1.32.0
```

Runs against the first controller endpoint. Only run after all nodes are on the target Talos version.

### Reboot a node

```bash
just talos reboot-node <ip>
```

Prompts for confirmation before rebooting. Uses `powercycle` mode.

### Shutdown a node

```bash
just talos shutdown-node <ip>
```

Prompts for confirmation before shutdown.

### Reset a node (destructive)

```bash
just talos reset-node <ip>
```

**Destructive** — wipes STATE, EPHEMERAL, and u-local-hostpath. Prompts for confirmation. Only use for decommissioning or re-provisioning a node.

### Generate schematic ID

```bash
just talos gen-schematic-id
```

Renders `talos/schematic.yaml.j2` and POSTs to `factory.talos.dev` to get the schematic ID. Run this after modifying the schematic (e.g. adding/removing extensions).

### Download Talos ISO

```bash
just talos download-image <version> <schematic-id>
```

Downloads the metal-amd64 ISO for the given version and schematic.

## Config file structure

```
talos/
├── machineconfig.yaml.j2    # base config for all nodes
├── schematic.yaml.j2        # Talos image schematic (extensions: Coral TPU, etc.)
└── nodes/
    ├── 192.168.30.10.yaml.j2  # k8s-0: controlplane, zone dmf-u
    ├── 192.168.30.11.yaml.j2  # k8s-1: controlplane, zone dmf-u
    └── 192.168.30.12.yaml.j2  # k8s-2: controlplane, zone dmf-u
```

Node overrides set `machine.type` and `hostname` via `HostnameConfig`. The `IS_CONTROLLER` env var is derived automatically by `just talos render-config`.

## Safety guidelines

- **Drain before maintenance**: `kubectl drain <node> --ignore-daemonsets --delete-emulated-storage`
- **Suspend VolSync and CNPG** before draining: `just kube volsync suspend && just kube cnpg suspend`
- **Resume after**: `just kube volsync resume && just kube cnpg resume`
- **Never reset without explicit confirmation** — reset wipes all local data
- **Upgrade one node at a time** — verify `kubectl get nodes` shows Ready before proceeding to the next
- **Rook-Ceph**: after a node upgrade/reboot, verify OSDs come back healthy: `kubectl -n rook-ceph get pods`
