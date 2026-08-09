set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']

kubernetes_dir := justfile_dir() + '/kubernetes'

[private]
default:
    just -l kube

[doc('Apply local Flux Kustomization')]
apply-ks ns ks:
    just kube render-local-ks "{{ ns }}" "{{ ks }}" | kubectl apply --server-side --force-conflicts --field-manager=kustomize-controller -f /dev/stdin

[doc('Browse a PVC')]
browse-pvc namespace claim:
    kubectl run -n {{ namespace }} browse-pvc-{{ claim }} -it --rm --restart=Never \
        --image=mirror.gcr.io/alpine:latest \
        --overrides='{"spec":{"containers":[{"name":"browse-pvc-{{ claim }}","image":"mirror.gcr.io/alpine:latest","stdin":true,"tty":true,"command":["/bin/sh"],"workingDir":"/mnt","volumeMounts":[{"mountPath":"/mnt","name":"data"}]}],"volumes":[{"name":"data","persistentVolumeClaim":{"claimName":"{{ claim }}"}}]}}'

[doc('Delete local Flux Kustomization')]
delete-ks ns ks:
    just k8s render-local-ks "{{ ns }}" "{{ ks }}" | kubectl delete -f /dev/stdin

[doc('Open a shell on a node')]
node-shell node:
    trap 'kubectl delete pod -n default -l app.kubernetes.io/managed-by=kubectl-debug --field-selector spec.nodeName={{ node }} --ignore-not-found --wait=false' EXIT
    kubectl debug node/{{ node }} -n default -it --image="mirror.gcr.io/alpine:latest" --profile sysadmin

[doc('Prune pods in Failed, Pending, or Succeeded state')]
prune-pods:
    for phase in Failed Pending Succeeded; do \
        kubectl delete pods -A --field-selector status.phase="$phase" --ignore-not-found=true; \
    done

[doc('Snapshot VolSync PVCs')]
snapshot:
    kubectl get replicationsources --no-headers -A | while read -r ns name _; do \
        kubectl -n "$ns" patch replicationsources "$name" --type merge -p '{"spec":{"trigger":{"manual":"$(date +%s)"}}}'; \
    done

[doc('Suspend or resume Keda ScaledObjects')]
keda state:
    kubectl get scaledobjects --no-headers -A | while read -r ns name _; do \
        kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite so "$name" autoscaling.keda.sh/paused{{ if state != "suspend" { "-" } else { "=true" } }}; \
    done

[doc('Suspend or resume CNPG clusters for node maintenance')]
cnpg state:
    kubectl get clusters --no-headers -A | while read -r ns name _; do \
        for i in 1 2 3; do \
            kubectl -n "$ns" patch cluster "$name" --type merge \
                -p '{"spec":{"nodeMaintenanceWindow":{"inProgress":{{ if state == "suspend" { "true" } else { "false" } }},"reusePVC":true}}}' \
                && break || { echo "retry $i/3 for $ns/$name" >&2; sleep 3; }; \
        done; \
    done

[doc('Suspend or resume VolSync')]
volsync state:
    flux -n volsync-system {{ state }} kustomization volsync
    flux -n volsync-system {{ state }} helmrelease volsync
    kubectl -n volsync-system scale deployment volsync --replicas {{ if state != "suspend" { "1" } else { "0" } }}

[arg('resource', pattern='hr|ks|gitrepo|ocirepo|es')]
[doc('Sync a resource (hr|ks|gitrepo|ocirepo|es)')]
sync resource:
    kubectl get {{ resource }} --no-headers -A | while read -r ns name _; do \
        kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite {{ resource }} "$name" \
            "force-sync=$(date +%s)" \
            "reconcile.fluxcd.io/requestedAt=$(date +%s)" \
            "reconcile.fluxcd.io/forceAt=$(date +%s)"; \
    done

[doc('View a secret')]
view-secret namespace secret:
    kubectl view-secret -n {{ namespace }} {{ secret }}

[private]
render-local-ks ns ks:
    flate build ks --namespace "{{ ns }}" --path "{{ kubernetes_dir }}/flux/cluster" "{{ ks }}"
