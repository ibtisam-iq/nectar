# Detached HEAD

Commits were made while `HEAD` pointed at a commit instead of a branch, so they belong to no branch and will become unreachable on the next switch. Interviewers use this because the fix is trivial once you understand what `HEAD` is, and the panic response (switching away, then assuming the work is gone) is avoidable.

---

## Symptom

> "Git says I am in 'detached HEAD' state. I made a couple of commits here. How do I keep them, and how did I end up like this?"

---

## Clarifying Questions

- **Have you switched away yet?** If still detached, a branch saves the commits instantly; if already switched, the reflog is the route back.
- **How did you get here?** `git checkout <sha>`, `git checkout <tag>`, or a `git switch --detach` all detach `HEAD`.
- **Do you actually want to keep the commits?** If they were throwaway experiments, switching away is the correct discard.
- **Is the working tree clean?** Uncommitted work must be committed or stashed before switching, or it is lost separately.

---

## Diagnostic Path

### 1. Confirm the Detached State

```bash
git status
cat .git/HEAD
```

Output:

```text
HEAD detached from 834c335
nothing to commit, working tree clean
0195add4971383a43ff1943c899e9930d83c48fd
```

`.git/HEAD` holds a raw SHA rather than `ref: refs/heads/<branch>`, which is the definition of detached: `HEAD` points straight at a commit, so new commits extend no branch. On a branch, that file would read `ref: refs/heads/main`.

### 2. See the Orphaned Commits

```bash
git log --oneline -3
```

Output:

```text
0195add Refine hotfix
9ae3f82 Add hotfix
834c335 Add app
```

`Refine hotfix` and `Add hotfix` are reachable only from `HEAD` right now. Nothing else points at them, so switching to a branch would leave them unreferenced.

---

## Root Causes

| Cause | Evidence | Fix |
|---|---|---|
| Checked out a commit or tag, then committed | `HEAD detached from <sha>`, still detached | `git branch <name>` (or `switch -c`), then switch |
| Already switched away without branching | Commits missing from every branch | `git reflog`, then `git branch <name> <sha>` |
| Experiment you want to discard | Detached commits are throwaway | `git switch <branch>` alone; they become unreachable |

---

## Fix

If you are still detached, give the commits a branch before switching. The branch captures the current `HEAD`, so nothing is lost.

```bash
git branch hotfix/urgent
git switch main
git log --oneline --all --decorate -5
```

Output:

```text
Previous HEAD position was 0195add Refine hotfix
Switched to branch 'main'
0195add (hotfix/urgent) Refine hotfix
9ae3f82 Add hotfix
98f882f (HEAD -> main) Third
b0decd9 Second
834c335 Add app
```

The commits now live on `hotfix/urgent`, safely off the detached position. If you had already switched away without branching, the commits are unreferenced but not gone; the reflog still names them.

```bash
git reflog -3
git branch recovered ab2164e
```

Output:

```text
cc3dfe3 HEAD@{0}: checkout: moving from ab2164ec0e02d00e8718377757d57704ad6987c9 to main
ab2164e HEAD@{1}: commit: Committed while detached
cc3dfe3 HEAD@{2}: checkout: moving from main to HEAD
```

`HEAD@{1}` is the detached commit; `git branch recovered <sha>` (or `git branch recovered HEAD@{1}`) turns it back into a named, reachable branch. This works until garbage collection prunes unreachable objects, which the recovery module covers in full.

!!! note "A detached HEAD is a feature, not a fault"
    Detaching is how you inspect or build on an old commit or a tag without moving a branch. It only becomes a problem when you commit and then forget to name the work. Create a branch first (`git switch -c <name>`) whenever the commits matter.

---

## Prevention

- Use `git switch -c <name> <commit>` instead of `git checkout <commit>` when you intend to commit; it lands you on a branch from the start.
- Watch the status header: a detached state prints `HEAD detached at/from <sha>` instead of a branch name.
- Treat the "you are in detached HEAD state" notice as an instruction to branch if you plan to keep anything.
- Leave `advice.detachedHead` enabled so Git keeps printing the warning.

---

## Related

- [Branches](../../02-branching-and-merging/branches.md): what `HEAD` is and how detaching works
- [Undoing Changes](../../01-core-workflow/undoing-changes.md): the reflog safety net for lost commits
- [Wrong-Branch Commits](wrong-branch-commits.md): relocating commits that landed in the wrong place
- [Inspecting History](../../01-core-workflow/inspecting-history.md): reading `git reflog` and `git log --all`

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
