# Branches

A branch is a movable pointer to one commit, so creating and switching branches is cheap and instant. Interviewers open with branches because every later topic (merging, rebasing, remotes) depends on understanding what a branch and `HEAD` actually are.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| A branch | A file under `refs/heads/` holding one 40-character commit SHA | `cat .git/refs/heads/main` |
| `HEAD` | A pointer to the current branch, or to a commit when detached | `cat .git/HEAD` |
| Create only | `git branch <name>` creates without switching | `git branch` |
| Create and switch | `git switch -c <name>` (older: `git checkout -b`) | `git branch --show-current` |
| Switch | `git switch <name>` (older: `git checkout <name>`) | `git branch --show-current` |
| Previous branch | `git switch -` returns to the last branch | `git branch --show-current` |
| Rename | `git branch -m <old> <new>` | `git branch` |
| Delete merged | `git branch -d <name>` refuses if commits are unmerged | `git branch` |
| Delete forced | `git branch -D <name>` deletes even unmerged commits | `git reflog` |
| Upstream | The remote branch a local branch tracks | `git branch -vv` |
| Set upstream | `git push -u origin <name>` or `git branch --set-upstream-to` | `git status -sb` |
| Default name | `init.defaultBranch`, `main` on current Git | `git config init.defaultBranch` |
<!-- --8<-- [end:facts] -->

---

## What a Branch Is

A branch is not a copy of the files. It is a small file whose entire content is the SHA of one commit, and `git commit` moves that file forward to the new commit.

```bash
cat .git/refs/heads/main
wc -c .git/refs/heads/main
```

Output:

```text
f592db18ea7fbce04e78a72002366c6a8bb69778
      41 .git/refs/heads/main
```

The 41 bytes are the 40 hexadecimal characters of the SHA plus a newline. Because a branch is one small pointer, Git creates and deletes branches in constant time regardless of repository size.

---

## Creating and Switching

`git switch -c <name>` creates a branch at the current commit and moves onto it. `git branch <name>` creates the pointer but leaves `HEAD` where it is.

```bash
git switch -c feature/checkout
git branch
```

Output:

```text
Switched to a new branch 'feature/checkout'
* feature/checkout
  main
```

The asterisk marks the current branch. `git switch` was added in Git 2.23 to separate branch changes from file restores; `git checkout -b` and `git checkout <name>` still work and appear in most existing scripts.

!!! note "switch and restore split the old checkout"
    `git checkout` did two unrelated jobs: change branch and overwrite files. Git 2.23 split them into `git switch` (branches) and `git restore` (files), which removes the mistake of discarding edits when you meant to change branch.

---

## HEAD and the Current Branch

`HEAD` is how Git knows which branch a new commit extends. On a branch, `HEAD` holds a symbolic reference to that branch, not a SHA.

```bash
cat .git/HEAD
git rev-parse --short HEAD
```

Output:

```text
ref: refs/heads/main
f592db1
```

`HEAD` points to `refs/heads/main`, and `main` points to the commit. `git rev-parse HEAD` follows both hops and prints the commit SHA, which is what `git log`, `git diff` and `git commit` act on.

---

## Renaming and Deleting

A branch rename rewrites the pointer name; a delete removes the pointer, not the commits. Deleting the last pointer to a line of commits is what makes them hard to find later.

```bash
git branch draft main
git branch -m draft experiment
git branch -d experiment
```

Output:

```text
Deleted branch experiment (was f592db1).
```

`git branch -d` refuses to delete a branch whose commits are not reachable from another branch, which protects work in progress. `git branch -D` forces the delete and is the usual way commits become unreachable.

---

## Tracking a Remote Branch

An upstream is the remote branch a local branch compares against for ahead and behind counts. `git push -u` sets it on the first push; `git branch -vv` shows it in square brackets.

```bash
git branch -vv
```

Output:

```text
  feature/checkout f592db1 Set service port
* main             f592db1 [origin/main] Set service port
```

A branch created locally has no upstream until one is set, so `git status` cannot report ahead or behind for it.

```bash
git switch -c feature/cart
git status -sb
```

Output:

```text
## feature/cart
```

The `## feature/cart` line has no `...origin/...` suffix, which confirms the branch tracks nothing yet. Setting an upstream and reading ahead and behind counts belong to the remotes topics.

---

## Detached HEAD

Checking out a commit instead of a branch detaches `HEAD`: it points straight at a commit, and new commits belong to no branch.

```bash
git switch --detach HEAD~1
git status | head -2
cat .git/HEAD
```

Output:

```text
HEAD is now at c7db66d Add service manifest
HEAD detached at c7db66d
c7db66d3fc803204c08b95e1b77f6bc8edd5f765
```

`.git/HEAD` now holds a raw SHA rather than `ref: refs/heads/...`. Reattaching to a branch is a plain switch, and Git reminds you where the detached position was.

```bash
git switch main
```

Output:

```text
Previous HEAD position was c7db66d Add service manifest
Switched to branch 'main'
```

!!! warning "Commits made on a detached HEAD have no branch to keep them"
    Work committed while detached is reachable only from `HEAD`. Switching away leaves it unreferenced, and `git gc` can eventually remove it. Create a branch first with `git switch -c <name>` if the commits matter.

---

## Common Errors

### `error: the branch 'wip' is not fully merged`

**Cause:** `git branch -d` was used on a branch with commits that no other branch reaches, so the delete would lose them.

**Fix:** merge or rebase the work first, or, if the commits are truly unwanted, delete with `git branch -D wip`.

### `fatal: a branch named 'feature/checkout' already exists`

**Cause:** `git switch -c` (or `git branch`) was given a name that is already a branch.

**Fix:** switch to it with `git switch feature/checkout`, or pick a different name.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a branch in Git?"
    **Say first:** a branch is a movable pointer to a single commit, stored as a small file under `refs/heads/` that holds that commit's SHA.

    **Proof:** `cat .git/refs/heads/main` prints one 40-character SHA; `git commit` advances it.

    **Follow-up:** What does `HEAD` point to when you are on a branch?

??? question "L1: What is HEAD, and how does it differ from a branch?"
    **Say first:** `HEAD` is a pointer to the current branch (or directly to a commit when detached), while a branch is a pointer to a commit; `HEAD` is one level of indirection above the branch.

    **Proof:** `cat .git/HEAD` shows `ref: refs/heads/main` on a branch, or a raw SHA when detached.

    **Follow-up:** What is a detached HEAD and when does it happen?
<!-- --8<-- [end:l1] -->

??? question "L2: Create a branch for a hotfix from main and switch to it in one command."
    **Say first:** `git switch -c hotfix/login main` creates the branch at `main` and moves onto it.

    **Proof:**

    ```bash
    git switch -c hotfix/login main
    git branch --show-current
    ```

    **Follow-up:** What is the older equivalent of `git switch -c`?

??? question "L2: How do you see which remote branch a local branch tracks?"
    **Say first:** `git branch -vv` lists each branch with its upstream in square brackets.

    **Proof:** the current branch shows `[origin/main]`; a branch with no upstream shows none.

    **Follow-up:** How do you set an upstream for a branch that has none?

??? question "L3: git status says 'HEAD detached', and there are commits you need to keep."
    **Say first:** the commits are reachable only from `HEAD`, so give them a branch before switching away.

    **Proof:** `git switch -c keep-work` turns the detached position into a branch; `git log --oneline -3` confirms the commits are now on it.

    **Follow-up:** What removes commits that were never given a branch?

??? question "L3: A teammate ran git branch -D on a branch and lost a day of commits. Can you recover them?"
    **Say first:** yes, if `git gc` has not pruned them; the reflog and `HEAD` history still name the commit.

    **Proof:** `git reflog` shows the tip SHA the branch had; `git branch recovered <sha>` restores it.

    **Follow-up:** Why does `git branch -d` refuse an unmerged branch while `-D` does not?

??? question "L4: What actually changes on disk when you create and then switch to a branch?"
    **Say first:** creating a branch writes one small ref file with the current commit's SHA; switching rewrites `.git/HEAD` to point at that ref and updates the working tree to match its commit.

    **Proof:** `cat .git/refs/heads/<name>` shows the SHA; `cat .git/HEAD` changes to `ref: refs/heads/<name>`.

    **Don't say:** "Git copies the files into a new directory for the branch."

---

## Related

- [Merging](merging.md): bringing two branches back together
- [Rebasing](rebasing.md): moving a branch onto a new base
- [Conflict Resolution](conflict-resolution.md): what happens when two branches change the same lines
- [Cherry-Pick](cherry-pick.md): copying one commit onto another branch

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
