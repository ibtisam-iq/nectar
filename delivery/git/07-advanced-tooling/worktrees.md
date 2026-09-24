# Worktrees

A worktree is a second working directory attached to the same repository, so two branches can be checked out at once without a second clone. Interviewers ask about them as the clean alternative to stashing when an urgent fix interrupts in-progress work.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Worktree | An extra checkout sharing one `.git` object store | `git worktree list` |
| Add | `git worktree add <path> <branch>` (`-b` for a new branch) | `git worktree list` |
| One branch, one worktree | A branch cannot be checked out in two at once | the error below |
| Linked `.git` | In a linked worktree, `.git` is a file, not a directory | `cat <path>/.git` |
| Remove and prune | `git worktree remove <path>`; `prune` clears stale entries | `git worktree list` |
<!-- --8<-- [end:facts] -->

---

## Adding a Worktree

`git worktree add` creates another directory checked out to a branch, backed by the same object store. Adding `-b` creates a new branch in one step.

```bash
git worktree add ../hotfix -b hotfix
```

Output:

```text
Preparing worktree (new branch 'hotfix')
HEAD is now at 210810c Init
```

`git worktree list` shows every checkout, its commit and its branch.

```bash
git worktree list
```

Output:

```text
/home/amina/shop    210810c [main]
/home/amina/hotfix  210810c [hotfix]
```

The main clone stays on `main` while the linked `hotfix` directory is a full working tree on its own branch. Both share one history, so a commit in either is immediately visible to the other.

!!! tip "Worktrees beat stashing for an urgent interruption"
    When a hotfix interrupts messy in-progress work, a new worktree gives a clean checkout without stashing or committing half-done changes; you fix and push from it, then return to the first directory as you left it.

---

## One Branch Cannot Live in Two Worktrees

Git refuses to check out the same branch in two worktrees, because both would move the one branch ref.

```bash
git worktree add ../login2 feature/login
```

Output:

```text
Preparing worktree (checking out 'feature/login')
fatal: 'feature/login' is already used by worktree at '/home/amina/login'
```

Use a different branch, or `--detach` to check out the same commit without the branch.

---

## How a Linked Worktree Is Stored

The main clone keeps a real `.git` directory. A linked worktree instead has a `.git` file pointing back into it, so all worktrees share the single object store and no history is duplicated.

```bash
cat ../hotfix/.git
```

Output:

```text
gitdir: .../.git/worktrees/hotfix
```

!!! warning "Delete a worktree with the command, not with rm alone"
    Running `rm -rf` on a worktree leaves a stale admin entry, so its branch still shows as in use; use `git worktree remove <path>`, or `git worktree prune` to clear a leftover after a manual delete.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a Git worktree, and how does it differ from a second clone?"
    **Say first:** a worktree is an additional working directory attached to the same repository, sharing one object store, so unlike a second clone it duplicates no history and sees the same commits instantly.

    **Proof:** `git worktree list` shows multiple checkouts on different branches; a linked worktree's `.git` is a file pointing into the shared store.

    **Follow-up:** Can two worktrees check out the same branch?

??? question "L1: Do worktrees share history and commits?"
    **Say first:** yes; all worktrees share one object store, so a commit in one is immediately present in the others, and only the working tree is separate.

    **Proof:** a linked worktree's `.git` file points at `.../.git/worktrees/<name>` in the main repository.

    **Follow-up:** What is duplicated by a worktree, if not the history?
<!-- --8<-- [end:l1] -->

??? question "L2: An urgent hotfix arrives while your branch is mid-refactor. Handle it without stashing."
    **Say first:** add a worktree on a new branch, fix and push from it, then return to the original directory untouched.

    **Proof:** `git worktree add ../hotfix -b hotfix`

    **Follow-up:** How is this cheaper than cloning the repo again?

??? question "L2: Why does Git refuse to check out one branch in two worktrees?"
    **Say first:** a branch is a single ref, and two worktrees moving it independently would corrupt which commit it names, so Git blocks it.

    **Proof:** the second `git worktree add <branch>` fails with `already used by worktree at`.

    **Follow-up:** How do you get that commit into a second worktree anyway?

??? question "L2: You deleted a worktree directory with rm and its branch still shows as in use. Fix it."
    **Say first:** the admin entry is stale; `git worktree prune` clears it, and `git worktree remove` is what you should have used.

    **Proof:** `git worktree prune`

    **Follow-up:** Why does `rm` alone leave the branch marked in use?

??? question "L2: How do you cleanly remove a worktree?"
    **Say first:** `git worktree remove <path>`, which deletes the directory and its admin entry together.

    **Proof:** `git worktree remove ../hotfix`

    **Follow-up:** What do you run if the directory is already gone?

---

## Related

- [Branches](../02-branching-and-merging/branches.md): the branch refs a worktree checks out
- [Stashing](../03-remotes-and-collaboration/stashing.md): the alternative to a worktree for a quick context switch
- [Object Model](../06-internals/object-model.md): the shared object store worktrees back onto

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
