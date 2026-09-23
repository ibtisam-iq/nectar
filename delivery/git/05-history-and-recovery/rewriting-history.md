# Rewriting History

Rewriting history means replacing commits with new ones: amending, resetting, rebasing or filtering. Interviewers focus here because every such tool creates new SHAs and abandons the old commits, which is safe on local work and destructive on anything already shared, the single golden rule of Git.

**Track:** Advanced · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Rewrite = new SHAs | A changed commit and all its descendants get new ids | `git log --oneline` |
| Amend | `git commit --amend` rewrites the last commit | `git log -1` |
| Reset | `git reset` moves the branch, dropping commits | `git reflog` |
| Interactive rebase | `git rebase -i` squashes, reorders, rewords, drops | `git log` |
| Whole history | `git filter-repo` rewrites every commit (paths, content) | `git log` |
| Golden rule | Never rewrite commits others have pulled | team history |
| Safe scope | Local, unpushed commits, or a branch that is yours alone | `git log @{u}..HEAD` |
| After rewriting a pushed branch | `git push --force-with-lease` | the push output |
| Old commits survive | In the reflog until `gc` prunes them | `git reflog` |
| filter-branch | The old, slow, error-prone tool; prefer filter-repo | Git docs |
<!-- --8<-- [end:facts] -->

---

## What Rewriting Means

A commit's id is a hash of its content, which includes its parent. So changing any commit produces a new id, and because each later commit records its parent's id, every descendant is rewritten too. The old commits are not edited; they are replaced and abandoned.

This is why "rewrite history" is literal: `git rebase`, `git commit --amend` and `git reset` do not modify commits in place. They build new commits and move the branch pointer to them, leaving the originals reachable only through the reflog.

---

## The Tools

Each tool rewrites a different scope of history.

| Tool | Rewrites | Typical use |
|---|---|---|
| `git commit --amend` | The last commit only | Fix the latest message or add a forgotten file |
| `git reset` | Drops commits from the branch tip | Undo local commits, keep or discard the changes |
| `git rebase -i` | A range of commits | Squash, reorder, reword or drop before sharing |
| `git rebase <base>` | Replays commits onto a new base | Update a branch to the latest `main` |
| `git filter-repo` | Every commit in history | Remove a file or secret from all of history |

The first three are covered in [Staging](../01-core-workflow/staging-and-committing.md), [Undoing Changes](../01-core-workflow/undoing-changes.md) and [Interactive Rebase](../02-branching-and-merging/interactive-rebase.md); the last in [Filter-Repo and Secrets](filter-repo-and-secrets.md).

---

## The Cascade Demonstrated

Rewriting the oldest commit changes the id of every commit after it, because each parent id changed. Rewording the root commit of a three-commit history shows all three ids change.

```bash
git log --oneline
```

Output:

```text
1ba9fba C
554736e B
b8f0e9b A
```

After an interactive rebase that rewords the root commit `A`:

```bash
git rebase -i --root
git log --oneline
```

Output:

```text
422d83b C
abdd491 B
cf4eef3 A (clarified)
```

Only `A`'s message changed, yet `B` and `C` also have new SHAs, because their parent chain was rewritten. This cascade is exactly why rewriting shared commits is disruptive: everyone who has the old ids now has a divergent history.

---

## Rewriting the Last Commit

The smallest rewrite is `git commit --amend`, which replaces the most recent commit with a new one built from the current index. It is the common case: a forgotten file or a bad message.

```bash
git log --oneline
git commit --amend -m "Add feature and tests"
git log --oneline
```

Output:

```text
f43a4bf Add feature
a72aead Add feature and tests
```

The commit is not edited; `f43a4bf` is replaced by a new commit `a72aead` with the amended content and message. The original is now unreachable from the branch but survives in the reflog.

```bash
git reflog -2
```

Output:

```text
a72aead HEAD@{0}: commit (amend): Add feature and tests
f43a4bf HEAD@{1}: commit (initial): Add feature
```

`HEAD@{1}` still names the pre-amend commit, which is why an amend done by mistake is recoverable. Amend is safe on the last commit only while it is unpushed; once shared, it needs a force and breaks the golden rule.

---

## The Golden Rule

Never rewrite commits that others have already pulled. Rewriting a shared commit replaces it with a new one, so teammates who have the old commit end up on a divergent history, and reconciling it means forced pushes and confusion.

The safe scope is commits that live only in your local repository, or a branch that is genuinely yours alone. `git log @{u}..HEAD` shows the commits not yet pushed, which are the ones you may freely reshape.

!!! danger "Rewriting shared history forces everyone into a divergence"
    Once a commit is pushed and pulled by others, its id is part of their history. Rewriting it (amend, rebase, reset then force) makes your branch and theirs disagree on what that commit is, and the next fetch reports diverged branches for the whole team. Rewrite before you push, not after.

---

## Rewriting a Branch You Already Pushed

Sometimes a branch is yours alone but already pushed (a personal feature branch). Rewriting it locally then needs a force push, and `--force-with-lease` is the safe form: it refuses if the remote moved since your last fetch, so it cannot clobber a commit someone else added.

```bash
git push --force-with-lease origin feature/mine
```

Never use a plain `git push --force` on anything shared. The full force-push mechanics and the `(stale info)` safety refusal are in [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md).

!!! tip "Rewrite locally, force-with-lease only your own branch"
    The clean workflow is: tidy commits with `rebase -i` while the branch is still local, and if it was already pushed to your own feature branch, update it with `--force-with-lease`. Shared branches (`main`, `develop`) are rewritten only through `git revert`, which adds history instead.

---

## Common Errors

### `Updates were rejected because the tip of your current branch is behind`

**Cause:** you rewrote local history, so the push is no longer a fast-forward of the remote branch.

**Fix:** if the branch is yours alone, `git push --force-with-lease`; if it is shared, do not force, use `git revert` instead.

### `error: cannot rebase: You have unstaged changes`

**Cause:** a rebase (which rewrites history) refuses to run with a dirty working tree.

**Fix:** commit or `git stash` the changes, run the rebase, then restore them.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does it mean to rewrite history in Git, and which commands do it?"
    **Say first:** it means replacing commits with new ones that have new SHAs; `git commit --amend`, `git reset`, `git rebase` (including `-i`) and `git filter-repo` all rewrite history.

    **Proof:** after a rebase, `git log --oneline` shows new SHAs for the rewritten commits; the old ones remain only in the reflog.

    **Follow-up:** What is the golden rule about rewriting?

??? question "L1: What is the golden rule of rebasing and rewriting?"
    **Say first:** never rewrite commits that others have already pulled; only rewrite local, unshared commits (or a branch that is yours alone).

    **Proof:** rewriting a shared commit gives it a new id, so teammates' clones diverge on the next fetch.

    **Follow-up:** How do you safely update a personal feature branch you already pushed?
<!-- --8<-- [end:l1] -->

??? question "L2: You need to change a commit five back and everything after it must stay. What is safe to do?"
    **Say first:** if those commits are unpushed, `git rebase -i` and `edit` (or `reword`) the target; expect new SHAs for it and every commit after it.

    **Proof:** `git log @{u}..HEAD` confirms the range is local; the rebase reports new ids from the edited commit forward.

    **Follow-up:** Why do the commits after the edited one also change SHA?

??? question "L2: Update a pushed personal branch after squashing its commits."
    **Say first:** `git push --force-with-lease`, which overwrites only if the remote is where you last saw it.

    **Proof:** a plain push is rejected as non-fast-forward; `--force-with-lease` succeeds unless the remote moved.

    **Follow-up:** Why `--force-with-lease` rather than `--force`?

??? question "L3: A teammate rebased and force-pushed main, and now everyone's pull shows diverged branches. What went wrong and how do you recover?"
    **Say first:** they rewrote shared history, breaking the golden rule; recovery is to agree on one correct tip and have everyone reset to it, using reflogs to rescue any local work.

    **Proof:** `git reflog` and `git log origin/main@{1}` locate the pre-force tips; the team resets to the agreed commit and re-applies stranded commits.

    **Follow-up:** What should have been used instead of a rewrite to undo whatever they were fixing?

??? question "L4: Why does rewriting one commit change the SHA of every commit after it?"
    **Say first:** a commit's SHA hashes its content including its parent's SHA, so a rewritten commit has a new id, which forces its child to record a new parent and therefore get a new id, cascading to the tip.

    **Proof:** rewording the root of a three-commit history changed all three SHAs, though only one message changed.

    **Don't say:** "Only the edited commit changes." The parent-id chain rewrites every descendant.

---

## Related

- [Interactive Rebase](../02-branching-and-merging/interactive-rebase.md): the main history-rewriting tool for a range
- [Undoing Changes](../01-core-workflow/undoing-changes.md): `reset` and `revert`, and when each is safe
- [Filter-Repo and Secrets](filter-repo-and-secrets.md): rewriting every commit to remove a file
- [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md): `--force-with-lease` and the rejected-push mechanics

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
