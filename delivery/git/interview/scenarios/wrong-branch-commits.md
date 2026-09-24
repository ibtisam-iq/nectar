# Wrong-Branch Commits

Two commits that belong on an existing feature branch were made on `main` instead. Interviewers use this because the fix depends on where the commits should end up: a brand-new branch is a rewind, but an existing branch needs the commits copied over and then removed from the source.

---

## Symptom

> "I started coding on main, but there was already a feature/payments branch for this work. Two payment commits are on main now. Move them onto feature/payments and clean main up. Nothing is pushed."

---

## Clarifying Questions

- **Does the target branch already exist?** A new branch is a rewind of the source; an existing branch needs the commits replayed onto it first.
- **How many commits moved?** `git log <target>..main` (or `origin/main..HEAD`) lists exactly which commits are on the wrong branch.
- **Are the commits pushed?** Local-only commits can be removed from the source with `reset`; pushed ones need `revert` on the shared branch.
- **Do the commits depend on other work on `main`?** If they build on unshared `main` commits, those must move too, or the replay will not apply cleanly.

---

## Diagnostic Path

### 1. See Where the Commits Are

```bash
git log --oneline --all --decorate
```

Output:

```text
5fb65de (HEAD -> main) Add payment API
10b8f5f Add payment model
f220d4e (feature/payments) Add app
```

`feature/payments` sits at the shared base `f220d4e`, and the two payment commits are ahead of it on `main`. The commits share the same base as the target, so they can be replayed onto `feature/payments` without conflict.

---

## Root Causes

| Cause | Evidence | Fix |
|---|---|---|
| Committed on `main`, target branch exists | Commits ahead of both the target and the remote | Cherry-pick the range onto the target, reset the source |
| Committed on `main`, target is new | Commits ahead of `origin/main`, no target yet | `git branch <new>` then `git reset --hard origin/main` |
| Commits depend on other `main` work | Replay conflicts or drags extra commits | Move the dependency too, or `git rebase --onto` |

---

## Fix

Copy the commits onto the target branch, then remove them from `main`. Switching to the target and cherry-picking the range replays both commits.

```bash
git switch feature/payments
git cherry-pick main~2..main
```

Output:

```text
[feature/payments 6552631] Add payment model
 Date: Thu Sep 17 10:05:00 2026 +0500
 1 file changed, 2 insertions(+)
 create mode 100644 pay.py
[feature/payments 109df66] Add payment API
 Date: Thu Sep 17 10:10:00 2026 +0500
 1 file changed, 3 insertions(+)
```

`main~2..main` is the two-commit range (the lower bound is exclusive), so both payment commits are now on `feature/payments`. With the work safely copied, `main` is rewound to drop them.

```bash
git switch main
git reset --hard HEAD~2
git log --oneline --all --decorate
```

Output:

```text
HEAD is now at f220d4e Add app
109df66 (feature/payments) Add payment API
6552631 Add payment model
f220d4e (HEAD -> main) Add app
```

`main` is back at the shared base, and the two commits live only on `feature/payments`. The cherry-picked commits carry new SHAs (`6552631`, `109df66`), because their parent changed; the original content and messages are preserved.

!!! note "For a brand-new target branch, one command replaces two"
    If the target does not exist yet, there is nothing to cherry-pick onto: `git branch feature/payments` at the tip captures the commits, then `git reset --hard origin/main` rewinds `main`. Cherry-pick is only needed when replaying onto a branch that already has its own tip.

!!! tip "git rebase --onto moves a run of commits in one step"
    `git rebase --onto feature/payments main~2 main` replays the commits after `main~2` onto `feature/payments` and moves `main` to the result in one operation. Cherry-pick plus reset is the more explicit equivalent and is easier to reason about under pressure.

---

## Prevention

- Create or switch to the feature branch before the first commit: `git switch feature/payments` (or `git switch -c` for a new one).
- Check `git status`'s `## <branch>` header before committing when several branches are in play.
- Keep the branch name visible in the shell prompt.
- Pull and branch at the start of a task, so the intended branch is already current when work begins.

---

## Related

- [Cherry-Pick](../../02-branching-and-merging/cherry-pick.md): copying a commit or a range onto another branch
- [Rebasing](../../02-branching-and-merging/rebasing.md): `git rebase --onto` for moving a run of commits
- [Undoing Changes](../../01-core-workflow/undoing-changes.md): the `reset --hard` that removes the commits from the source
- [Accidental Commit to Main](accidental-commit-to-main.md): the new-branch variant of the same mistake

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
