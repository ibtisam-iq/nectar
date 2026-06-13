# The `Application` CRD — Every Field Explained

The `Application` is the **core object in ArgoCD**. It is a Kubernetes Custom Resource (CRD) that tells ArgoCD:
- **Where** to get the desired state from (Git source)
- **Where** to deploy it (destination cluster + namespace)
- **How** to keep it in sync (sync policy)

---

## Minimal Example

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd          # Application CRs always live in the argocd namespace
spec:
  project: default           # AppProject this app belongs to
  source:
    repoURL: https://github.com/my-org/my-cd-repo
    targetRevision: HEAD
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## `metadata` Fields

| Field | Required | Explanation |
|-------|----------|-------------|
| `name` | ✅ | Unique name for this Application inside ArgoCD |
| `namespace` | ✅ | **Always `argocd`** — Application CRs must live in the ArgoCD control-plane namespace |
| `labels` | ❌ | Arbitrary labels; useful for filtering in UI and `argocd app list -l` |
| `annotations` | ❌ | Can hold `argocd.argoproj.io/sync-wave` for ordering sync hooks |
| `finalizers` | ❌ | `resources-finalizer.argocd.argoproj.io` — if set, deleting the Application also deletes all deployed resources (cascade delete) |

---

## `spec.project`

References an `AppProject` CR. Default is `default` (permissive). Projects restrict what repos and namespaces are allowed.

---

## `spec.source` — Single Source

Used when all manifests come from one repo + path.

```yaml
source:
  repoURL: https://github.com/my-org/my-cd-repo   # required
  targetRevision: HEAD                              # required
  path: apps/my-app                                # required
```

### `repoURL`
- The HTTPS or SSH URL of the Git repository
- Must be registered in ArgoCD's known repos (or be public)
- For Helm charts from a chart repo (not Git), use the chart repo URL here

### `targetRevision`
- A Git ref: branch name, tag, or full commit SHA
- `HEAD` means the latest commit on the default branch
- Best practice for production: pin to a **tag** (e.g. `v1.4.2`) not `HEAD`

### `path`
- The directory inside the repo that ArgoCD should look at
- ArgoCD auto-detects the tool (Helm / Kustomize / plain YAML) based on files present here
- Use `.` for the repo root

### Tool-Specific Overrides Inside `source`

#### Helm
```yaml
source:
  repoURL: https://github.com/my-org/my-cd-repo
  targetRevision: HEAD
  path: charts/my-app
  helm:
    releaseName: my-app-prod          # override Helm release name
    valueFiles:
      - values.yaml
      - values-prod.yaml              # environment-specific overrides
    values: |                         # inline values (highest priority)
      replicaCount: 3
    parameters:                       # equivalent to --set
      - name: image.tag
        value: "1.2.3"
```

#### Kustomize
```yaml
source:
  repoURL: https://github.com/my-org/my-cd-repo
  targetRevision: HEAD
  path: overlays/production
  kustomize:
    namePrefix: prod-
    nameSuffix: -v2
    images:
      - name: nginx
        newTag: "1.25.0"
```

#### Kustomize — Enabling `exec` Plugins (the "blocked by default" topic)
By default ArgoCD runs Kustomize in a restricted sandbox. Custom exec plugins are **blocked** unless you explicitly allow them:

```yaml
# In argocd-cm ConfigMap
data:
  kustomize.buildOptions: "--enable-alpha-plugins --enable-exec"
```

> ⚠️ This is the "hack" mentioned in our session. Enabling exec plugins is a security consideration — only do it for trusted repos.

---

## `spec.sources` — Multi-Source (ArgoCD v2.6+)

Allows combining manifests from **multiple repos or paths** into a single Application sync. Common use-case: Helm chart from an external chart repo + your own `values.yaml` from a separate Git repo.

```yaml
spec:
  sources:
    - repoURL: https://charts.bitnami.com/bitnami   # external Helm chart repo
      chart: wordpress
      targetRevision: 15.2.5
      helm:
        valueFiles:
          - $values/environments/prod/wordpress-values.yaml

    - repoURL: https://github.com/my-org/my-values-repo   # your values repo
      targetRevision: HEAD
      ref: values                                          # gives this source the alias "$values"
```

> When `sources` (plural) is used, `source` (singular) must **not** be present — they are mutually exclusive.

---

## `spec.destination`

```yaml
destination:
  server: https://kubernetes.default.svc   # in-cluster; or external cluster API URL
  namespace: my-app
```

| Field | Explanation |
|-------|-------------|
| `server` | Kubernetes API server URL. `https://kubernetes.default.svc` = the same cluster ArgoCD is installed in. For external clusters use the URL registered with `argocd cluster add`. |
| `namespace` | Namespace where resources will be deployed. ArgoCD creates it if `CreateNamespace=true` is set in syncPolicy. |
| `name` | Alternative to `server` — use a cluster's friendly name registered in ArgoCD instead of its URL. |

---

## `spec.syncPolicy`

Controls **when and how** ArgoCD syncs.

```yaml
syncPolicy:
  automated:
    prune: true       # delete resources that exist in cluster but not in Git
    selfHeal: true    # re-apply if someone manually changes cluster state
  syncOptions:
    - CreateNamespace=true          # auto-create destination namespace
    - PrunePropagationPolicy=foreground
    - ApplyOutOfSyncOnly=true       # only apply resources that are out-of-sync
    - ServerSideApply=true          # use server-side apply instead of client-side
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

### `automated`

| Field | Default | Meaning |
|-------|---------|--------|
| `prune` | `false` | If `true`, resources removed from Git are **deleted** from the cluster. If `false`, they are left orphaned (OutOfSync). |
| `selfHeal` | `false` | If `true`, ArgoCD will revert any manual changes to the cluster back to what Git says within ~3 minutes. This enforces Git as the only source of truth. |

> If `automated` is **not** set, ArgoCD runs in **manual sync mode** — it detects drift but takes no automatic action. You must click Sync or run `argocd app sync <name>`.

### `syncOptions` (notable ones)

| Option | Effect |
|--------|--------|
| `CreateNamespace=true` | ArgoCD creates the destination namespace if it does not exist |
| `ApplyOutOfSyncOnly=true` | Only applies resources that are actually out-of-sync (faster for large apps) |
| `ServerSideApply=true` | Uses Kubernetes server-side apply (recommended for large/complex CRDs) |
| `PruneLast=true` | Deletes pruned resources **after** all other resources are synced (safer) |
| `RespectIgnoreDifferences=true` | Applies the `ignoreDifferences` rules during sync, not just during diff display |

---

## `spec.ignoreDifferences`

Tells ArgoCD to ignore certain fields when calculating sync status. Useful for fields that the cluster mutates (e.g., `replicas` managed by HPA).

```yaml
ignoredDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
      - /spec/replicas       # ignore replica count (managed by HPA)
  - group: ""
    kind: Secret
    jsonPointers:
      - /data                # ignore secret data (managed externally)
```

---

## `spec.revisionHistoryLimit`

How many old sync revisions to keep (default: `10`). Useful for audit trails and rollback.

```yaml
revisionHistoryLimit: 5
```

---

## Complete Reference Skeleton

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <app-name>
  namespace: argocd
  labels:
    team: platform
  annotations:
    argocd.argoproj.io/sync-wave: "2"
  finalizers:
    - resources-finalizer.argocd.argoproj.io   # cascade delete
spec:
  project: default

  # --- SINGLE SOURCE ---
  source:
    repoURL: <git-repo-url>
    targetRevision: <branch|tag|SHA>  # e.g. HEAD, main, v1.2.3
    path: <path-in-repo>              # e.g. apps/frontend
    # helm:                           # only if Helm
    #   valueFiles: [values.yaml]
    # kustomize:                      # only if Kustomize
    #   images: [myapp=myapp:1.0.0]

  # --- OR MULTI-SOURCE (ArgoCD v2.6+, mutually exclusive with 'source') ---
  # sources:
  #   - repoURL: ...
  #     chart: ...
  #     targetRevision: ...
  #   - repoURL: ...
  #     targetRevision: HEAD
  #     ref: values

  destination:
    server: https://kubernetes.default.svc   # in-cluster
    namespace: <target-namespace>

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 1m

  revisionHistoryLimit: 10

  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas
```
