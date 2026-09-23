# Round 4: Internals

Senior, SRE and platform loops ask what Git stores and how a command changes it: what a commit hashes over, what a branch and `HEAD` really are, and why a design trades one property for another. Each question links to the topic file that answers it. This page grows as each module is added, and the dedicated internals module fills in the object model.

---

## Foundations

| Question | Answered in |
|---|---|
| Why does changing one old commit change the id of every commit after it? | [What Is Git](../00-foundations/what-is-git.md) |
| How does Git decide which config file a value comes from? | [Install and Config](../00-foundations/install-and-config.md) |
| What does `git commit` do to the three trees internally? | [The Three Trees](../00-foundations/the-three-trees.md) |

---

## Core Workflow

| Question | Answered in |
|---|---|
| Why does amending a commit change its SHA even if only the message changed? | [Staging and Committing](../01-core-workflow/staging-and-committing.md) |
| For `git log` and `git diff`, what do `A..B` and `A...B` each compute? | [Inspecting History](../01-core-workflow/inspecting-history.md) |
| What does the `binary` attribute actually turn off, and why does it matter for merges? | [Ignoring and Attributes](../01-core-workflow/ignoring-and-attributes.md) |
| After `git reset --hard HEAD~1`, is the discarded commit really gone? | [Undoing Changes](../01-core-workflow/undoing-changes.md) |

---

## Branching and Merging

| Question | Answered in |
|---|---|
| What actually changes on disk when you create and switch a branch? | [Branches](../02-branching-and-merging/branches.md) |
| What does the ort strategy compute during a three-way merge? | [Merging](../02-branching-and-merging/merging.md) |
| Why does rebasing change commit SHAs while merging does not? | [Rebasing](../02-branching-and-merging/rebasing.md) |
| How does autosquash know where to place a fixup commit? | [Interactive Rebase](../02-branching-and-merging/interactive-rebase.md) |
| What are the three index stages during a conflict? | [Conflict Resolution](../02-branching-and-merging/conflict-resolution.md) |
| How does cherry-pick apply a commit, and why is the result not identical? | [Cherry-Pick](../02-branching-and-merging/cherry-pick.md) |

---

## Remotes and Collaboration

| Question | Answered in |
|---|---|
| How does Git know which remote branch your local branch tracks, and where is it stored? | [Remotes](../03-remotes-and-collaboration/remotes.md) |
| How does `--force-with-lease` know the remote moved without seeing its live state? | [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md) |
| Why can an annotated tag be signed but a lightweight tag cannot? | [Tags and Releases](../03-remotes-and-collaboration/tags-and-releases.md) |
| How is a stash stored, and why can you inspect it like a commit? | [Stashing](../03-remotes-and-collaboration/stashing.md) |

---

## Team Workflows

| Question | Answered in |
|---|---|
| Why does gitflow merge a release branch into both `main` and `develop`? | [Branching Strategies](../04-team-workflows/branching-strategies.md) |
| How does release tooling derive the next version from commit messages? | [Commit Conventions](../04-team-workflows/commit-conventions.md) |
| How does `git range-diff` pair a reworked commit rather than matching by SHA? | [Code Review with Git](../04-team-workflows/code-review-with-git.md) |

---

## History and Recovery

| Question | Answered in |
|---|---|
| If `reset --hard` does not delete commits, what eventually does, and when? | [Reflog and Recovery](../05-history-and-recovery/reflog-and-recovery.md) |
| How does `git bisect` choose which commit to test, and why is it logarithmic? | [Bisect](../05-history-and-recovery/bisect.md) |
| Why does rewriting one commit change the SHA of every commit after it? | [Rewriting History](../05-history-and-recovery/rewriting-history.md) |
| Why does removing a file from history change SHAs and force re-clones? | [Filter-Repo and Secrets](../05-history-and-recovery/filter-repo-and-secrets.md) |

---

## Internals

| Question | Answered in |
|---|---|
| What exact bytes does Git hash to produce a blob's SHA? | [Object Model](../06-internals/object-model.md) |
| How does an annotated tag reach a commit, and how does `rev-parse` peel it? | [Refs and HEAD](../06-internals/refs-and-head.md) |
| What does the ort strategy compute during a three-way merge? | [How Merge and Rebase Work](../06-internals/how-merge-and-rebase-work.md) |
| How does a packfile store many versions of a file without full copies? | [Packfiles and GC](../06-internals/packfiles-and-gc.md) |
