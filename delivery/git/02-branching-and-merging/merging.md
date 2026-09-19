# Merging

Merging brings the commits of one branch into another, either by moving a pointer forward or by creating a merge commit that joins two histories. Interviewers test whether a candidate knows when Git fast-forwards, when it builds a merge commit, and what a squash merge throws away.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Fast-forward | Possible when the current branch has no commits the other lacks; Git moves the pointer | `git merge --ff-only <branch>` |
| Three-way merge | Used when both branches advanced; creates a merge commit with two parents | `git show --no-patch HEAD` |
| Merge base | The common ancestor of the two branch tips | `git merge-base A B` |
| Default strategy | `ort` (Ostensibly Recursive's Twin), since Git 2.34 | `git merge --no-edit` output |
| Force a merge commit | `git merge --no-ff <branch>` even when fast-forward is possible | `git log --graph` |
| Squash | `git merge --squash <branch>` stages the result with no merge parent | `git status -s` |
| Abort | `git merge --abort` restores the pre-merge state | `git status` |
| No-op merge | `Already up to date` when the branch is already an ancestor | `git merge <branch>` |
| Parents | First parent is the branch merged into; second is the merged branch | `git show --format=%p HEAD` |
| Editor | Non-fast-forward merges open a message editor unless `--no-edit` | `git config core.editor` |
<!-- --8<-- [end:facts] -->

---

## Fast-Forward Merge

When the current branch points to an ancestor of the branch being merged, Git has no divergence to reconcile. It moves the current branch pointer up to the other tip, which is a fast-forward.

```bash
git switch main
git merge feature/login
```

Output:

```text
Updating 0256521..465e094
Fast-forward
 auth.py | 2 ++
 1 file changed, 2 insertions(+)
 create mode 100644 auth.py
```

No merge commit is created; the history stays linear.

```bash
git log --oneline --graph -3
```

Output:

```text
* 465e094 Add logout function
* 3ad8c11 Add login function
* 0256521 Add app entrypoint
```

`git merge --ff-only <branch>` makes a fast-forward the only acceptable outcome, and fails instead of building a merge commit. This is the safe form for updating a local branch from its upstream.

---

## Three-Way Merge and the Merge Base

When both branches have new commits, neither is an ancestor of the other. Git finds the merge base, their common ancestor, and combines the two sets of changes on top of it.

```bash
git log --oneline --graph --all -3
```

Output:

```text
* 24b1bc8 Add y
| * 829656a Add x
|/
* 6eed087 Add app entrypoint
```

```bash
git merge-base main feature/x
```

Output:

```text
6eed087
```

The base is `6eed087`, the last commit both branches share. Merging combines the base-to-`main` changes with the base-to-`feature` changes, so the result is a new commit with two parents.

```bash
git merge --no-edit feature/api
git show --no-patch --format='%h parents: %p' HEAD
```

Output:

```text
Merge made by the 'ort' strategy.
 api.py | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 api.py
f1fbc2d parents: 9d65b0e 6675ff5
```

```bash
git log --oneline --graph -4
```

Output:

```text
*   f1fbc2d Merge branch 'feature/api'
|\
| * 6675ff5 Add API handler
* | 9d65b0e Add README on main
|/
* b95efe9 Add app entrypoint
```

!!! info "The ort strategy replaced recursive"
    Git 2.34 made `ort` the default three-way merge strategy. It merges faster on large trees and handles renames and directory changes more correctly than the old `recursive` strategy, with the same command surface.

---

## Forcing a Merge Commit with --no-ff

A fast-forward hides that a branch ever existed, because the history stays a single line. `--no-ff` forces a merge commit so the branch and its scope stay visible.

```bash
git merge --no-ff --no-edit feature/cart
git log --oneline --graph -3
```

Output:

```text
Merge made by the 'ort' strategy.
 cart.py | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 cart.py
*   f2b08cd Merge branch 'feature/cart'
|\
| * 946dd21 Add cart add
|/
* 8eb4ed9 Add app entrypoint
```

The merge commit records where the feature branch joined `main`, which keeps feature boundaries readable and makes a single-commit revert of the whole feature possible. Many teams set `--no-ff` for merges into long-lived branches.

---

## Squash Merge

`git merge --squash` applies the other branch's net changes to the working tree and index but makes no commit and records no second parent. A following `git commit` produces one ordinary commit.

```bash
git merge --squash feature/report
git status -s
```

Output:

```text
Updating 09c564f..517af04
Fast-forward
Squash commit -- not updating HEAD
 report.py | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 report.py
A  report.py
```

```bash
git commit -m "Add reporting feature"
git show --no-patch --format='%h parents: %p' HEAD
```

Output:

```text
93456d5 parents: 09c564f
```

The result has one parent, so `feature/report` is not recorded as merged. The individual commits on the branch are gone from `main`'s history, which is why the branch still shows as unmerged and must be deleted with `git branch -D`.

!!! warning "A squash merge loses the branch's individual commits and merge link"
    Squashing is useful for collapsing noisy work-in-progress commits into one, but Git does not mark the source branch as merged. Later merges of the same branch can replay the same changes and conflict.

---

## Aborting and No-op Merges

A three-way merge that hits conflicting edits stops and waits. `git merge --abort` returns the working tree and index to exactly the pre-merge commit.

```bash
git merge --no-edit feature/port
git merge --abort
git log --oneline -1
```

Output:

```text
Auto-merging config.ini
CONFLICT (content): Merge conflict in config.ini
Automatic merge failed; fix conflicts and then commit the result.
7a2f3e9 Set port 8080
```

Resolving conflicts is covered in [Conflict Resolution](conflict-resolution.md). When the branch to merge is already an ancestor, Git does nothing and says so.

```bash
git merge feature/x
```

Output:

```text
Already up to date.
```

---

## Common Errors

### `fatal: Not possible to fast-forward, aborting.`

**Cause:** `git merge --ff-only` was run but the branches have diverged, so a fast-forward is impossible.

**Fix:** merge normally (`git merge <branch>`), or rebase the current branch onto the target first if a linear history is required.

### `CONFLICT (content): Merge conflict in <file>`

**Cause:** both branches changed the same lines of a file, so Git cannot combine them automatically.

**Fix:** resolve the marked file, `git add` it, and `git commit`; or `git merge --abort` to back out. See [Conflict Resolution](conflict-resolution.md).

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a fast-forward and a three-way merge?"
    **Say first:** a fast-forward only moves the branch pointer forward when there is no divergence, while a three-way merge builds a merge commit from the two tips and their common ancestor when both have advanced.

    **Proof:** a fast-forward prints `Fast-forward` and keeps history linear; a three-way merge prints `Merge made by the 'ort' strategy` and creates a two-parent commit.

    **Follow-up:** How do you force a merge commit when a fast-forward is possible?

??? question "L1: What is a merge base?"
    **Say first:** the merge base is the most recent commit that both branches share, and it is the starting point Git uses to compute what each branch changed.

    **Proof:** `git merge-base main feature` prints that commit's SHA.

    **Follow-up:** What are the two parents of a merge commit, and in what order?
<!-- --8<-- [end:l1] -->

??? question "L2: Merge a feature branch into main but keep the merge visible in history."
    **Say first:** use `git merge --no-ff` so Git records a merge commit even if a fast-forward was possible.

    **Proof:**

    ```bash
    git switch main
    git merge --no-ff --no-edit feature/cart
    git log --oneline --graph -3
    ```

    **Follow-up:** Why do teams prefer `--no-ff` for merges into a release branch?

??? question "L2: Combine a noisy feature branch into main as a single commit."
    **Say first:** `git merge --squash feature` stages the net change, then `git commit` makes one commit.

    **Proof:** `git status` shows the staged files and `Squash commit -- not updating HEAD`; the new commit has one parent.

    **Follow-up:** After a squash merge, why does Git still treat the branch as unmerged?

??? question "L3: A merge that used to fast-forward now creates a merge commit you did not expect."
    **Say first:** the current branch has gained commits the target lacks, so the branches diverged and a fast-forward is no longer possible.

    **Proof:** `git log --oneline --graph --all` shows the divergence; `git merge-base HEAD <branch>` is behind both tips.

    **Follow-up:** How would you keep history linear here instead of merging?

??? question "L3: You started a merge, it stopped on a conflict, and you want to get back to a clean state."
    **Say first:** abort the merge to restore the exact pre-merge commit, then decide how to proceed.

    **Proof:** `git merge --abort` followed by `git status` shows a clean tree at the original commit.

    **Follow-up:** What state does `--abort` restore, and when is it unavailable?

??? question "L4: What does the ort strategy compute during a three-way merge?"
    **Say first:** it finds the merge base, computes the diff from the base to each side, and applies both diffs to the base; overlapping changes to the same lines become conflicts.

    **Proof:** `git merge-base A B` shows the base the diffs are taken against; the merge commit's two parents are the branch tips.

    **Don't say:** "Git merges by comparing only the two branch tips to each other."

---

## Related

- [Branches](branches.md): the pointers a merge moves and joins
- [Rebasing](rebasing.md): the linear-history alternative to a merge commit
- [Conflict Resolution](conflict-resolution.md): resolving a merge that stops on conflicting edits
- [Cherry-Pick](cherry-pick.md): copying a single commit instead of merging a branch

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
