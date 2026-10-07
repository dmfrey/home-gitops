#!/usr/bin/env bash
# fetch-envoy-docs.sh — pull curated, version-matched troubleshooting docs for Envoy's
# knowledge ingestion, and write a manifest with product/version/doc_type/source_url per file.
#
# Usage:
#   ./fetch-envoy-docs.sh [OUT_DIR]            # download only (default OUT_DIR=./envoy-docs)
#   UPLOAD=1 ENVOY_URL=https://envoy.internal ./fetch-envoy-docs.sh   # download, then upload
#
# Requires: git, bash 4+. Optional: kubectl (autodetects Ceph release, CNPG operator, k8s version).
# Uses shallow, blob-filtered, sparse clones, so only the listed files are downloaded.
#
# Versions below match home-gitops as of 2026-10-06. Override any via env var.
set -euo pipefail

OUT_DIR="${1:-./envoy-docs}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
MANIFEST="$OUT_DIR/manifest.jsonl"

ROOK_REF="${ROOK_REF:-v1.20.8}"
CILIUM_REF="${CILIUM_REF:-v1.18.6}"
GARAGE_REF="${GARAGE_REF:-v2.4.1}"          # GitHub mirror of git.deuxfleurs.fr
TALOS_DOCS="${TALOS_DOCS:-v1.14}"           # nodes run Talos v1.14.2
OPENEBS_DOCS="${OPENEBS_DOCS:-4.4.x}"       # chart 4.4.0, local-pv hostpath in use
CEPH_BRANCH="${CEPH_BRANCH:-}"              # e.g. squid, tentacle — autodetected if empty
CNPG_REF="${CNPG_REF:-}"                    # e.g. v1.28.4 — autodetected if empty
K8S_VERSION="${K8S_VERSION:-}"              # e.g. 1.34 — autodetected if empty (tag only)

# --- Autodetect from the cluster where possible -------------------------------------------
if command -v kubectl >/dev/null 2>&1; then
  if [[ -z "$CEPH_BRANCH" ]]; then
    CEPH_BRANCH="$(kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph version 2>/dev/null \
      | grep -oE '\b(reef|squid|tentacle|umbrella)\b' | head -1 || true)"
  fi
  if [[ -z "$CNPG_REF" ]]; then
    tag="$(kubectl get deploy -A -l app.kubernetes.io/name=cloudnative-pg \
      -o jsonpath='{.items[0].spec.template.spec.containers[0].image}' 2>/dev/null \
      | sed -E 's/@sha256.*//; s/.*://' || true)"
    [[ -n "$tag" ]] && CNPG_REF="v${tag#v}"
  fi
  if [[ -z "$K8S_VERSION" ]]; then
    K8S_VERSION="$(kubectl version -o json 2>/dev/null \
      | grep -A3 '"serverVersion"' | grep -oE '"(major|minor)": *"[0-9]+' | grep -oE '[0-9]+$' \
      | paste -sd. - || true)"
  fi
fi
if [[ -z "$CEPH_BRANCH" ]]; then
  CEPH_BRANCH=squid; echo "WARN: Ceph release not detected; using '$CEPH_BRANCH' (set CEPH_BRANCH)" >&2
fi
if [[ -z "$CNPG_REF" ]]; then
  CNPG_REF=main; echo "WARN: CNPG operator version not detected; using 'main' (set CNPG_REF)" >&2
fi
K8S_VERSION="${K8S_VERSION:-unknown}"

mkdir -p "$OUT_DIR"
: > "$MANIFEST"

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# fetch REPO REF PRODUCT VERSION DOC_TYPE "PATH [PATH...]" ["EXCLUDE_REGEX"]
fetch() {
  local repo="$1" ref="$2" product="$3" version="$4" doc_type="$5" paths="$6" exclude="${7:-^$}"
  local dir="$WORK_DIR/$(echo "$repo" | tr / _)_$ref"
  echo "==> $repo@$ref ($product $version)"
  if [[ ! -d "$dir" ]]; then
    git -c advice.detachedHead=false clone -q --depth 1 --filter=blob:none --no-checkout \
      --branch "$ref" "https://github.com/$repo.git" "$dir"
  fi
  # Non-cone sparse checkout so both files and directories can be listed.
  local patterns=()
  for p in $paths; do patterns+=("/$p"); done
  git -C "$dir" sparse-checkout set --no-cone "${patterns[@]}"
  git -C "$dir" -c advice.detachedHead=false checkout -q
  local count=0
  for p in $paths; do
    while IFS= read -r -d '' f; do
      local rel="${f#"$dir"/}"
      [[ "$rel" =~ $exclude ]] && continue
      [[ "$rel" =~ \.(md|mdx|rst|txt)$ ]] || continue
      local dest="$OUT_DIR/$product/$version/$rel"
      mkdir -p "$(dirname "$dest")"
      cp "$f" "$dest"
      printf '{"file":"%s","product":"%s","version":"%s","doc_type":"%s","source_url":"%s"}\n' \
        "$(json_escape "${dest#"$OUT_DIR"/}")" "$product" "$version" "$doc_type" \
        "$(json_escape "https://github.com/$repo/blob/$ref/$rel")" >> "$MANIFEST"
      count=$((count + 1))
    done < <(find "$dir/$p" -type f -print0 2>/dev/null)
  done
  echo "    $count files"
}

# --- Tier 1: infra -------------------------------------------------------------------------
fetch rook/rook "$ROOK_REF" rook "${ROOK_REF#v}" doc \
  "Documentation/Troubleshooting" \
  'openshift-common-issues|performance-profiling|\.pages$'

fetch ceph/ceph "$CEPH_BRANCH" ceph "$CEPH_BRANCH" doc \
  "doc/rados/operations/health-checks.rst doc/rados/troubleshooting" \
  'community\.rst|cpu-profiling|memory-profiling'

fetch deuxfleurs-org/garage "$GARAGE_REF" garage "${GARAGE_REF#v}" doc \
  "doc/book/operations"

fetch openebs/website main openebs "$OPENEBS_DOCS" doc \
  "docs/versioned_docs/version-$OPENEBS_DOCS/troubleshooting/troubleshooting-local-storage.md"

fetch cilium/cilium "$CILIUM_REF" cilium "${CILIUM_REF#v}" doc \
  "Documentation/operations/troubleshooting.rst Documentation/observability/hubble Documentation/observability/visibility.rst"

fetch siderolabs/docs main talos "$TALOS_DOCS" doc \
  "public/talos/$TALOS_DOCS/troubleshooting public/talos/$TALOS_DOCS/build-and-extend-talos/cluster-operations-and-maintenance" \
  'cgroups-analysis'

# --- Tier 2: platform ----------------------------------------------------------------------
fetch kubernetes/website main kubernetes "$K8S_VERSION" doc \
  "content/en/docs/tasks/debug" \
  'windows\.md|audit\.md'

fetch prometheus-operator/runbooks main prometheus-runbooks main runbook \
  "content/runbooks"

fetch fluxcd/website main flux main doc \
  "content/en/flux/cheatsheets/troubleshooting.md"

fetch cloudnative-pg/cloudnative-pg "$CNPG_REF" cnpg "${CNPG_REF#v}" doc \
  "docs/src/troubleshooting.md docs/src/failover.md docs/src/backup.md docs/src/recovery.md docs/src/wal_archiving.md"

fetch grafana/loki main loki main doc \
  "docs/sources/operations/troubleshooting" \
  'troubleshoot-drilldown'

fetch grafana/alloy main alloy main doc \
  "docs/sources/troubleshoot" \
  'import-mixin-dashboards'

total="$(wc -l < "$MANIFEST" | tr -d ' ')"
echo
echo "Done: $total files in $OUT_DIR (manifest: $MANIFEST)"
echo "Versions used: ceph=$CEPH_BRANCH cnpg=$CNPG_REF kubernetes=$K8S_VERSION talos=$TALOS_DOCS"

# --- Optional upload -----------------------------------------------------------------------
# Field names must match Envoy's knowledge upload endpoint (phase 3 PR 2). Adjust if they differ.
if [[ "${UPLOAD:-0}" == "1" ]]; then
  : "${ENVOY_URL:?set ENVOY_URL, e.g. https://envoy.<internal-domain>}"
  UPLOAD_PATH="${UPLOAD_PATH:-/api/knowledge/documents}"
  ok=0; fail=0
  while IFS= read -r line; do
    file="$(sed -E 's/.*"file":"([^"]*)".*/\1/' <<<"$line")"
    product="$(sed -E 's/.*"product":"([^"]*)".*/\1/' <<<"$line")"
    version="$(sed -E 's/.*"version":"([^"]*)".*/\1/' <<<"$line")"
    doc_type="$(sed -E 's/.*"doc_type":"([^"]*)".*/\1/' <<<"$line")"
    source_url="$(sed -E 's/.*"source_url":"([^"]*)".*/\1/' <<<"$line")"
    if curl -fsS -o /dev/null -X POST "$ENVOY_URL$UPLOAD_PATH" \
         -F "file=@$OUT_DIR/$file;type=text/plain" \
         -F "product=$product" -F "version=$version" \
         -F "docType=$doc_type" -F "sourceUrl=$source_url"; then
      ok=$((ok + 1))
    else
      fail=$((fail + 1)); echo "FAILED: $file" >&2
    fi
  done < "$MANIFEST"
  echo "Uploaded: $ok ok, $fail failed"
fi
