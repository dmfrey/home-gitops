set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

talos_dir := justfile_dir() + '/talos'
controller := `talosctl config info -o yaml 2>/dev/null | yq -e '.endpoints[0]' 2>/dev/null || true`

[private]
default:
    just -l talos

[doc('Apply Talos config to a node')]
apply-node node *args: health-check
    just talos render-config "{{ node }}" | talosctl -n "{{ node }}" apply-config -f /dev/stdin {{ args }}

[doc('Download Talos machine image')]
download-image version schematic:
    gum spin --title "Downloading Talos {{ version }} ..." -- \
    curl -sfL --remove-on-error --retry 5 --retry-delay 5 --retry-all-errors \
        -o "{{ talos_dir }}/talos-{{ version }}-{{ replace_regex(schematic, '^(.{8}).*', '$1') }}.iso" \
        "https://factory.talos.dev/image/{{ schematic }}/{{ version }}/metal-amd64.iso"
    just log info "Downloaded Talos" version "{{ version }}" schematic "{{ schematic }}"

[doc('Generate schematic ID from Talos schematic')]
gen-schematic-id:
    curl -sX POST --data-binary @<(just template "{{ talos_dir }}/schematic.yaml.j2") "https://factory.talos.dev/schematics" | jq -r '.id'

[doc('Generate schematic ID for the eGPU (k8s-2) variant')]
gen-schematic-id-egpu:
    curl -sX POST --data-binary @<(EGPU=true just template "{{ talos_dir }}/schematic.yaml.j2") "https://factory.talos.dev/schematics" | jq -r '.id'

[doc('Reboot a node')]
reboot-node node: health-check
    gum confirm "Reboot node {{ node }}?" --default="No" && \
        talosctl -n {{ node }} reboot -m powercycle || exit 0

[doc('Render Talos config for a node')]
render-config node:
    export IS_CONTROLLER="$(just talos machine-controller {{ node }})"; \
    talosctl machineconfig patch <(just template "{{ talos_dir }}/machineconfig.yaml.j2") \
        -p @<(just template "{{ talos_dir }}/nodes/{{ node }}.yaml.j2")

[doc('Reset a node')]
reset-node node *args: health-check
    gum confirm "Reset node {{ node }}?" --default="No" && \
        talosctl -n "{{ node }}" reset --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --system-labels-to-wipe u-local-hostpath --graceful=false {{ args }} || exit 0

[doc('Shutdown a node')]
shutdown-node node *args: health-check
    gum confirm "Shutdown node {{ node }}?" --default="No" && \
        talosctl -n "{{ node }}" shutdown --force {{ args }} || exit 0

[doc('Upgrade Kubernetes version on the cluster')]
upgrade-k8s version: health-check
    talosctl -n "{{ controller }}" upgrade-k8s --to {{ version }}

[doc('Upgrade Talos version on a node')]
upgrade-node node *args: health-check
    talosctl -n "{{ node }}" upgrade -i "$(just talos machine-image {{ node }})" -m powercycle --timeout=10m {{ args }}

[private]
health-check:
    #!/usr/bin/env bash
    set -euo pipefail
    problems=()

    ceph_health="$(kubectl -n rook-ceph get cephcluster rook-ceph -o jsonpath='{.status.ceph.health}' 2>/dev/null || echo UNKNOWN)"
    [[ "$ceph_health" == "HEALTH_OK" ]] || problems+=("Ceph health is $ceph_health (expected HEALTH_OK)")

    while IFS= read -r line; do
        [[ -n "$line" ]] && problems+=("CNPG backup in progress: $line")
    done < <(kubectl get backups.postgresql.cnpg.io -A -o json 2>/dev/null \
        | jq -r '.items[] | select(.status.phase as $p | ["running","started","pending"] | index($p) != null) | "\(.metadata.namespace)/\(.metadata.name) (\(.status.phase))"')

    while IFS= read -r line; do
        [[ -n "$line" ]] && problems+=("VolSync sync in progress: $line")
    done < <(kubectl get replicationsources.volsync.backube -A -o json 2>/dev/null \
        | jq -r '.items[] | select((.status.conditions // []) | any(.type == "Synchronizing" and .status == "True")) | "\(.metadata.namespace)/\(.metadata.name)"')

    if [[ ${#problems[@]} -eq 0 ]]; then
        just log info "Cluster health checks passed"
        exit 0
    fi

    just log warn "Cluster health checks failed" count "${#problems[@]}"
    for p in "${problems[@]}"; do
        echo "  - $p" >&2
    done
    gum confirm "Proceed anyway?" --default="No"

[private]
machine-controller node:
    just template "{{ talos_dir }}/nodes/{{ node }}.yaml.j2" | yq -e 'select(.machine) | (.machine.type == "controlplane") // ""'

[private]
machine-image node:
    just talos render-config "{{ node }}" | yq -re 'select(.machine) | .machine.install.image'
