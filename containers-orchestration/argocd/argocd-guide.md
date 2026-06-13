# ArgoCD — Complete Theory Guide

## 1. What is GitOps?

GitOps is a way of operating Kubernetes where **Git is the single source of truth** for the desired state of the system. Any change to the cluster must first be a commit in Git. ArgoCD is the reconciliation engine that enforces this contract.

The four principles of GitOps:
1. **Declarative** — the entire system is described declaratively.
2. **Versioned and immutable** — desired state is stored in Git with a full audit trail.
3. **Pulled automatically** — approved changes are applied automatically by a software agent (ArgoCD).
4. **Continuously reconciled** — software agents continuously compare desired vs actual state and self-heal.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────┐
│                  Kubernetes Cluster              │
│                                                 │
│  ┌────────────────────────────────────────────┐ │
│  │              argocd namespace               │ │
│  │                                            │ │
│  │  argocd-server          (UI + API)         │ │
│  │  argocd-repo-server     (Git clone/render) │ │
│  │  argocd-application-controller  (reconcile)│ │
│  │  argocd-dex-server      (SSO/OIDC)         │ │
│  │  argocd-redis           (cache)            │ │
│  └────────────────────────────────────────────┘ │
│                                                 │
│  ┌──────────────┐   ┌──────────────────────┐   │
│  │  App NS 1    │   │  App NS 2            │   │
│  │  (boutique)  │   │  (monitoring)        │   │
│  └──────────────┘   └──────────────────────┘   │
└─────────────────────────────────────────────────┘
          ▲                        ▲
          │ git pull (poll/webhook)│
          │                        │
   ┌──────┴──────┐         ┌───────┴──────┐
   │  Source Repo│         │   CD Repo    │
   │  (app code) │         │  (manifests) │
   └─────────────┘         └─────────────┘
```

### Core Components

| Component | Role |
|---|---|
| **argocd-application-controller** | The brain. Watches Application CRDs, polls Git, compares live vs desired state, triggers syncs. |
| **argocd-repo-server** | Clones the Git repo, renders manifests (Helm template / Kustomize build / plain YAML), returns rendered YAML to the controller. |
| **argocd-server** | Hosts the web UI and the gRPC/REST API. The `argocd` CLI talks to this. |
| **argocd-dex-server** | Optional SSO provider. Delegates authentication to GitHub, LDAP, OIDC providers. |
| **argocd-redis** | In-memory cache for rendered manifests and app state. Speeds up re-renders. |

---

## 3. Installation on Bare-Metal (Helm)

```bash
# Add the ArgoCD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install into a dedicated namespace
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version 7.x.x

# Retrieve the initial admin password
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath='{.data.password}' | base64 -d
```

On bare-metal there is no cloud LoadBalancer, so the `argocd-server` service stays `<pending>`. Patch it to NodePort or use port-forward for initial access:

```bash
kubectl patch svc argocd-server -n argocd \
  -p '{"spec":{"type":"NodePort"}}'

# Or port-forward for quick access
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

## 4. The Application CRD

The `Application` is the **central object in ArgoCD**. It is a Kubernetes Custom Resource (`kind: Application`) that tells ArgoCD:
- **Where** to get the desired state (source — Git repo + path).
- **Where** to deploy it (destination — cluster + namespace).
- **How** to keep it in sync (sync policy).

### Minimal Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: boutique-app
  namespace: argocd          # Application object always lives in argocd namespace
spec:
  project: default
  source:
    repoURL: https://github.com/ibtisam-iq/platform-engineering-systems.git
    targetRevision: HEAD
    path: systems/microservices-demo
  destination:
    server: https://kubernetes.default.svc   # in-cluster
    namespace: boutique-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 5. `spec.source` — Single Source (Deep Dive)

The `source` block tells ArgoCD where to find the manifests.

```yaml
spec:
  source:
    repoURL: https://github.com/org/cd-repo.git   # MANDATORY: Git repo URL
    targetRevision: HEAD                           # MANDATORY: branch, tag, or commit SHA
    path: systems/microservices-demo               # MANDATORY: folder inside the repo
```

### `targetRevision` Values

| Value | Meaning |
|---|---|
| `HEAD` | Always tracks the default branch tip. Changes on push. |
| `main` | Explicitly tracks the `main` branch. |
| `v1.2.3` | Pins to a specific tag. Immutable reference. |
| `abc1234` | Pins to a specific commit SHA. Fully immutable. |

### Auto-Detection: What ArgoCD Finds in `path`

ArgoCD inspects the folder at `path` and **automatically chooses the rendering engine**:

| File found in `path` | Engine used | How it renders |
|---|---|---|
| `Chart.yaml` | **Helm** | `helm template` — renders all templates with values |
| `kustomization.yaml` | **Kustomize** | `kustomize build` — builds the kustomization |
| Plain `*.yaml` files (no above) | **Directory** | `kubectl apply -f` — applies files as-is |

You do **not** need to specify the engine — ArgoCD detects it automatically. This is one of ArgoCD's most elegant design decisions.

### Helm-Specific Source Options

When ArgoCD detects Helm, extra options become available:

```yaml
spec:
  source:
    repoURL: https://github.com/org/cd-repo.git
    targetRevision: HEAD
    path: charts/boutique
    helm:
      releaseName: boutique-app          # override helm release name
      valueFiles:
        - values.yaml
        - values-prod.yaml               # merge multiple value files
      parameters:
        - name: image.tag
          value: sha-abc1234             # override a specific value
```

### Kustomize-Specific Source Options

```yaml
spec:
  source:
    repoURL: https://github.com/org/cd-repo.git
    targetRevision: HEAD
    path: overlays/production
    kustomize:
      images:
        - ghcr.io/org/app:sha-abc1234   # override image tag inline
```

> **Important — Kustomize exec plugin:** Kustomize's `exec` plugin is disabled in ArgoCD by default as a security measure. If you need it, enable it in the ArgoCD ConfigMap with `kustomize.buildOptions: --enable-exec-plugin` (use with caution in production).

---

## 6. `spec.sources` — Multiple Sources (Advanced)

ArgoCD 2.6+ supports **multiple sources** in a single Application. This is useful when your Helm chart lives in one repo and your `values.yaml` lives in another (common in large GitOps setups).

```yaml
spec:
  sources:                               # note: sources (plural), not source
    - repoURL: https://github.com/org/helm-charts.git
      targetRevision: HEAD
      path: charts/boutique
      helm:
        valueFiles:
          - $values/envs/production/values.yaml   # $values references the second source
    - repoURL: https://github.com/org/config-repo.git
      targetRevision: HEAD
      ref: values                                  # named reference for use in other sources
```

> **Note:** When using `sources` (plural), the `source` (singular) field must be omitted. They are mutually exclusive.

---

## 7. `spec.destination`

Tells ArgoCD where to deploy the rendered manifests.

```yaml
spec:
  destination:
    server: https://kubernetes.default.svc   # in-cluster (the same cluster ArgoCD runs in)
    namespace: boutique-app                  # target namespace; must exist or be created
```

### External Cluster

To deploy to a different cluster, register it with ArgoCD first:

```bash
argocd cluster add <context-name>
```

Then reference it by URL:

```yaml
destination:
  server: https://api.external-cluster.example.com:6443
  namespace: boutique-app
```

---

## 8. `spec.syncPolicy` — How ArgoCD Applies Changes

Without a sync policy, ArgoCD only **shows** that the cluster is out of sync — it does not act. The sync policy defines how ArgoCD reacts.

### Manual Sync (default — no syncPolicy)

```yaml
# No syncPolicy block = manual only
# ArgoCD shows OutOfSync status but waits for you to click "Sync" in UI or run:
# argocd app sync boutique-app
```

### Automated Sync

```yaml
spec:
  syncPolicy:
    automated:
      prune: true       # delete resources removed from Git
      selfHeal: true    # re-sync when live state drifts from Git
```

| Option | Default | What it does |
|---|---|---|
| `automated` | absent (manual) | Enables automatic sync when Git changes are detected |
| `prune: true` | `false` | Deletes Kubernetes resources that are no longer in Git. **Dangerous if left false** — orphaned resources pile up. |
| `selfHeal: true` | `false` | Re-applies Git state if someone manually edits a resource in the cluster. Enforces Git as the only source of truth. |

### Sync Options

`syncOptions` is a list of fine-grained flags applied during the sync operation:

```yaml
spec:
  syncPolicy:
    syncOptions:
      - CreateNamespace=true        # create destination namespace if it doesn't exist
      - ApplyOutOfSyncOnly=true     # only apply resources that are actually out of sync
      - ServerSideApply=true        # use kubectl server-side apply (handles large objects)
      - PrunePropagationPolicy=foreground  # how to delete child resources
      - Replace=true                # use kubectl replace instead of apply (rare)
      - RespectIgnoreDifferences=true
```

### Retry on Failure

```yaml
spec:
  syncPolicy:
    retry:
      limit: 5                 # retry up to 5 times
      backoff:
        duration: 5s           # initial backoff
        factor: 2              # exponential backoff multiplier
        maxDuration: 3m        # cap
```

---

## 9. How ArgoCD Detects Changes (Two Modes)

This is the heart of the GitOps reconciliation loop. ArgoCD has two ways of knowing something changed:

### Mode 1: Git Polling (default)

ArgoCD polls the Git repository every **3 minutes** by default. When it finds the commit SHA has changed, it re-renders the manifests and compares them to the live cluster state.

```
Every 3 min:
  git fetch origin
  if HEAD != last_seen_sha:
    render manifests
    compare vs live state
    if OutOfSync and automated: sync()
```

To reduce latency, configure a **Git webhook** so GitHub pushes a notification to ArgoCD immediately on every push:

```bash
# ArgoCD webhook endpoint
https://<argocd-server>/api/webhook

# In GitHub repo → Settings → Webhooks → Add:
# Payload URL: https://<argocd-server>/api/webhook
# Content type: application/json
# Secret: (set and configure in ArgoCD)
# Events: Just the push event
```

### Mode 2: ArgoCD Image Updater

The standard ArgoCD approach requires the CI pipeline to **write the new image tag into the CD repo** (which is what `reusable-gitops.yaml` does in this project). ArgoCD then detects the Git change and syncs.

ArgoCD Image Updater takes a different approach — it **watches the image registry directly** and bypasses the Git-write step:

```
Image Updater loop:
  poll registry (GHCR, Docker Hub, ECR...)
  if new tag matching pattern found:
    either: write updated tag to CD repo (git-write mode)
    or:     patch the running Deployment directly (direct mode — not GitOps!)
```

#### Installation

```bash
helm install argocd-image-updater \
  argo/argocd-image-updater \
  --namespace argocd
```

#### Configuration via Annotations on the Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: boutique-app
  namespace: argocd
  annotations:
    # Which images to track
    argocd-image-updater.argoproj.io/image-list: |
      frontend=ghcr.io/ibtisam-iq/microservices-demo/frontend

    # Tag update strategy: semver, latest, name, digest, or a custom regex
    argocd-image-updater.argoproj.io/frontend.update-strategy: name

    # Filter tags by pattern (only track sha- prefixed tags)
    argocd-image-updater.argoproj.io/frontend.allow-tags: regexp:^sha-[a-f0-9]{7}$

    # Write mode: git (update CD repo and commit), or argocd (patch app directly)
    argocd-image-updater.argoproj.io/write-back-method: git

    # Branch to commit the updated tag to
    argocd-image-updater.argoproj.io/git-branch: main
```

#### Git-Write Mode vs Direct Mode

| Mode | How it works | GitOps? |
|---|---|---|
| `git` (write-back) | Image Updater commits the new tag to the CD repo → ArgoCD detects the Git change → syncs | ✅ Yes — Git remains source of truth |
| `argocd` (direct) | Image Updater patches the Application object or Deployment directly, bypassing Git | ❌ No — Git is stale, not source of truth |

**Always prefer `git` write-back mode** for a proper GitOps setup.

---

## 10. `spec.project`

Applications are organized into **AppProjects**. The `default` project allows deploying to any cluster and any namespace. For production, create scoped projects:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: microservices
  namespace: argocd
spec:
  description: Online Boutique microservices
  sourceRepos:
    - https://github.com/ibtisam-iq/platform-engineering-systems.git
  destinations:
    - namespace: boutique-app
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: ''
      kind: Namespace
```

---

## 11. Health Status vs Sync Status

These are two independent status fields on every Application — a common source of confusion.

| Status Type | Meaning | Possible Values |
|---|---|---|
| **Sync Status** | Does live state match Git? | `Synced`, `OutOfSync`, `Unknown` |
| **Health Status** | Are the deployed resources actually healthy? | `Healthy`, `Progressing`, `Degraded`, `Suspended`, `Missing`, `Unknown` |

An app can be `Synced` but `Degraded` — meaning ArgoCD applied exactly what Git said, but the Pods are crashing. Always check both.

---

## 12. The Two-Repo Pattern (This Project)

This project uses the standard industry pattern:

```
microservices-demo (source repo)
  └── src/
      ├── frontend/
      ├── cartservice/
      └── ...
      CI pushes new images → GHCR

platform-engineering-systems (CD repo)
  └── systems/microservices-demo/src/
      ├── frontend/image.env     ← CI writes IMAGE_TAG=sha-abc1234
      ├── cartservice/image.env
      └── ...
      ArgoCD watches this repo
```

**Data flow on every code push:**

```
1. Developer pushes to main
2. CI (reusable-build.yaml) builds image → pushes to GHCR with :sha-abc1234
3. CI (reusable-gitops.yaml) writes sha-abc1234 to CD repo (image.env)
4. ArgoCD detects CD repo changed (polling or webhook)
5. ArgoCD re-renders manifests (Helm reads image.env values)
6. ArgoCD syncs → kubectl applies updated Deployment to cluster
7. Kubernetes rolls out new Pods
```

---

## 13. Ignoring Differences

Sometimes certain fields in the live cluster are managed by other controllers (e.g., HPA modifies `replicas`, cert-manager injects annotations). Tell ArgoCD to ignore these to prevent constant OutOfSync:

```yaml
spec:
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas             # managed by HPA
    - group: ""
      kind: ServiceAccount
      jsonPointers:
        - /secrets                   # injected by Kubernetes
```

---

## 14. Sync Waves and Hooks

For ordered deployments (e.g., run DB migrations before app, create namespace before deploying into it), use sync waves and hooks.

### Sync Waves

Resources with a lower wave number are applied first. ArgoCD waits for them to become healthy before proceeding.

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"   # runs before wave 2, 3, etc.
```

### Resource Hooks

```yaml
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync        # runs before main sync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
```

| Hook | When it runs |
|---|---|
| `PreSync` | Before any resources are applied |
| `Sync` | During the sync alongside regular resources |
| `PostSync` | After all resources are healthy |
| `SyncFail` | Only when the sync fails (useful for rollback jobs) |
