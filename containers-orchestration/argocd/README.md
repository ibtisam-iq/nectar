# ArgoCD

ArgoCD is a **declarative, GitOps-based Continuous Delivery tool for Kubernetes**. It watches a Git repository and ensures the live state of a Kubernetes cluster always matches the desired state declared in that repository.

## Where It Fits in the DevSecOps Pipeline

```
Developer  →  Source Repo (CI)  →  Image Registry (GHCR)
                                        │
                    CD Repo (manifests) ←┘  (CI writes image tag here)
                          │
                       ArgoCD  →  Kubernetes Cluster
```

- **CI** (GitHub Actions) builds, scans, and pushes images.
- **CI** also updates the CD repo with the new image tag (via `reusable-gitops.yaml`).
- **ArgoCD** continuously watches the CD repo and reconciles the cluster state.
- You never run `kubectl apply` manually in production — ArgoCD does it.

## Why ArgoCD Over Plain `kubectl apply`?

| Problem with manual apply | How ArgoCD solves it |
|---|---|
| No audit trail of who applied what | Every change is a Git commit — full history |
| Drift: cluster diverges from repo over time | Self-heal detects and corrects drift automatically |
| Rollback requires finding old manifests | `git revert` + ArgoCD syncs instantly |
| No visibility into sync state | ArgoCD UI and CLI show exact diff between desired and live |
| Multi-service deploys are not atomic | ArgoCD sync waves coordinate ordering |

## Key Concepts

| Term | Meaning |
|---|---|
| **Application** | The core ArgoCD CRD. Defines source (Git), destination (cluster + namespace), and sync policy. |
| **Sync** | The act of applying Git state to the cluster. Can be manual or automatic. |
| **Drift** | When the live cluster state diverges from what Git says it should be. |
| **Self-Heal** | ArgoCD automatically resyncs when drift is detected. |
| **Prune** | Delete resources from the cluster that have been removed from Git. |
| **Health Status** | ArgoCD evaluates if deployed resources are actually healthy (Running, not just applied). |
| **Image Updater** | An ArgoCD add-on that watches an image registry and updates image tags in the CD repo automatically. |

## Files in This Folder

| File | Purpose |
|---|---|
| `argocd-guide.md` | Full theory: architecture, Application manifest deep dive, sync policies, detection modes, Image Updater |
| `quick-ref.md` | Cheat sheet — all Application YAML fields, sync options, annotations |
