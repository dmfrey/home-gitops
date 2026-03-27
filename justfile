#!/usr/bin/env -S just --justfile

set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

mod bootstrap "bootstrap"
mod kube "kubernetes"
mod talos "talos"

[private]
default:
    just -l

[doc('Verify all required tools are present')]
doctor:
    #!/usr/bin/env bash
    missing=()
    for tool in just kubectl flux talosctl helm kustomize minijinja-cli op gum flux-local; do
        command -v "$tool" &>/dev/null || missing+=("$tool")
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        echo "All tools present"
    else
        echo "Missing: ${missing[*]}"
        echo "Hint: run 'mise install' for mise-managed tools (e.g. flux-local)"
        exit 1
    fi

[private]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
template file *args:
    minijinja-cli "{{ file }}" {{ args }} | op inject
