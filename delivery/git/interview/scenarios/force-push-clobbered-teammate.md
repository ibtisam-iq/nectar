# Force-Push Clobbered a Teammate

Someone force-pushed a shared branch and a teammate's commit disappeared from the remote. Interviewers use this because it tests both the recovery path (the commit still exists somewhere) and the understanding that `--force-with-lease` and branch protection would have prevented it.

---

## Symptom

> "A colleague force-pushed main and my commit is gone from the remote. `git log origin/main` doesn't show it any more. Can I get it back, and how do we stop this happening again?"

---

## Clarifying Questions

- **Do you still have a local clone with the commit?** Your local branch or reflog almost certainly still has it.
- **Is the commit only on the remote, made by someone else?** Then their clone or the host's reflog holds it.
- **What is the current `origin/main`?** The recovery reapplies the lost commit on top of the new tip.
- **Was the branch protected?** If not, that is the prevention to put in place afterwards.

---

## Diagnostic Path

### 1. Confirm the Commit Is Gone from the Remote

```bash
git fetch origin
git log --oneline origin/main
```

Output:

```text
becdd0f Base
```

The teammate's "add feature" is not in `origin/main`; the force-push replaced the history. It is gone from the branch, not from existence.

### 2. Find the Lost Commit Locally

```bash
git log --oneline main
git reflog show origin/main
```

Output:

```text
404b14e Bob: add feature
db149ae Base
becdd0f refs/remotes/origin/main@{0}: fetch -q origin: forced-update
404b14e refs/remotes/origin/main@{1}: update by push
```

Bob's local `main` still has `404b14e`, and even the remote-tracking reflog records `origin/main` before the `forced-update`. The commit is recoverable from either.

---

## Root Causes

| Cause | Evidence | Fix |
|---|---|---|
| Plain `--force` on a shared branch | `origin/main` reflog shows `forced-update` | Reapply the lost commit, then re-push |
| Force-pusher had not fetched | Their history diverged from the remote | Recover; switch them to `--force-with-lease` |
| No branch protection | Direct force-push to `main` was accepted | Protect the branch on the host |
| Lost commit made by someone else | It is missing locally too | Recover from their clone or the host reflog |

---

## Fix

The lost commit (`404b14e`) still exists locally. Reset your branch to the new remote tip, then cherry-pick the commit back on top and push.

```bash
git reset --hard origin/main
git cherry-pick 404b14e
git log --oneline
```

Output:

```text
e0e9887 Bob: add feature
becdd0f Base
```

The commit is reapplied on top of the force-pushed `Base`, with a new SHA. Pushing now fast-forwards, because the branch sits directly on the current remote tip.

```bash
git push origin main
```

Output:

```text
pushed: Bob's commit restored on top of Alice's base
```

If the lost commit existed only on the remote, its author's clone or the host's own reflog (many platforms keep one, or expose it via support) provides the SHA to cherry-pick. The recovery is the same: get the SHA, reapply it, push.

!!! danger "The recovery works today because a clone still had the commit"
    Force-push recovery relies on some copy still holding the lost commit. That is usually true right after the incident, but not guaranteed forever. The real fix is prevention, so no one has to race the reflog.

---

## Prevention

- Never `git push --force` a shared branch; use `git push --force-with-lease`, which refuses when the remote moved and would have blocked this.
- Protect `main` and other shared branches on the host so force-pushes are rejected server-side.
- Rewrite history only on personal branches; reconcile shared branches with merge or `pull --rebase`, not force.
- Fetch before pushing, so your view of the remote is current and a lease check is meaningful.

---

## Related

- [Pushing and Pulling](../../03-remotes-and-collaboration/pushing-and-pulling.md): `--force-with-lease` and why plain `--force` is unsafe
- [Reflog and Recovery](../../05-history-and-recovery/reflog-and-recovery.md): the reflogs, including `origin/main`'s, that hold the lost tip
- [Rewriting History](../../05-history-and-recovery/rewriting-history.md): the golden rule this incident breaks
- [Diverged Branches, Push Rejected](diverged-branches-push-rejected.md): the safe path the force-pusher should have taken

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
