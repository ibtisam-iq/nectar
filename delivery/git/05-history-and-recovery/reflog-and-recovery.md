# Reflog and Recovery

The reflog records every move of `HEAD` and each branch tip, so commits that a reset, rebase or branch delete made unreachable can still be found and restored. Interviewers lean on this because "I lost my commits" has a calm answer, and knowing it separates people who fear Git from people who trust it.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Reflog | A local log of where `HEAD` (or a ref) has pointed | `git reflog` |
| Entry syntax | `HEAD@{n}` is the position n moves ago | `git reflog` |
| Per-branch reflog | `git reflog show <branch>` | `git reflog show main` |
| Recover after reset | `git reset --hard HEAD@{1}` (the pre-reset tip) | `git log` |
| `ORIG_HEAD` | The tip before the last reset, merge or rebase | `git rev-parse ORIG_HEAD` |
| Recover a commit | `git branch <name> <sha>` at the lost SHA | `git log <name>` |
| Deleted branch | `git branch -D` prints the tip SHA; recreate from it | `git reflog` |
| Local only | The reflog is per-clone, never pushed or fetched | it stays local |
| Expiry | Unreachable entries expire (default 30/90 days), then `gc` prunes | `git config gc.reflogExpire` |
| Last resort | `git fsck --lost-found` finds dangling commits | `git fsck` |
<!-- --8<-- [end:facts] -->

---

## What the Reflog Is

Every time `HEAD` moves (a commit, checkout, reset, merge or rebase), Git appends an entry to the reflog with the resulting SHA and a description. It is a local safety journal, separate from the commit history.

```bash
git reflog
```

Output:

```text
dcac1d1 HEAD@{0}: commit: Add tests
c136cdc HEAD@{1}: commit: Add feature
ef6463a HEAD@{2}: commit (initial): Add app
```

`HEAD@{0}` is the current position and `HEAD@{n}` is where `HEAD` was n moves ago. Because the reflog is per-clone and never shared, it can recover work on your machine that exists nowhere else.

---

## Recovering After a Hard Reset

A `git reset --hard` moves the branch and abandons the commits above the target, but those commits stay in the object store and the reflog still names them.

```bash
git reset --hard HEAD~2
git reflog
```

Output:

```text
ef6463a HEAD@{0}: reset: moving to HEAD~2
dcac1d1 HEAD@{1}: commit: Add tests
c136cdc HEAD@{2}: commit: Add feature
ef6463a HEAD@{3}: commit (initial): Add app
```

`HEAD@{1}` is the tip from before the reset. Resetting back to it restores the branch exactly.

```bash
git reset --hard HEAD@{1}
git log --oneline
```

Output:

```text
dcac1d1 Add tests
c136cdc Add feature
ef6463a Add app
```

The two "lost" commits are back. Nothing was ever deleted; the branch pointer had only moved, and the reflog remembered where it was.

---

## ORIG_HEAD

Before a reset, merge or rebase, Git saves the previous tip in `ORIG_HEAD`, which is a one-shot shortcut to "where I was before that operation".

```bash
git rev-parse --short ORIG_HEAD
```

Output:

```text
dcac1d1
```

`git reset --hard ORIG_HEAD` undoes the last reset or merge without hunting through the reflog. It is overwritten by the next such operation, so it only recovers the most recent one.

!!! tip "ORIG_HEAD is the fast undo for a merge or reset"
    Right after a merge you regret, `git reset --hard ORIG_HEAD` returns to the pre-merge state in one command. For anything older than the last history-moving operation, use the reflog and its `HEAD@{n}` entries.

---

## Recovering a Deleted Branch

Deleting a branch removes only the pointer. `git branch -D` prints the tip SHA it deleted, and the reflog also holds it, so the branch is recreated at that SHA.

```bash
git branch -D feature/experiment
```

Output:

```text
Deleted branch feature/experiment (was 868178a).
```

```bash
git branch feature/experiment 868178a
git log --oneline feature/experiment -1
```

Output:

```text
868178a Add experiment
```

If the SHA scrolled away, `git reflog` (the `HEAD` reflog records the checkout onto and off the branch) or `git fsck` finds it. The commits were reachable the whole time; only the name was gone.

!!! warning "The reflog is local and expires, so it is not a backup"
    The reflog exists only in your clone and is never pushed. Unreachable entries expire (90 days for reachable, 30 for unreachable by default) and then `git gc` can prune the objects. Recover promptly, and use a remote or real backup for durable safety.

---

## When the Reflog Cannot Help

If the reflog entry has expired or the work was in a fresh clone with no history, `git fsck --lost-found` scans the object store for dangling commits (commits no ref or reflog reaches) and lists them for inspection. Each dangling commit can be examined with `git show` and rescued with `git branch <name> <sha>`.

This is the true last resort: it works only while `git gc` has not yet pruned the unreachable objects, which is why acting quickly matters after a mistake.

---

## Common Errors

### `fatal: ambiguous argument 'HEAD@{1}': unknown revision`

**Cause:** the reflog has too few entries (a very fresh repository), or the shell mangled the braces.

**Fix:** quote it as `'HEAD@{1}'`; run `git reflog` first to see which entries exist.

### `error: unable to find <sha>` when recovering

**Cause:** `git gc` already pruned the unreachable object, so it no longer exists in the store.

**Fix:** check `git fsck --lost-found` immediately; if the object is gone, recover from a remote or another clone that still has it.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the reflog and what is it for?"
    **Say first:** it is a local log of every position `HEAD` (and each branch tip) has held, so you can recover commits made unreachable by a reset, rebase or branch delete.

    **Proof:** `git reflog` lists `HEAD@{n}` entries; `git reset --hard HEAD@{1}` returns to the previous tip.

    **Follow-up:** Is the reflog pushed to the remote or shared with teammates?

??? question "L1: You ran git reset --hard and lost commits. Are they gone?"
    **Say first:** almost certainly not; the branch pointer moved but the commits remain in the object store, and the reflog still names the old tip.

    **Proof:** `git reflog` shows the pre-reset SHA at `HEAD@{1}`; `git reset --hard HEAD@{1}` restores it.

    **Follow-up:** What is `ORIG_HEAD` and how does it help here?
<!-- --8<-- [end:l1] -->

??? question "L2: Recover a branch a colleague accidentally deleted with git branch -D."
    **Say first:** recreate it at the tip SHA, which `git branch -D` printed and the reflog still holds.

    **Proof:**

    ```bash
    git branch feature/x <sha>   # sha from the delete message or git reflog
    ```

    **Follow-up:** Where do you find the SHA if the delete message has scrolled away?

??? question "L2: Undo a merge you regret without hunting through the reflog."
    **Say first:** `git reset --hard ORIG_HEAD`, which Git set to the pre-merge tip.

    **Proof:** `git rev-parse ORIG_HEAD` shows the pre-merge commit; the reset returns the branch to it.

    **Follow-up:** Why can `ORIG_HEAD` only undo the most recent such operation?

??? question "L3: A developer says a day of work vanished after 'some rebase went wrong', and there is no branch on it. Walk through recovery."
    **Say first:** the commits are likely still in the object store; use the reflog to find the pre-rebase tip and branch from it, falling back to `fsck` if needed.

    **Proof:** `git reflog` (or `git reflog show <branch>`) locates the lost tip; `git branch rescue <sha>` restores it; `git fsck --lost-found` finds it if the reflog was pruned.

    **Follow-up:** What time pressure is there, and why?

??? question "L4: If reset --hard does not delete commits, what eventually does, and when?"
    **Say first:** commits become unreachable when no ref or reflog entry points to them; `git gc` prunes unreachable objects after they pass the expiry window (30 days unreachable, 90 days reachable, by default), or immediately with `git gc --prune=now`.

    **Proof:** `git config gc.reflogExpireUnreachable` shows the window; before expiry, `git fsck --lost-found` still finds the dangling commit.

    **Don't say:** "reset --hard deletes the commits immediately." The pointer moves; pruning is a later, separate step.

---

## Related

- [Undoing Changes](../01-core-workflow/undoing-changes.md): the `reset` modes whose damage the reflog undoes
- [Rewriting History](rewriting-history.md): amend, reset and rebase as rewrites, and their safety net
- [Branches](../02-branching-and-merging/branches.md): what a branch pointer is and how deleting it works
- [Lost Commits After Reset](../interview/scenarios/lost-commits-after-reset.md): this recovery worked end to end

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
