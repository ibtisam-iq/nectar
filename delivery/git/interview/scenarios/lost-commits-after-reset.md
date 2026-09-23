# Lost Commits After Reset

A `git reset --hard` moved the branch back and a day of commits seems to have vanished. Interviewers use this because the calm, correct answer is the reflog, and the tell of a shaky candidate is panic or a claim that the work is gone for good.

---

## Symptom

> "I ran git reset --hard to undo one thing and now two commits, a whole afternoon of work, are missing from git log. Nothing was pushed. Can I get them back?"

---

## Clarifying Questions

- **Were the commits actually committed?** The reflog recovers commits; uncommitted working-tree changes that `--hard` overwrote are not recoverable.
- **How long ago?** The reflog keeps unreachable entries about 30 days, and `gc` could prune sooner, so recover promptly.
- **Has `git gc --prune=now` been run since?** That would remove the safety net; otherwise the objects are still there.
- **Do you know roughly when the good tip was?** The reflog is time-ordered, so an approximate time narrows the search.

---

## Diagnostic Path

### 1. Confirm What the Branch Shows Now

```bash
git log --oneline
```

Output:

```text
287f025 Add base
```

The two later commits are not in the branch history. That only means the branch pointer moved; it does not mean the commits were deleted.

### 2. Find the Lost Tip in the Reflog

```bash
git reflog
```

Output:

```text
287f025 HEAD@{0}: reset: moving to HEAD~2
f5062f0 HEAD@{1}: commit: Add tests
f3c2c34 HEAD@{2}: commit: Add feature (a day of work)
287f025 HEAD@{3}: commit (initial): Add base
```

`HEAD@{1}` (`f5062f0`, "Add tests") is the tip from immediately before the reset. The commits are intact in the object store; the reflog remembered where the branch was.

---

## Root Causes

| Cause | Evidence | Fix |
|---|---|---|
| `reset --hard` moved the branch back | Reflog shows `reset: moving to ...` at `HEAD@{0}` | Reset back to `HEAD@{1}`, or branch the lost tip |
| Meant `--soft` or `--mixed`, used `--hard` | Working-tree changes also gone | Recover commits via reflog; uncommitted edits are lost |
| Uncommitted work overwritten by `--hard` | No commit for it in the reflog | Not recoverable from Git; only committed work survives |

---

## Fix

If the branch should go back to before the reset, reset it to the reflog entry.

```bash
git reset --hard HEAD@{1}
git log --oneline
```

Output:

```text
f5062f0 Add tests
f3c2c34 Add feature (a day of work)
287f025 Add base
```

The commits are back. When you would rather not move the current branch, recover the work onto a new branch instead, which is the safer, non-destructive option.

```bash
git branch recovered f5062f0
git log --oneline recovered
```

Output:

```text
f5062f0 Add tests
f3c2c34 Add feature (a day of work)
287f025 Add base
```

`recovered` now holds the lost commits; from there you can merge or cherry-pick them where they belong. Either way, nothing was ever truly deleted; the reflog held the tip until you asked for it.

!!! danger "reset --hard also discards uncommitted changes, and those do not come back"
    The reflog recovers commits, not working-tree edits. Anything `--hard` overwrote that was never committed has no object to restore from. The lesson: commit or stash before any `reset --hard`.

---

## Prevention

- Prefer `git reset --soft` or `--mixed` when you only want to move the branch and keep the changes.
- Commit or `git stash` before any `reset --hard`, so uncommitted work is never at risk.
- Act quickly after a mistake, before `git gc` can prune unreachable objects.
- Learn `git reflog` as the first response to "my commits are gone", not the last.

---

## Related

- [Reflog and Recovery](../../05-history-and-recovery/reflog-and-recovery.md): the reflog, `ORIG_HEAD` and recovery in full
- [Undoing Changes](../../01-core-workflow/undoing-changes.md): the `reset` modes and which discard work
- [Rewriting History](../../05-history-and-recovery/rewriting-history.md): why reset abandons rather than deletes commits
- [Detached HEAD](detached-head.md): another way commits become unreferenced

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
