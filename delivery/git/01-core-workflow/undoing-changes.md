# Undoing Changes

Git has a different undo for each of the three trees, and picking the wrong one either fails to help or destroys work. Interviewers push here because the safe choice depends on whether the change is unstaged, staged, committed, or already pushed, and a candidate who reaches for `reset --hard` first loses points.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Discard unstaged edit | `git restore <file>` (index to working tree) | `git status` |
| Unstage | `git restore --staged <file>` (`HEAD` to index) | `git status` |
| Undo commit, keep staged | `git reset --soft HEAD~1` | `git status` |
| Undo commit, keep unstaged | `git reset --mixed HEAD~1` (default) | `git status` |
| Undo commit, discard all | `git reset --hard HEAD~1` (destructive) | `git log` |
| Undo a pushed commit | `git revert <sha>` (new inverse commit) | `git log` |
| File from an old commit | `git restore --source=<rev> <file>` | `git status` |
| Remove untracked files | `git clean -fd` (`-n` to preview) | `git clean -nd` |
| Recover after reset | `git reflog` still names the old tip | `git reflog` |
| Rule of thumb | `revert` shares safely; `reset` rewrites local only | team workflow |
<!-- --8<-- [end:facts] -->

---

## Choosing the Undo

The right command follows from what you want to undo and whether the commit is shared.

| Situation | Command | Effect |
|---|---|---|
| Unstaged edit is wrong | `git restore <file>` | Working-tree file back to the index version |
| Staged the wrong file | `git restore --staged <file>` | Unstage, keep the edit |
| Last commit, keep the work | `git reset --soft HEAD~1` | Commit undone, changes staged |
| Last commit, redo staging | `git reset --mixed HEAD~1` | Commit undone, changes unstaged |
| Last commit, throw it away | `git reset --hard HEAD~1` | Commit and changes gone from the tree |
| A pushed or shared commit | `git revert <sha>` | New commit that inverts it, history intact |
| Untracked junk files | `git clean -fd` | Files not in Git removed from disk |

The line that matters most: `reset` rewrites history and is for local commits; `revert` adds a new commit and is safe on shared branches.

---

## Discarding and Unstaging

`git restore <file>` overwrites the working-tree file with the index version, discarding an unstaged edit.

```bash
git status -s
git restore app.py
git status -s
```

Output:

```text
 M app.py
```

The second `git status -s` prints nothing: the edit is gone. `git restore --staged <file>` instead copies the `HEAD` version into the index, which unstages without touching the working tree.

```bash
git restore --staged app.py
git status -s
```

Output:

```text
M  app.py
 M app.py
```

Before, the `M ` was in the first column (staged); after, the `M` moved to the second column (unstaged, edit preserved). `git restore --staged --worktree <file>` does both at once, discarding the change entirely.

!!! danger "git restore <file> without --staged discards the edit permanently"
    A plain `git restore` on a modified file throws away the uncommitted change with no reflog entry to recover it, because the edit was never in an object. Stage or stash first if there is any doubt.

---

## Undoing a Commit with reset

`reset` moves the current branch to another commit and, depending on the mode, also rewinds the index and working tree. `--soft` undoes the commit but keeps its changes staged, ready to recommit.

```bash
git reset --soft HEAD~1
git status -sb
```

Output:

```text
## main
M  f
```

The commit is gone from the branch, but the change is staged (`M ` in the first column), which is how you split, reword or recombine a just-made commit. `--hard` rewinds all three trees, discarding the commit and its changes.

```bash
git reset --hard HEAD~1
git log --oneline
```

Output:

```text
HEAD is now at 3b9770d Add f
```

The `WIP not ready` commit is gone and the working tree matches the older commit. The commit object still exists in the reflog until garbage collection, so `git reflog` plus `git reset --hard <old-sha>` can bring it back; the reflog and recovery mechanics land in module 05.

---

## Reverting a Shared Commit

`git revert` creates a new commit that applies the inverse of a target commit, so history is added to, never rewritten. This is the only safe undo for a commit others have already pulled.

```bash
git revert --no-edit HEAD
git log --oneline
```

Output:

```text
ab1b01c Revert "Add more"
9f004a4 Add more
3b58597 Introduce bug
3b9770d Add f
```

The original `Add more` commit stays in history, and a new `Revert "Add more"` commit undoes its effect. Reverting a commit whose lines a later commit also changed raises a conflict, resolved like any other before `git revert --continue`.

!!! note "revert adds history, reset removes it"
    Use `revert` on anything already pushed: teammates fast-forward over the new commit with no divergence. Use `reset` only on commits that live solely in your local branch, because it abandons the old commits and forces everyone else into a rewritten history.

---

## A File from an Old Commit, and Cleaning Up

`git restore --source=<rev> <file>` pulls one file's content from any commit into the working tree, without moving the branch.

```bash
git restore --source=HEAD~3 f
git status -s
```

Output:

```text
 M f
```

The file now holds its `HEAD~3` content as an unstaged change, ready to inspect, stage or discard. Untracked files that Git never sees are removed with `git clean`, and `-n` previews first.

```bash
git clean -nd
git clean -fd
```

Output:

```text
Would remove note.txt
Would remove tmpdir/
Removing note.txt
Removing tmpdir/
```

`clean` deletes files outright with no Git copy to recover, so always run `-n` (dry run) before `-f`. Add `-x` to also remove ignored files, which is how a build directory is wiped for a clean rebuild.

---

## Common Errors

### `error: pathspec 'file' did not match any file(s) known to git`

**Cause:** `git restore --staged <file>` or `git restore --source=<rev> <file>` named a path that does not exist in that source, often a typo or a file added later.

**Fix:** confirm the path exists in the source with `git ls-tree <rev>`; use the exact path as Git records it.

### `fatal: Cannot do hard reset with paths`

**Cause:** `git reset --hard <commit> -- <path>` was attempted, but `--hard` operates on the whole tree and cannot take a pathspec.

**Fix:** use `git restore --source=<commit> <path>` to reset a single file, or drop the path to hard-reset the whole branch.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: When do you use git revert instead of git reset?"
    **Say first:** use `revert` for a commit that has been pushed or shared, because it adds a new inverse commit and leaves history intact; use `reset` only for commits that are still local, because it rewrites history.

    **Proof:** `git revert <sha>` keeps the original commit in `git log` and adds a `Revert "..."` commit; `git reset --hard` removes commits from the branch.

    **Follow-up:** What breaks if you `reset` and force-push a branch teammates have already pulled?

??? question "L1: What is the difference between reset --soft, --mixed and --hard?"
    **Say first:** all three move `HEAD`; `--soft` stops there (changes stay staged), `--mixed` also resets the index (changes become unstaged), and `--hard` also resets the working tree (changes are discarded).

    **Proof:** after `--soft HEAD~1` the change shows `M ` (staged); after `--hard HEAD~1` the working tree matches the target and the change is gone.

    **Follow-up:** Which of the three can lose uncommitted work, and is it recoverable?
<!-- --8<-- [end:l1] -->

??? question "L2: You staged a file by mistake. Unstage it without losing the edit."
    **Say first:** `git restore --staged <file>` moves the `HEAD` version into the index and keeps the working-tree edit.

    **Proof:**

    ```bash
    git restore --staged app.py
    git status -s
    ```

    **Follow-up:** How do you both unstage and discard the edit in one command?

??? question "L2: Undo your last local commit but keep its changes to recommit differently."
    **Say first:** `git reset --soft HEAD~1` removes the commit and leaves its changes staged.

    **Proof:** `git status` shows the files as staged (`M ` in the first column) with no commit above the previous one.

    **Follow-up:** What would `--mixed` (the default) do differently here?

??? question "L3: A bad change was merged to main last week and is already in production history. How do you back it out safely?"
    **Say first:** `git revert` the bad commit (or the merge) so the fix is a new commit everyone can pull, without rewriting the shared history.

    **Proof:** `git log` after the revert shows the original commit plus a `Revert "..."` commit; teammates fast-forward with no divergence.

    **Follow-up:** How does reverting a merge commit differ from reverting a normal commit?

??? question "L4: After git reset --hard HEAD~1, is the discarded commit really gone?"
    **Say first:** the branch no longer points to it, but the commit object survives in the object store and the reflog until garbage collection prunes unreachable objects.

    **Proof:** `git reflog` still lists the old tip SHA; `git reset --hard <sha>` or `git branch save <sha>` restores it.

    **Don't say:** "reset --hard permanently deletes the commit immediately." The uncommitted working-tree edits it overwrote are what is truly unrecoverable.

---

## Related

- [The Three Trees](../00-foundations/the-three-trees.md): what each `reset` mode moves and why
- [Staging and Committing](staging-and-committing.md): the staging these commands undo
- [Accidental Commit to Main](../interview/scenarios/accidental-commit-to-main.md): `reset` used to move commits off a branch safely
- [Error Messages](../reference/error-messages.md): the `reset` and `restore` errors, with fixes

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
