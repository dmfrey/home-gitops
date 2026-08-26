#!/usr/bin/env -S just --justfile

set quiet := true
set default-list
set shell := ['bash', '-euo', 'pipefail', '-c']

[group('Bootstrap')]
mod bootstrap "bootstrap"
[group('Kube')]
mod kube "kubernetes"
[group('Talos')]
mod talos "talos"

[doc('Verify all required tools are present')]
doctor:
    #!/usr/bin/env bash
    missing=()
    for tool in just kubectl flux talosctl helm kustomize minijinja-cli op gum flate; do
        command -v "$tool" &>/dev/null || missing+=("$tool")
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        echo "All tools present"
    else
        echo "Missing: ${missing[*]}"
        echo "Hint: run 'mise install' for mise-managed tools (e.g. flate)"
        exit 1
    fi

[private]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
template file *args:
    minijinja-cli "{{ file }}" {{ args }} | op inject
