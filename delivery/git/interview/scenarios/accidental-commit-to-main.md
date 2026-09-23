# Accidental Commit to Main

Two commits meant for a feature branch landed on `main` instead, because the branch was never created first. Interviewers use this because the safe fix is a two-step move (name the commits, then rewind `main`) and the tempting wrong move (`reset --hard` before saving the commits) throws the work away.

---

## Symptom

> "I did some work and committed it, then realised I was on main the whole time and never made a branch. Nothing is pushed yet. Get my commits onto a feature branch and put main back where it was."

---

## Clarifying Questions

- **Are the commits pushed?** If `main` is local-only ahead of `origin/main`, a rewind is safe; if pushed, this becomes a shared-history problem needing `revert`.
- **How many commits are on the wrong branch?** `git log origin/main..HEAD` counts them exactly.
- **Is `main` protected upstream?** A protected `main` would have rejected a direct push anyway, which confirms nothing shared was affected.
- **Is the working tree clean?** Uncommitted changes must be handled before any `reset --hard`, which would discard them.

---

## Diagnostic Path

### 1. Confirm main Is Ahead and Nothing Is Pushed

```bash
git status -sb
```

Output:

```text
## main...origin/main [ahead 2]
```

`[ahead 2]` means the local `main` has two commits `origin/main` does not, so the accident is entirely local. Listing exactly those commits confirms what will move.

```bash
git log --oneline origin/main..HEAD
```

Output:

```text
e65525a Wire up login
812fddf Add login form
```

Both commits are the feature work. `origin/main..HEAD` is the precise set to relocate, and it excludes the shared history that must stay on `main`.

---

## Root Causes

| Cause | Evidence | Fix |
|---|---|---|
| Forgot to branch before committing | `main` ahead of `origin/main` by the feature commits | Branch at the tip, rewind `main` |
| Committed on `main`, already pushed | `git status` shows `up to date` or the push was accepted | `git revert` on `main`, or a coordinated reset |
| Meant to amend, made a new commit | Two commits with near-identical intent | Squash after relocating, if wanted |

---

## Fix

The move is two steps: first give the commits a branch so they cannot be lost, then rewind `main` to the remote.

```bash
git branch feature/login
git reset --hard origin/main
```

Output:

```text
HEAD is now at ede4502 Add app
```

`git branch feature/login` created a pointer at the current tip, so both commits are now reachable from `feature/login`. `git reset --hard origin/main` moved `main` back to match the remote. Verifying shows the commits safe on the new branch and `main` clean.

```bash
git log --oneline --all --decorate
```

Output:

```text
e65525a (feature/login) Wire up login
812fddf Add login form
ede4502 (HEAD -> main, origin/main) Add app
```

```bash
git switch feature/login
```

Output:

```text
Switched to branch 'feature/login'
```

`main` now equals `origin/main`, and the feature work continues on `feature/login`. Because the commits were branched before the reset, the `--hard` was safe; without the branch, `git reflog` would have been the only way back.

!!! warning "Branch before you rewind, not after"
    `git reset --hard` moves the branch and discards anything not otherwise reachable. Run `git branch <name>` first so the commits have a second pointer; then the reset only moves `main` and loses nothing.

---

## Prevention

- Start feature work with `git switch -c feature/<name>` before the first commit, so `main` never receives it.
- Protect `main` on the remote (branch protection lives in [GitHub](../../../github/codeowners.md)) so a stray direct push is rejected.
- Watch the branch name in the shell prompt or `git status` header; the `## main` line is the tell.
- If the commits were already pushed, do not rewind shared history; use `git revert` and open a proper branch for the redo.

---

## Related

- [Branches](../../02-branching-and-merging/branches.md): creating the branch that saves the commits
- [Undoing Changes](../../01-core-workflow/undoing-changes.md): `reset` modes and why `--hard` needs a saved pointer first
- [Wrong-Branch Commits](wrong-branch-commits.md): the same problem when commits landed on the wrong feature branch
- [Round 3: Troubleshooting](../round-3-troubleshooting.md): the read-only-first method this fix follows

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
