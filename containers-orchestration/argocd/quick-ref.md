# ArgoCD — Quick Reference

## Application Manifest — Full Structure

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <app-name>               # Name of the Application object
  namespace: argocd              # Always argocd — where Application CRDs live
  labels:
    app.kubernetes.io/name: <app-name>
  annotations:
    # Image Updater annotations (if used) go here — see argocd-guide.md §9

spec:
  project: default               # AppProject name; default allows everything

  # ── SINGLE SOURCE ──────────────────────────────────────────────────────────
  source:
    repoURL: https://github.com/org/repo.git   # Git repo URL
    targetRevision: HEAD                        # branch / tag / commit SHA
    path: path/to/manifests                     # folder inside the repo

    # Helm options (only when Chart.yaml is detected)
    helm:
      releaseName: my-release
      valueFiles:
        - values.yaml
        - values-prod.yaml
      parameters:
        - name: image.tag
          value: sha-abc1234

    # Kustomize options (only when kustomization.yaml is detected)
    kustomize:
      images:
        - ghcr.io/org/app:sha-abc1234

  # ── MULTIPLE SOURCES (ArgoCD 2.6+, mutually exclusive with source) ─────────
  # sources:
  #   - repoURL: https://github.com/org/charts.git
  #     targetRevision: HEAD
  #     path: charts/myapp
  #     helm:
  #       valueFiles:
  #         - $values/envs/prod/values.yaml
  #   - repoURL: https://github.com/org/config.git
  #     targetRevision: HEAD
  #     ref: values

  # ── DESTINATION ─────────────────────────────────────────────────────────────
  destination:
    server: https://kubernetes.default.svc   # in-cluster; use URL for remote cluster
    namespace: my-app-namespace

  # ── SYNC POLICY ─────────────────────────────────────────────────────────────
  syncPolicy:
    automated:
      prune: true        # delete resources removed from Git
      selfHeal: true     # re-sync when cluster drifts from Git
    syncOptions:
      - CreateNamespace=true         # create namespace if missing
      - ApplyOutOfSyncOnly=true      # skip already-synced resources
      - ServerSideApply=true         # use server-side apply
      - PrunePropagationPolicy=foreground
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m

  # ── IGNORE DIFFERENCES ──────────────────────────────────────────────────────
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas             # ignore HPA-managed replica count
```

---

## Auto-Detection Logic (What ArgoCD Looks for in `path`)

```
path/
├── Chart.yaml          → Helm   (helm template)
├── kustomization.yaml  → Kustomize (kustomize build)
└── *.yaml only         → Directory (kubectl apply -f)
```

Only **one engine** is active per path. ArgoCD picks automatically.

---

## `targetRevision` Cheat Sheet

| Value | Tracks | Mutable? |
|---|---|---|
| `HEAD` | Default branch tip | ✅ Changes on every push |
| `main` | `main` branch tip | ✅ Changes on every push |
| `v1.2.3` | A specific tag | ❌ Immutable |
| `abc1234f` | A specific commit | ❌ Fully immutable |

---

## Sync Status vs Health Status

| | Synced | OutOfSync |
|---|---|---|
| **Healthy** | ✅ All good | Git has changes not yet applied |
| **Progressing** | Rolling out | Rollout in progress |
| **Degraded** | Applied correctly but Pods crashing | Both problems at once |
| **Missing** | Resources missing from cluster | Resources missing + Git has changes |

---

## Sync Options Reference

| Option | Effect |
|---|---|
| `CreateNamespace=true` | Auto-create destination namespace |
| `ApplyOutOfSyncOnly=true` | Only touch resources that differ |
| `ServerSideApply=true` | Use server-side apply (handles CRDs, large annotations) |
| `Replace=true` | Use `kubectl replace` instead of apply |
| `PruneLast=true` | Prune deleted resources after new ones are healthy |
| `PrunePropagationPolicy=foreground` | Wait for child resources to delete before parent |
| `RespectIgnoreDifferences=true` | Apply ignoreDifferences during sync too |

---

## Resource Hooks

```yaml
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync      # PreSync | Sync | PostSync | SyncFail
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
    argocd.argoproj.io/sync-wave: "-1"    # negative = earlier wave
```

---

## Image Updater Annotations (on Application)

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: |
    alias=ghcr.io/org/repo/service
  argocd-image-updater.argoproj.io/alias.update-strategy: name
  argocd-image-updater.argoproj.io/alias.allow-tags: regexp:^sha-[a-f0-9]{7}$
  argocd-image-updater.argoproj.io/write-back-method: git
  argocd-image-updater.argoproj.io/git-branch: main
```

---

## CLI Quick Reference

```bash
# Login
argocd login <argocd-server> --username admin --password <pass>

# List apps
argocd app list

# Get app status
argocd app get <app-name>

# Manually sync
argocd app sync <app-name>

# Hard refresh (re-clone Git, bypass cache)
argocd app get <app-name> --hard-refresh

# Rollback to previous deployed version
argocd app rollback <app-name> <history-id>

# Get rollout history
argocd app history <app-name>

# Delete app (does NOT delete cluster resources by default)
argocd app delete <app-name>

# Delete app AND cluster resources
argocd app delete <app-name> --cascade
```

---

## Common Errors and Fixes

| Error | Cause | Fix |
|---|---|---|
| `ComparisonError: failed to load target state` | ArgoCD can't render manifests | Check path, targetRevision, and Helm/Kustomize syntax |
| Service stays `<pending>` EXTERNAL-IP | No cloud LB on bare-metal | Patch to NodePort or use MetalLB |
| App `OutOfSync` immediately after sync | `ignoreDifferences` not set for controller-managed fields | Add `ignoreDifferences` for HPA replicas, injected secrets etc. |
| Kustomize exec plugin disabled | Security default | Add `--enable-exec-plugin` to `kustomize.buildOptions` in ArgoCD CM |
| Image Updater not writing back | Wrong `write-back-method` or missing Git credentials | Set `write-back-method: git` and create `argocd-image-updater-secret` |
