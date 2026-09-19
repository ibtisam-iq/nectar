# Round 4: Internals

Senior, SRE and platform loops ask what Git stores and how a command changes it: what a commit hashes over, what a branch and `HEAD` really are, and why a design trades one property for another. Each question links to the topic file that answers it. This page grows as each module is added, and the dedicated internals module fills in the object model.

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
