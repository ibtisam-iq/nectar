# Stashing

`git stash` sets aside uncommitted changes so the working tree is clean, then restores them later. Interviewers ask about it for the interruption case: a hotfix arrives mid-task, and the candidate must park work in progress without committing it half-done.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Stash changes | `git stash push -m "<msg>"` | `git stash list` |
| Include untracked | `git stash push -u` (or `--include-untracked`) | `git stash show` |
| Include ignored too | `git stash push -a` (`--all`) | `git stash show` |
| List | `git stash list` (entries are `stash@{n}`) | `git stash list` |
| Inspect | `git stash show -p stash@{0}` | the diff |
| Restore and remove | `git stash pop` | `git stash list` |
| Restore and keep | `git stash apply` | `git stash list` |
| Drop one | `git stash drop stash@{n}` | `git stash list` |
| Clear all | `git stash clear` | `git stash list` |
| Stash to a branch | `git stash branch <name>` | `git branch` |
| Storage | A stash is a commit off `refs/stash`, not a file | `git log -g refs/stash` |
<!-- --8<-- [end:facts] -->

---

## Saving Work Aside

`git stash push` records the working-tree and staged changes and reverts the tree to `HEAD`. By default it ignores untracked files; `-u` includes them, which matters for a new file that is part of the work.

```bash
git stash push -u -m "wip on login"
git status -sb
```

Output:

```text
Saved working directory and index state On main: wip on login
## main
```

The status is clean, so the branch can be switched or a hotfix applied. The `-m` message is what makes a stash findable later; without it, entries read only "WIP on main".

!!! warning "Untracked files are not stashed unless you ask"
    A plain `git stash` shelves tracked changes only, so a brand-new file stays in the working tree and travels to whatever branch you switch to. Use `git stash push -u` to include untracked files, and `-a` to include ignored ones as well.

---

## Listing and Inspecting

Stashes form a stack, newest as `stash@{0}`. `git stash list` shows them, and `git stash show -p` prints the diff of one.

```bash
git stash list
git stash show -p stash@{0}
```

Output:

```text
stash@{0}: On main: wip on login
diff --git a/app.py b/app.py
index 626799f..70c5f1c 100644
--- a/app.py
+++ b/app.py
@@ -1 +1,2 @@
 v1
+wip
```

A stash is stored as a commit (actually two or three, for the index and untracked files) hanging off `refs/stash`, not as a patch file. That is why it survives branch switches and can be inspected like any commit.

---

## Restoring: pop Versus apply

`git stash pop` reapplies the top stash and removes it from the stack. `git stash apply` reapplies it but keeps the entry, for applying the same change to several branches.

```bash
git stash pop
git status -sb
```

Output:

```text
Dropped refs/stash@{0} (16cc8da20f64c5db6eef3e4f4a696855c005332b)
## main
 M app.py
?? new.txt
```

The tracked edit and the untracked `new.txt` are both back, and the `Dropped` line confirms the entry is gone. Reapplying a stash onto a changed tree can conflict, in which case `pop` leaves the entry in place so nothing is lost; resolve the conflict, then `git stash drop` it.

!!! tip "apply keeps the stash, pop consumes it"
    Use `git stash apply` when the same shelved change is needed on more than one branch, then `git stash drop` once. Use `pop` for the ordinary "put my work back" case where the stash is no longer needed.

---

## Turning a Stash into a Branch

When a stash was taken on an old base and no longer applies cleanly, `git stash branch` creates a new branch from the commit the stash was made on, then pops the stash there with no conflict.

```bash
git stash branch feature/from-stash
```

Output:

```text
Switched to a new branch 'feature/from-stash'
On branch feature/from-stash
Changes not staged for commit:
```

The new branch starts at the exact commit the stash was created on, so the changes reapply without the drift that caused the conflict. This is the clean escape when a `pop` onto the current branch keeps conflicting.

---

## Common Errors

### `No local changes to save`

**Cause:** `git stash` was run with a clean working tree, or with only untracked files and no `-u`.

**Fix:** confirm there are changes with `git status`; add `-u` to include untracked files.

### `CONFLICT (content): Merge conflict in <file>` during a stash pop

**Cause:** the working tree changed since the stash was taken, so the reapplied changes overlap.

**Fix:** resolve the conflict and `git add` the files; the stash entry is kept on a conflicting `pop`, so `git stash drop` it once resolved.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does git stash do and when would you use it?"
    **Say first:** it shelves your uncommitted changes and reverts the working tree to `HEAD`, so you can switch context (a hotfix, a branch change) without committing half-done work; you restore the changes later.

    **Proof:** `git stash push` leaves `git status` clean; `git stash pop` brings the changes back.

    **Follow-up:** Why might a stash not include your new file, and how do you fix that?

??? question "L1: What is the difference between git stash pop and git stash apply?"
    **Say first:** both reapply the stashed changes, but `pop` removes the entry from the stack while `apply` keeps it.

    **Proof:** `git stash list` is empty after `pop` but still shows the entry after `apply`.

    **Follow-up:** When would you deliberately choose `apply`?
<!-- --8<-- [end:l1] -->

??? question "L2: A hotfix comes in while you have dirty, partly untracked work. Park it, fix, and restore."
    **Say first:** `git stash push -u` to include untracked files, do the fix, then `git stash pop`.

    **Proof:**

    ```bash
    git stash push -u -m "wip"
    # ... make and commit the hotfix ...
    git stash pop
    ```

    **Follow-up:** Where is the stash stored, and does it survive a branch switch?

??? question "L2: A stash no longer applies cleanly to your current branch. Recover it without a messy conflict."
    **Say first:** `git stash branch <name>` recreates the original base as a branch and pops the stash there conflict-free.

    **Proof:** the new branch starts at the stash's parent commit, so the changes reapply cleanly.

    **Follow-up:** Why does making a branch avoid the conflict a plain `pop` hit?

??? question "L3: You stashed some work days ago, made many stashes since, and cannot remember which entry it is. How do you find and restore it?"
    **Say first:** list the stashes with their messages, inspect the likely one's diff, then apply it by its ref.

    **Proof:** `git stash list` shows each `stash@{n}` with its message; `git stash show -p stash@{n}` confirms the contents; `git stash apply stash@{n}` restores it.

    **Follow-up:** Why prefer `apply` over `pop` while you are still identifying the right entry?

??? question "L4: How is a stash stored, and why can you inspect it like a commit?"
    **Say first:** a stash is one or more commit objects hanging off the `refs/stash` ref (a working-tree commit, its index, and optionally untracked files), not a patch file, so ordinary commit tooling reads it.

    **Proof:** `git stash show -p stash@{0}` diffs it, and `git log -g refs/stash` walks the stash reflog.

    **Don't say:** "A stash is a diff saved to a file in `.git`." It is commit objects, which is why it survives branch switches.

---

## Related

- [Undoing Changes](../01-core-workflow/undoing-changes.md): discarding rather than shelving changes
- [Branches](../02-branching-and-merging/branches.md): switching branches, the main reason to stash
- [Pushing and Pulling](pushing-and-pulling.md): stashing before a `pull` that would collide with local edits
- [Error Messages](../reference/error-messages.md): stash conflict and empty-stash messages

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
