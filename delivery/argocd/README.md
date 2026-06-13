# ArgoCD

ArgoCD is a **declarative, GitOps-based Continuous Delivery (CD) tool for Kubernetes**. It continuously monitors a Git repository and reconciles the live state of your cluster with the desired state declared in Git.

## Why ArgoCD Exists

Traditional CI/CD pipelines push changes imperatively (`kubectl apply`, `helm upgrade`). ArgoCD flips this model:

- Git is the **single source of truth** for what should run in the cluster
- ArgoCD **pulls** the desired state from Git and applies it automatically
- Any drift between Git and the cluster is detected and (optionally) auto-corrected

## Folder Structure

| File | What It Covers |
|------|----------------|
| `argocd-guide.md` | Core concepts: architecture, components, how ArgoCD works end-to-end |
| `application.md` | Deep dive into the `Application` CRD — every field explained |
| `sync-strategies.md` | Sync policies, automation, image updater, multi-source, and GitOps repo patterns |
| `quick-ref.md` | Cheat sheet — install command, key CLI commands, manifest skeletons |

## Where ArgoCD Fits in the Big Picture

```
Developer
   │
   ▼
Source Code Repo  ──► CI Pipeline (build, test, push image)
                                        │
                                        ▼
                          CD Manifests Repo (Helm / Kustomize / plain YAML)
                                        │
                                        ▼  (ArgoCD watches this repo)
                                   ArgoCD
                                        │
                                        ▼
                              Kubernetes Cluster
```

ArgoCD lives between the **CD manifests repo** and the **cluster**. It does NOT build images — that is CI's job.
