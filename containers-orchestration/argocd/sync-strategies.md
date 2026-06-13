# Sync Strategies, GitOps Repo Patterns & Image Updater

---

## The Two GitOps Repo Patterns

In real-world GitOps, there are always **two repositories**:

| Repo | Contains | Updated by |
|------|----------|------------|
| **Source / App Repo** | Application source code (Go, Python, Node, etc.) | Developers (feature branches, PRs) |
| **CD / Config Repo** | Kubernetes manifests (Helm charts, Kustomize overlays, plain YAML) | CI pipeline or image updater |

ArgoCD only ever watches the **CD / Config Repo** — it does not care about source code.

```
Source Repo ──► CI (build + push image) ──► CD Repo ──► ArgoCD ──► Cluster
```

---

## Sync Strategy 1 — Manifest-Based (Git-Driven)

**How it works:**

1. CI builds a new Docker image and pushes it to a registry
2. CI (or a bot) **updates the CD repo** — either:
   - Changes the image tag directly in a manifest YAML
   - Updates an `image.env` / `IMAGE_TAG` variable file that the manifest references
   - Bumps `values.yaml` (for Helm) or `kustomization.yaml` image field (for Kustomize)
3. ArgoCD detects the Git change (polling every 3 min, or instant via webhook)
4. ArgoCD applies the updated manifests to the cluster

**Pros:** Full audit trail in Git. Every deployment is a Git commit. Easy rollback (revert commit).

**Example — Kustomize image update in CI:**
```bash
# In CI pipeline after building image:
cd cd-repo/overlays/production
kustomize edit set image myapp=myregistry.io/myapp:${GIT_SHA}
git commit -am "chore: update myapp image to ${GIT_SHA}"
git push
# ArgoCD picks this up and syncs automatically
```

**Example — Helm values update in CI:**
```bash
# Using yq to update image tag in values.yaml
yq e '.image.tag = strenv(IMAGE_TAG)' -i values-prod.yaml
git commit -am "chore: bump image tag to ${IMAGE_TAG}"
git push
```

---

## Sync Strategy 2 — Image Updater (Registry-Driven)

**How it works:**

1. CI builds and pushes a new image to a container registry
2. **ArgoCD Image Updater** (a separate component installed alongside ArgoCD) watches the registry for new image tags
3. When a new tag matching a pattern appears, Image Updater:
   - Option A: **commits the updated tag back to Git** (write-back to CD repo)
   - Option B: **updates the ArgoCD Application in-memory** (no Git commit, less audit trail)
4. ArgoCD picks up the change and syncs

**No one manually updates the CD repo** — the image updater does it.

### Installing ArgoCD Image Updater

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
```

### Annotating the Application for Image Updater

Image Updater is annotation-driven on the `Application` CR:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  annotations:
    # Tell image updater which images to watch
    argocd-image-updater.argoproj.io/image-list: myapp=myregistry.io/myapp

    # Update strategy: semver, latest, digest, name
    argocd-image-updater.argoproj.io/myapp.update-strategy: semver

    # Write-back to Git (recommended for audit trail)
    argocd-image-updater.argoproj.io/write-back-method: git
    argocd-image-updater.argoproj.io/git-branch: main

    # For Kustomize: which image name to update
    argocd-image-updater.argoproj.io/myapp.kustomize.image-name: myregistry.io/myapp
```

### Update Strategies

| Strategy | Behavior |
|----------|----------|
| `semver` | Update to the newest tag that satisfies a semver constraint (e.g. `~1.2`) |
| `latest` | Always use the most recently pushed tag |
| `digest` | Track a specific tag (e.g. `latest`) by its immutable digest |
| `name` | Alphabetically newest tag |

---

## Sync Waves & Hooks — Ordering Within a Sync

ArgoCD lets you control the **order** in which resources are applied during a sync.

### Sync Waves

Annotate resources with a wave number. Lower numbers sync first.

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # sync this before wave 2, 3, etc.
```

Typical ordering:
- Wave 0: Namespaces, CRDs
- Wave 1: RBAC, ConfigMaps, Secrets
- Wave 2: Databases, StatefulSets
- Wave 3: Application Deployments
- Wave 4: Ingress, Services

### Sync Hooks

Special jobs/pods that run at specific points in the sync lifecycle:

| Hook | When it runs |
|------|-------------|
| `PreSync` | Before any resources are applied |
| `Sync` | During the sync, in wave order |
| `PostSync` | After all resources are Healthy |
| `SyncFail` | If the sync fails |

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
        - name: migrate
          image: myapp:latest
          command: ["python", "manage.py", "migrate"]
      restartPolicy: Never
```

---

## ApplicationSet — Generating Many Applications

`ApplicationSet` is ArgoCD's way to **templated generate multiple Application objects** from a single manifest. Common use-cases:

- Deploy the same app to 10 clusters
- Deploy every microservice from a monorepo
- Deploy per-environment (dev, staging, prod) from a single template

### List Generator Example

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: microservices
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - app: frontend
            namespace: prod-frontend
          - app: backend
            namespace: prod-backend
          - app: worker
            namespace: prod-worker
  template:
    metadata:
      name: '{{app}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/my-org/cd-repo
        targetRevision: HEAD
        path: 'apps/{{app}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

### Git Generator Example (auto-discover apps from folders)

```yaml
generators:
  - git:
      repoURL: https://github.com/my-org/cd-repo
      revision: HEAD
      directories:
        - path: apps/*   # creates one Application per subdirectory
```

---

## Health Checks

ArgoCD has **built-in health checks** for native Kubernetes resources:

| Resource | Healthy when |
|----------|--------------|
| `Deployment` | `availableReplicas >= minReadyReplicas` |
| `StatefulSet` | All replicas ready |
| `DaemonSet` | All desired pods ready |
| `Pod` | Phase = Running, all containers ready |
| `Service` | Always healthy (unless `LoadBalancer` with no IP assigned) |
| `Ingress` | Always healthy |

Custom health checks can be written in **Lua** and registered in `argocd-cm`.

---

## Rollback

ArgoCD keeps a history of syncs (`revisionHistoryLimit`).

```bash
# View history
argocd app history my-app

# Roll back to revision 3
argocd app rollback my-app 3
```

> Note: Rolling back while `automated.selfHeal: true` is enabled will cause ArgoCD to immediately re-sync forward again. Disable selfHeal or pause the app before rolling back.

```bash
# Pause auto-sync before rolling back
argocd app patch my-app --patch '{"spec":{"syncPolicy":null}}' --type merge
```
