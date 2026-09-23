# Git

Git version control in depth, organised so one folder serves four uses: learning a topic, revising before an interview, practising interview rounds, and day-to-day lookup. This folder is being rebuilt to the Nectar writing standard one module batch at a time; the module map below fills in as batches land.

---

## How the Folder Works

| Layer | Where | Use it for |
|---|---|---|
| **Learn** | Numbered module folders, one focused file per topic | Depth and daily lookup |
| **Revise** | Each module's Revision Card, and [Must-Know Facts](reference/must-know-facts.md) | The night before, or a one-hour sweep |
| **Interview** | Checkpoints at the end of every topic, and [Interview](interview/README.md) | Round-by-round preparation |
| **Practice** | [Labs](labs/README.md), and the [Roadmap](roadmap.md) tracker | Hands-on repetition |

Every topic file declares a **Track** (Core, Workflow, Advanced) and an **Interview weight** (High, Med, Low). High-weight topics go deep; Low-weight topics stay short. Command output on these pages was captured from real Git runs, never written by hand.

---

## Modules

| # | Module | Covers |
|---|---|---|
| 00 | [Foundations](00-foundations/README.md) | What Git is, install and config, the three trees |
| 01 | [Core Workflow](01-core-workflow/README.md) | Staging, history, ignoring, undoing changes |
| 02 | [Branching and Merging](02-branching-and-merging/README.md) | Branches, merge, rebase, interactive rebase, conflicts, cherry-pick |
| 03 | Remotes and Collaboration | Remotes, push and pull, tags, stashing, forks (batch B) |
| 04 | Team Workflows | Branching strategies, commit conventions, reviews, releases (batch C) |
| 05 | History and Recovery | Reflog, bisect, rewriting history, secrets (batch D) |
| 06 | Internals | Object model, refs and HEAD, packfiles (batch D) |
| 07 | Advanced Tooling | Hooks, submodules, worktrees, large repos, signing (batch E) |

Modules 00, 01 and 02 are complete. The other modules are built in the batches noted above.

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

## Study Paths

| Time available | Path |
|---|---|
| 15 minutes | [Must-Know Facts](reference/must-know-facts.md), read once |
| 1 hour | Must-Know Facts, then [Round 1](interview/round-1-screening.md) aloud, then one scenario |
| 1 day | Every High-weight topic's checkpoints, all scenarios, one lab |

---

## Reference

Raw source material for the rebuild is kept in `_sources/` (git-ignored, excluded from the site). `_sources/INVENTORY.md` maps every legacy topic to its new home.
