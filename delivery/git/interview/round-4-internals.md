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
