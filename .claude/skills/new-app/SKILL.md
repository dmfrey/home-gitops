---
name: new-app
description: Scaffold the full directory structure for a new Flux-managed application in this GitOps repo. Interactively prompts for namespace, app name, and optional components (database, DragonflyDB, VolSync, routing), then generates all required files following established repo patterns.
---

Scaffold a new Flux application. **Before writing any files**, use `AskUserQuestion` to gather all required inputs in two rounds as described below. Then generate files based on the answers.

## Round 1 — Identity (ask these together)

Ask for:

1. **Namespace** — which existing namespace? (`self-hosted`, `home`, `media`, `network`, `observability`, `security`, `ai`, `download`, or other)
2. **App name** — kebab-case (e.g. `my-app`)
3. **Container image** — repository and tag (e.g. `ghcr.io/owner/app:1.2.3`)
4. **Routing** — `envoy-internal` (UniFi DNS only, default) or `envoy-external` (Cloudflare tunnel, public internet)

## Round 2 — Optional components (ask these together)

Ask for:

1. **Persistent storage + backup** — does this app need a VolSync-backed PVC? If yes, ask for capacity (default `5Gi`) and cache capacity (default `2Gi`).
2. **PostgreSQL database** — does this app need a CNPG database cluster?
3. **DragonflyDB** — does this app need a DragonflyDB key-value store?
4. **ExternalSecret** — does this app pull secrets from 1Password? (default yes; ask for the 1Password item name and which keys to expose)

Generate all files only after both rounds are complete.

---

## Directory structure to create

```
kubernetes/apps/<namespace>/<app-name>/
├── ks.yaml
└── app/
    ├── kustomization.yaml
    ├── ocirepository.yaml
    ├── helmrelease.yaml
    └── externalsecret.yaml   # omit if no secrets needed
```

---

## File templates

### ks.yaml

Base (always present):

```yaml
---
# yaml-language-server: $schema=https://kubernetes-schemas.dmfrey.com/kustomize.toolkit.fluxcd.io/kustomization_v1.json
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
    name: <app-name>
spec:
    interval: 1h
    path: ./kubernetes/apps/<namespace>/<app-name>/app
    prune: true
    sourceRef:
        kind: GitRepository
        name: flux-system
        namespace: flux-system
    targetNamespace: <namespace>
    wait: true
```

**`components`** — add only the ones selected:

```yaml
components:
    - ../../../../components/volsync # if VolSync selected
    - ../../../../components/cnpg # if CNPG selected
    - ../../../../components/dragonflydb # if DragonflyDB selected
```

**`dependsOn`** — add entries based on selections:

```yaml
dependsOn:
    - name: rook-ceph-cluster # if VolSync selected
      namespace: rook-ceph
    - name: cloudnative-pg # if CNPG selected
      namespace: datastore
    - name: dragonfly-operator # if DragonflyDB selected
      namespace: datastore
```

**`postBuild`** — add when VolSync is selected:

```yaml
postBuild:
    substitute:
        APP: <app-name>
        VOLSYNC_CAPACITY: <capacity>
        VOLSYNC_CACHE_CAPACITY: <cache-capacity>
    substituteFrom:
        - kind: Secret
          name: cluster-secrets
          optional: false
```

Add `substituteFrom` (without `substitute`) even without VolSync if the app uses cluster-wide variables like `${IPV6_IOT_PREFIX}`.

**Do NOT add** `commonMetadata`, `retryInterval`, or `timeout` — injected cluster-wide.

---

### app/kustomization.yaml

```yaml
---
# yaml-language-server: $schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
    - ./helmrelease.yaml
    - ./ocirepository.yaml
    - ./externalsecret.yaml # omit if no secrets
```

---

### app/ocirepository.yaml

```yaml
---
# yaml-language-server: $schema=https://kubernetes-schemas.dmfrey.com/source.toolkit.fluxcd.io/ocirepository_v1.json
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
    name: <app-name>
spec:
    interval: 15m
    layerSelector:
        mediaType: application/vnd.cncf.helm.chart.content.v1.tar+gzip
        operation: copy
    ref:
        tag: 5.0.0
    url: oci://ghcr.io/bjw-s-labs/helm/app-template
```

---

### app/helmrelease.yaml

```yaml
---
# yaml-language-server: $schema=https://kubernetes-schemas.dmfrey.com/helm.toolkit.fluxcd.io/helmrelease_v2.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
    name: <app-name>
spec:
    chartRef:
        kind: OCIRepository
        name: <app-name>
    interval: 1h
    values:
        controllers:
            <app-name>:
                annotations:
                    reloader.stakater.com/auto: "true"
                containers:
                    app:
                        image:
                            repository: <image-repository>
                            tag: <image-tag>
                        env:
                            TZ: America/New_York
                        probes:
                            liveness: &probes
                                enabled: true
                                custom: true
                                spec:
                                    httpGet:
                                        path: /
                                        port: &port 8080
                                    initialDelaySeconds: 10
                                    periodSeconds: 30
                                    failureThreshold: 5
                            readiness: *probes
                        resources:
                            requests:
                                cpu: 10m
                                memory: 128Mi
                            limits:
                                memory: 256Mi
        defaultPodOptions:
            securityContext:
                runAsNonRoot: true
                runAsUser: 1000
                runAsGroup: 1000
                fsGroup: 1000
                fsGroupChangePolicy: OnRootMismatch
        service:
            app:
                ports:
                    http:
                        port: *port
        route:
            app:
                annotations:
                    gatus.home-operations.com/endpoint: |-
                        conditions: ["[STATUS] < 400"]
                        url: "https://<app-name>.dmfrey.com"
                    gethomepage.dev/enabled: "true"
                    gethomepage.dev/group: <group>
                    gethomepage.dev/name: <Display Name>
                    gethomepage.dev/icon: <app-name>.png
                hostnames:
                    - "{{ .Release.Name }}.dmfrey.com"
                parentRefs:
                    - name: <envoy-internal|envoy-external> # from Round 1 answer
                      namespace: network
```

**If VolSync selected**, add under `values`:

```yaml
persistence:
    data:
        existingClaim: "{{ .Release.Name }}"
        globalMounts:
            - path: /data
```

**If ExternalSecret selected**, add `envFrom` under the container:

```yaml
envFrom:
    - secretRef:
          name: <app-name>-secret
```

---

### app/externalsecret.yaml (omit if no secrets needed)

```yaml
---
# yaml-language-server: $schema=https://kubernetes-schemas.dmfrey.com/external-secrets.io/externalsecret_v1.json
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
    name: <app-name>
spec:
    secretStoreRef:
        name: onepassword
        kind: ClusterSecretStore
    refreshInterval: 15m
    target:
        name: <app-name>-secret
        template:
            engineVersion: v2
            data:
                <KEY>: "{{ .<KEY> }}" # one entry per key from Round 2 answer
    dataFrom:
        - extract:
              key: <1password-item-name> # from Round 2 answer
```

---

## After creating files

Update `kubernetes/apps/<namespace>/kustomization.yaml` — add the new app in alphabetical order:

```yaml
resources:
    - ./<app-name>/ks.yaml
```
