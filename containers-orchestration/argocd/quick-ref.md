# ArgoCD — Quick Reference

## Install (Helm, Bare-Metal)

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace
```

## Expose ArgoCD Server (NodePort)

```bash
kubectl patch svc argocd-server -n argocd \
  -p '{"spec":{"type":"NodePort"}}'
```

## Get Initial Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

## CLI Login

```bash
argocd login <node-ip>:<nodePort> \
  --username admin \
  --password <password> \
  --insecure
```

---

## argocd CLI Cheat Sheet

| Command | What it does |
|---------|--------------|
| `argocd app list` | List all Applications |
| `argocd app get <name>` | Show app details (sync/health status, resources) |
| `argocd app sync <name>` | Trigger a manual sync |
| `argocd app diff <name>` | Show diff between Git desired state and live state |
| `argocd app history <name>` | List sync history |
| `argocd app rollback <name> <id>` | Roll back to a previous revision |
| `argocd app delete <name>` | Delete the Application (and optionally its resources) |
| `argocd app set <name> --sync-policy automated` | Enable auto-sync via CLI |
| `argocd repo add <url>` | Register a private Git repo |
| `argocd cluster add <context>` | Register an external cluster |

---

## Application Skeleton — Plain YAML Source

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/cd-repo
    targetRevision: HEAD
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Application Skeleton — Helm Source

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-helm-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/cd-repo
    targetRevision: HEAD
    path: charts/my-app
    helm:
      releaseName: my-app
      valueFiles:
        - values.yaml
        - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Application Skeleton — Kustomize Source

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-kustomize-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/cd-repo
    targetRevision: HEAD
    path: overlays/production
    kustomize:
      images:
        - myapp=myregistry.io/myapp:1.2.3
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Application Skeleton — Multi-Source (v2.6+)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-multi-source-app
  namespace: argocd
spec:
  project: default
  sources:
    - repoURL: https://charts.bitnami.com/bitnami
      chart: nginx
      targetRevision: 15.0.0
      helm:
        valueFiles:
          - $values/environments/prod/nginx-values.yaml
    - repoURL: https://github.com/my-org/my-values-repo
      targetRevision: HEAD
      ref: values
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## Source Auto-Detection Logic

| File present in `path` | Tool ArgoCD uses |
|------------------------|------------------|
| `Chart.yaml` | Helm |
| `kustomization.yaml` | Kustomize |
| `*.yaml` / `*.json` only | Plain directory (`kubectl apply`) |

---

## syncPolicy Fields at a Glance

| Field | Values | Effect |
|-------|--------|--------|
| `automated.prune` | `true` / `false` | Delete resources removed from Git |
| `automated.selfHeal` | `true` / `false` | Revert manual cluster changes |
| `syncOptions: CreateNamespace=true` | — | Auto-create destination namespace |
| `syncOptions: ServerSideApply=true` | — | Use server-side apply |
| `syncOptions: ApplyOutOfSyncOnly=true` | — | Skip already-synced resources |
| `retry.limit` | integer | Retry failed syncs N times |

---

## Image Updater Install

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
```

## Image Updater Annotations

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: myapp=myregistry.io/myapp
  argocd-image-updater.argoproj.io/myapp.update-strategy: semver
  argocd-image-updater.argoproj.io/write-back-method: git
  argocd-image-updater.argoproj.io/git-branch: main
```
