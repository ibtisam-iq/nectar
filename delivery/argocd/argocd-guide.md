# ArgoCD — Core Concepts & Architecture

## What Is ArgoCD?

ArgoCD is a **Kubernetes-native, pull-based GitOps CD controller**. It is installed inside the cluster itself and continuously reconciles cluster state with the desired state stored in a Git repository.

> **Key mental model:** ArgoCD does not *push* deployments to the cluster. It *watches* Git and *pulls* changes into the cluster automatically.

---

## Core Components

| Component | Role |
|-----------|------|
| **API Server** | gRPC/REST server; handles CLI, UI, and SSO. The brain you talk to. |
| **Repository Server** | Clones the Git repo and renders manifests (Helm template, Kustomize build, or plain YAML). Stateless. |
| **Application Controller** | Kubernetes controller that watches `Application` CRs; compares desired vs live state; triggers syncs. |
| **ApplicationSet Controller** | Generates multiple `Application` objects from templates (matrix, list, git generator). |
| **Redis** | In-memory cache for rendered manifests and app state. Speeds up reconciliation. |
| **Dex (optional)** | OIDC identity provider for SSO integration. |
| **Notifications Controller (optional)** | Sends Slack/email/webhook alerts on sync events. |

---

## How ArgoCD Works — End to End

```
1. You install ArgoCD into the cluster (via Helm or plain manifests)
2. You create an Application CR pointing to a Git repo path
3. ArgoCD's Repo Server clones that repo and renders the manifests
4. Application Controller compares rendered manifests vs live cluster objects
5. If out-of-sync:
   a. Manual sync mode  → you click Sync in UI or run `argocd app sync`
   b. Automatic sync    → ArgoCD applies the change itself
6. ArgoCD reports Health status (Healthy / Degraded / Progressing / Missing)
```

---

## Installation on Bare-Metal via Helm

```bash
# 1. Add the ArgoCD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 2. Install into argocd namespace
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace

# 3. Verify pods
kubectl get pods -n argocd
```

> On bare-metal the ArgoCD server `Service` is `ClusterIP` by default.  
> Patch it to `NodePort` or use an Ingress to expose the UI.

```bash
# Quick NodePort patch to reach the UI
kubectl patch svc argocd-server -n argocd \
  -p '{"spec":{"type":"NodePort"}}'
```

---

## Accessing the UI

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Login via CLI
argocd login <node-ip>:<nodePort> --username admin --password <password> --insecure
```

---

## Key Concepts

### Desired State vs Live State

| Term | Meaning |
|------|---------|
| **Desired State** | What is declared in Git (manifests, Helm values, Kustomize overlays) |
| **Live State** | What is actually running in the Kubernetes cluster right now |
| **Sync Status** | `Synced` = they match; `OutOfSync` = they differ |
| **Health Status** | Whether live resources are actually functioning (Pods running, Services reachable) |

### Reconciliation Loop

ArgoCD's Application Controller runs a continuous reconciliation loop (default every **3 minutes** for polling, or instantly via Git webhook). It:

1. Renders desired manifests from Git
2. Fetches live state from the Kubernetes API
3. Diffs the two
4. Takes action (sync or report OutOfSync)

### Refresh vs Sync

- **Refresh** — re-fetch from Git and re-render manifests, update the diff display. Does NOT apply anything.
- **Sync** — actually apply the diff to the cluster (`kubectl apply` under the hood).

---

## Source Detection Logic

When ArgoCD is given a `path` inside a Git repo, the **Repository Server** auto-detects the tool to use:

| File found at `path` | Tool used | How it renders |
|----------------------|-----------|----------------|
| `Chart.yaml` | **Helm** | `helm template` (or `helm upgrade --install` in server-side mode) |
| `kustomization.yaml` | **Kustomize** | `kustomize build` |
| `*.yaml` / `*.json` (plain) | **Directory** | `kubectl apply -f` equivalent |
| `jsonnet` files | **Jsonnet** | Jsonnet renderer |

> You do **not** have to declare the tool explicitly in the `Application` spec (though you can override it). ArgoCD figures it out from what files are present.

---

## RBAC & Multi-Tenancy

- ArgoCD has its own RBAC layer (`argocd-rbac-cm` ConfigMap)
- Roles: `role:admin`, `role:readonly`, custom roles
- **Projects** (`AppProject` CR) are the multi-tenancy boundary — they restrict which repos, clusters, and namespaces an Application can touch

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-a
  namespace: argocd
spec:
  sourceRepos:
    - 'https://github.com/my-org/team-a-*'
  destinations:
    - namespace: team-a-*
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: ''
      kind: Namespace
```
