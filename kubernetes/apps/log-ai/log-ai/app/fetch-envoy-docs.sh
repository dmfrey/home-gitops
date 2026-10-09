#!/usr/bin/env bash
# fetch-envoy-docs.sh — pull curated, version-matched troubleshooting docs for Envoy's
# knowledge ingestion, and write a manifest with product/version/doc_type/source_url per file.
#
# Usage:
#   ./fetch-envoy-docs.sh [OUT_DIR]            # download only (default OUT_DIR=./envoy-docs)
#   UPLOAD=1 ENVOY_URL=https://envoy.internal ./fetch-envoy-docs.sh   # download, then upload
#
# Requires: git, bash 4+. Upload also needs curl and jq.
# Optional: kubectl (autodetects Ceph release, CNPG operator, k8s, Loki and Alloy versions).
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
K8S_VERSION="${K8S_VERSION:-}"              # e.g. 1.34 — autodetected if empty
LOKI_REF="${LOKI_REF:-}"                    # e.g. v3.5.9 — autodetected if empty
ALLOY_REF="${ALLOY_REF:-}"                  # e.g. v1.19.2 — autodetected if empty

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
  # image_tag <label selector> <image regex>: tag of the first matching workload whose first
  # container image matches the regex. The regex matters: the Loki chart's gateway Deployment
  # carries the same app.kubernetes.io/name label but runs nginx.
  image_tag() {
    kubectl get deploy,statefulset,daemonset -A -l "$1" \
      -o jsonpath='{range .items[*]}{.spec.template.spec.containers[0].image}{"\n"}{end}' 2>/dev/null \
      | grep -E "$2" | head -1 | sed -E 's/@sha256.*//; s/.*://' || true
  }
  if [[ -z "$LOKI_REF" ]]; then
    tag="$(image_tag app.kubernetes.io/name=loki '/grafana/loki:')"
    [[ -n "$tag" ]] && LOKI_REF="v${tag#v}"
  fi
  if [[ -z "$ALLOY_REF" ]]; then
    tag="$(image_tag app.kubernetes.io/name=alloy '/grafana/alloy:')"
    [[ -n "$tag" ]] && ALLOY_REF="v${tag#v}"
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
# Kubernetes docs: use the release branch matching the cluster, so the version label is true.
K8S_REF=main
if [[ -n "$K8S_VERSION" ]] && git ls-remote --exit-code --heads \
     https://github.com/kubernetes/website.git "release-$K8S_VERSION" >/dev/null 2>&1; then
  K8S_REF="release-$K8S_VERSION"
else
  echo "WARN: no kubernetes/website release-${K8S_VERSION:-?} branch; using main, labelled 'main'" >&2
  K8S_VERSION=main
fi
if [[ -z "$LOKI_REF" ]]; then
  LOKI_REF=main; echo "WARN: Loki version not detected; using 'main' (set LOKI_REF)" >&2
fi
if [[ -z "$ALLOY_REF" ]]; then
  ALLOY_REF=main; echo "WARN: Alloy version not detected; using 'main' (set ALLOY_REF)" >&2
fi

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
      [[ "$(basename "$rel")" == "_index.md" ]] && continue   # Hugo section stubs: front matter only
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
  (( count > 0 )) || echo "WARN: no files from $repo@$ref; check the paths for this version" >&2
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
fetch kubernetes/website "$K8S_REF" kubernetes "$K8S_VERSION" doc \
  "content/en/docs/tasks/debug" \
  'windows\.md|audit\.md'

fetch prometheus-operator/runbooks main prometheus-runbooks main runbook \
  "content/runbooks"

fetch fluxcd/website main flux main doc \
  "content/en/flux/cheatsheets/troubleshooting.md"

fetch cloudnative-pg/cloudnative-pg "$CNPG_REF" cnpg "${CNPG_REF#v}" doc \
  "docs/src/troubleshooting.md docs/src/failover.md docs/src/backup.md docs/src/recovery.md docs/src/wal_archiving.md"

fetch grafana/loki "$LOKI_REF" loki "${LOKI_REF#v}" doc \
  "docs/sources/operations/troubleshooting docs/sources/operations/troubleshooting.md" \
  'troubleshoot-drilldown'   # a directory on newer releases, a single file on 3.5.x

fetch grafana/alloy "$ALLOY_REF" alloy "${ALLOY_REF#v}" doc \
  "docs/sources/troubleshoot" \
  'import-mixin-dashboards'

total="$(wc -l < "$MANIFEST" | tr -d ' ')"
echo
echo "Done: $total files in $OUT_DIR (manifest: $MANIFEST)"
echo "Versions used: ceph=$CEPH_BRANCH cnpg=$CNPG_REF kubernetes=$K8S_VERSION talos=$TALOS_DOCS loki=$LOKI_REF alloy=$ALLOY_REF"

# --- Optional upload -----------------------------------------------------------------------
# Envoy's knowledge endpoint: POST multipart file + product, version, doc_type, source_url.
# - Envoy keys documents by filename, so each upload gets a unique name derived from its path
#   (re-uploading the same name replaces that document, which makes a rerun idempotent).
# - Envoy accepts only .pdf/.docx/.txt, so text sources are sent with a .txt suffix.
# - Each upload starts an async parse + embed; wait for it to finish before the next one.
if [[ "${UPLOAD:-0}" == "1" ]]; then
  : "${ENVOY_URL:?set ENVOY_URL to the internal Envoy base URL}"
  command -v jq >/dev/null || { echo "ERROR: upload needs jq" >&2; exit 1; }
  UPLOAD_PATH="${UPLOAD_PATH:-/api/knowledge/documents}"
  INGEST_TIMEOUT="${INGEST_TIMEOUT:-300}"   # seconds to wait for each document
  ready=0; failed=0; rejected=0; timedout=0
  while IFS= read -r line; do
    file="$(jq -r .file <<<"$line")"
    name="$(tr '/' '_' <<<"$file").txt"
    if ! resp="$(curl -fsS -X POST "$ENVOY_URL$UPLOAD_PATH" \
         -F "file=@$OUT_DIR/$file;filename=$name;type=text/plain" \
         -F "product=$(jq -r .product <<<"$line")" \
         -F "version=$(jq -r .version <<<"$line")" \
         -F "doc_type=$(jq -r .doc_type <<<"$line")" \
         -F "source_url=$(jq -r .source_url <<<"$line")")"; then
      rejected=$((rejected + 1)); echo "REJECTED: $name" >&2; continue
    fi
    id="$(jq -r .id <<<"$resp")"
    status=PROCESSING; waited=0
    while [[ "$status" == "PROCESSING" && "$waited" -lt "$INGEST_TIMEOUT" ]]; do
      sleep 2; waited=$((waited + 2))
      status="$(curl -fsS "$ENVOY_URL$UPLOAD_PATH" | jq -r --arg id "$id" '.[] | select(.id == $id) | .status')"
    done
    case "$status" in
      READY)  ready=$((ready + 1)) ;;
      FAILED) failed=$((failed + 1))
              echo "FAILED: $name: $(curl -fsS "$ENVOY_URL$UPLOAD_PATH" \
                | jq -r --arg id "$id" '.[] | select(.id == $id) | .errorMessage')" >&2 ;;
      *)      timedout=$((timedout + 1)); echo "TIMEOUT: $name still $status after ${INGEST_TIMEOUT}s" >&2 ;;
    esac
  done < "$MANIFEST"
  echo "Upload: $ready ready, $failed failed, $rejected rejected, $timedout timed out (of $total)"
  (( failed + rejected + timedout == 0 ))
fi
