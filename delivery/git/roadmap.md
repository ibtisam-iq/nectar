# Roadmap

Progress tracker for the Git folder. Each topic, scenario and lab is checked off as it is written to the standard. Modules are built in batches; this page fills in as each batch lands.

---

## 00 Foundations

| Topic | Track | Weight | Done |
|---|---|---|---|
| [What Is Git](00-foundations/what-is-git.md) | Core | Med | [x] |
| [Install and Config](00-foundations/install-and-config.md) | Core | Med | [x] |
| [The Three Trees](00-foundations/the-three-trees.md) | Core | High | [x] |

---

## 01 Core Workflow

| Topic | Track | Weight | Done |
|---|---|---|---|
| [Staging and Committing](01-core-workflow/staging-and-committing.md) | Core | High | [x] |
| [Inspecting History](01-core-workflow/inspecting-history.md) | Core | High | [x] |
| [Ignoring and Attributes](01-core-workflow/ignoring-and-attributes.md) | Core | Med | [x] |
| [Undoing Changes](01-core-workflow/undoing-changes.md) | Core | High | [x] |

---

## 02 Branching and Merging

| Topic | Track | Weight | Done |
|---|---|---|---|
| [Branches](02-branching-and-merging/branches.md) | Core | High | [x] |
| [Merging](02-branching-and-merging/merging.md) | Core | High | [x] |
| [Rebasing](02-branching-and-merging/rebasing.md) | Core | High | [x] |
| [Interactive Rebase](02-branching-and-merging/interactive-rebase.md) | Advanced | High | [x] |
| [Conflict Resolution](02-branching-and-merging/conflict-resolution.md) | Core | High | [x] |
| [Cherry-Pick](02-branching-and-merging/cherry-pick.md) | Core | Med | [x] |

---

## 03 Remotes and Collaboration

| Topic | Track | Weight | Done |
|---|---|---|---|
| [Remotes](03-remotes-and-collaboration/remotes.md) | Core | High | [x] |
| [Pushing and Pulling](03-remotes-and-collaboration/pushing-and-pulling.md) | Core | High | [x] |
| [Tags and Releases](03-remotes-and-collaboration/tags-and-releases.md) | Core | Med | [x] |
| [Stashing](03-remotes-and-collaboration/stashing.md) | Core | Med | [x] |
| [Forks and Pull Requests](03-remotes-and-collaboration/forks-and-pull-requests.md) | Workflow | Med | [x] |

---

## 04 Team Workflows

| Topic | Track | Weight | Done |
|---|---|---|---|
| [Branching Strategies](04-team-workflows/branching-strategies.md) | Workflow | High | [x] |
| [Commit Conventions](04-team-workflows/commit-conventions.md) | Workflow | High | [x] |
| [Code Review with Git](04-team-workflows/code-review-with-git.md) | Workflow | Med | [x] |
| [Release and Versioning](04-team-workflows/release-and-versioning.md) | Workflow | Med | [x] |

---

## 05 History and Recovery

| Topic | Track | Weight | Done |
|---|---|---|---|
| [Reflog and Recovery](05-history-and-recovery/reflog-and-recovery.md) | Core | High | [x] |
| [Bisect](05-history-and-recovery/bisect.md) | Advanced | Med | [x] |
| [Rewriting History](05-history-and-recovery/rewriting-history.md) | Advanced | High | [x] |
| [Filter-Repo and Secrets](05-history-and-recovery/filter-repo-and-secrets.md) | Advanced | Med | [x] |

---

## 06 Internals

| Topic | Track | Weight | Done |
|---|---|---|---|
| [Object Model](06-internals/object-model.md) | Advanced | High | [x] |
| [Refs and HEAD](06-internals/refs-and-head.md) | Advanced | High | [x] |
| [How Merge and Rebase Work](06-internals/how-merge-and-rebase-work.md) | Advanced | High | [x] |
| [Packfiles and GC](06-internals/packfiles-and-gc.md) | Advanced | Low | [x] |

---

## 07 Advanced Tooling

| Topic | Track | Weight | Done |
|---|---|---|---|
| [Hooks](07-advanced-tooling/hooks.md) | Advanced | Med | [x] |
| [Submodules](07-advanced-tooling/submodules.md) | Advanced | Med | [x] |
| [Worktrees](07-advanced-tooling/worktrees.md) | Advanced | Low | [x] |
| [Large Repos](07-advanced-tooling/large-repos.md) | Advanced | Med | [x] |
| [Credentials and Signing](07-advanced-tooling/credentials-and-signing.md) | Core | Med | [x] |

---

## Scenarios

| Scenario | Modules | Done |
|---|---|---|
| [Accidental Commit to Main](interview/scenarios/accidental-commit-to-main.md) | 01, 02 | [x] |
| [Wrong-Branch Commits](interview/scenarios/wrong-branch-commits.md) | 01, 02 | [x] |
| [Merge Conflict Resolution](interview/scenarios/merge-conflict-resolution.md) | 02 | [x] |
| [Detached HEAD](interview/scenarios/detached-head.md) | 02 | [x] |
| [Diverged Branches, Push Rejected](interview/scenarios/diverged-branches-push-rejected.md) | 03 | [x] |
| [Messy History Before a PR](interview/scenarios/messy-history-before-pr.md) | 02, 04 | [x] |
| [Lost Commits After Reset](interview/scenarios/lost-commits-after-reset.md) | 05 | [x] |
| [Committed a Secret](interview/scenarios/committed-a-secret.md) | 05 | [x] |
| [Force-Push Clobbered a Teammate](interview/scenarios/force-push-clobbered-teammate.md) | 03, 05 | [x] |
| [Bloated Repo, Large File](interview/scenarios/bloated-repo-large-file.md) | 07 | [x] |

---

## Labs

| Lab | Modules | Done |
|---|---|---|
| [Core Workflow Lab](labs/core-workflow-lab.md) | 00, 01 | [x] |
| [Branching and Rebase Lab](labs/branching-and-rebase-lab.md) | 02, 04 | [x] |
| [Recovery and Bisect Lab](labs/recovery-and-bisect-lab.md) | 05 | [x] |

---

## Upcoming Modules

Built in later batches, in this order:

- The reference pages (`cheatsheet`, `command-index`, `config-reference`, `dotfiles-reference`, `glossary`)
- The remaining labs (`internals-by-hand`, `history-surgery`)
