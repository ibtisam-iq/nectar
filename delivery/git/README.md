# Git

Git version control in depth, organised so one folder serves four uses: learning a topic, revising before an interview, practising interview rounds, and day-to-day lookup. This folder is being rebuilt to the Nectar writing standard; modules are added in batches and the map below fills in as they land.

---

## Scope

This folder covers Git itself: the object model, the working tree, branching and merging, remotes, history rewriting, recovery, and the tooling around them. Platform features that sit on top of Git live in their own folders and are linked from the relevant topics rather than duplicated here.

---

## Out of Scope

| Topic | Where it lives |
|---|---|
| Pull requests, CODEOWNERS, branch protection | [GitHub](../github/codeowners.md) |
| CI and CD pipelines | [GitHub Actions](../github-actions/static-site-deployment.md) |
| GitOps deployment | [ArgoCD](../argocd/README.md) |
| Running Git servers and protocols | Hosting concern, not covered |
| Git as a client to other version control systems | Legacy bridges, not covered |

---

## Reference

Raw source material for the rebuild is kept in `_sources/` (git-ignored, excluded from the site). `_sources/INVENTORY.md` maps every legacy topic to its new home.
