# Merge Conflict Resolution

A `git pull` stops with a conflict and the repository is stuck mid-merge. Interviewers use this because the wrong instinct (delete the file, force something, or `git checkout .`) destroys work, while the right path is a short, ordered set of read-only checks followed by one deliberate resolution.

---

## Symptom

> "I ran git pull and it stopped with a conflict. Now git says the branches diverged and I cannot push. Get it merged cleanly without losing my change or my teammate's."

---

## Clarifying Questions

- **What did `git pull` print?** The `CONFLICT` line names the file; the fetch line shows how far the remote moved.
- **Is the branch shared?** A shared branch rules out rewriting history to fix this; the merge must be resolved and committed.
- **Do you want a merge or a linear history?** That decides between finishing the merge and aborting to `git pull --rebase`.
- **Which change is correct, yours, theirs, or both?** The resolution depends on intent, not on which side is newer.
- **Has anything else been committed on top?** If the merge is already half-resolved, `git status` says so.

---

## Diagnostic Path

### 1. Confirm the Conflict and What Stopped

```bash
git pull --no-rebase origin main
```

Output:

```text
From github.com:acme/shop
 * branch            main       -> FETCH_HEAD
   262ac45..bbdaae5  main       -> origin/main
Auto-merging settings.conf
CONFLICT (content): Merge conflict in settings.conf
Automatic merge failed; fix conflicts and then commit the result.
```

```bash
git status
```

Output:

```text
On branch main
Your branch and 'origin/main' have diverged,
and have 1 and 1 different commits each, respectively.
# ... (trimmed)
Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   settings.conf

no changes added to commit (use "git add" and/or "git commit -a")
```

`both modified` confirms a content conflict: the local branch and `origin/main` each changed `settings.conf`. The merge is paused, not failed, so the fix is to resolve and commit.

### 2. See Which Commits Diverged

```bash
git log --oneline --graph --all -4
```

Output:

```text
* bcc3344 Set timeout to 45
| * bbdaae5 Raise timeout to 60
|/
* 262ac45 Add settings
```

Both branches built one commit on the shared base `262ac45`, editing the same setting to different values. Neither is an ancestor of the other, which is why Git needs a merge and hit a conflict.

### 3. Read Both Sides

```bash
git diff
```

Output:

```text
diff --cc settings.conf
index 9248c45,121f443..0000000
--- a/settings.conf
+++ b/settings.conf
@@@ -1,2 -1,2 +1,6 @@@
++<<<<<<< HEAD
 +timeout = 45
++=======
+ timeout = 60
++>>>>>>> bbdaae56ace11023badca408998d852500e15bf4
  retries = 3
```

The section above `=======` is the local change (`HEAD`), below it is the incoming commit. Deciding the value is a judgement call: here the team agrees the higher timeout wins.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Both sides edited the same line | `both modified` in status; markers in the file | Edit to the intended value, `git add`, commit the merge |
| A pull merged when a rebase was wanted | A merge commit appears in `git log --graph` | `git merge --abort`, then `git pull --rebase` |
| Only one side was kept by mistake | The resolved file matches one branch verbatim | Re-open and combine both intents, then re-stage |
| Marker committed by accident | `git diff --check` reports a leftover marker | Amend the resolution and remove the marker |

---

## Fix

```bash
printf 'timeout = 60\nretries = 3\n' > settings.conf
git add settings.conf
git diff --check
git commit --no-edit
```

Output:

```text
[main 21e92a3] Merge branch 'main' of github.com:acme/shop
```

`git diff --check` prints nothing, confirming no conflict markers remain. The merge commit records both parents, so history keeps the local and the incoming commits. A `git push` then updates the remote.

---

## Prevention

- Pull often, so branches diverge by little and conflicts stay small.
- Prefer `git pull --rebase` (or set `pull.rebase=true`) for a linear history on personal branches, and `git pull --ff-only` to be told to reconcile explicitly rather than silently merging.
- Split large files that many people edit, and agree who owns shared config lines.
- Enable `rerere` so a recurring conflict is resolved once and replayed.
- Run `git diff --check` before committing a resolution, to catch a leftover marker.

---

## Related

- [Conflict Resolution](../../02-branching-and-merging/conflict-resolution.md): markers, index stages and `--ours`/`--theirs`
- [Merging](../../02-branching-and-merging/merging.md): why a three-way merge is needed here
- [Rebasing](../../02-branching-and-merging/rebasing.md): the linear-history alternative to this merge
- [Branches](../../02-branching-and-merging/branches.md): the diverged pointers behind the conflict

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
