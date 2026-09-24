# Diverged Branches, Push Rejected

A push is rejected because the local branch and the remote branch each gained a commit since the last fetch. Interviewers use this because the reflex fix (`git push --force`) destroys the teammate's commit, while the correct path is a read-only diagnosis followed by an integrate-then-push.

---

## Symptom

> "I tried to push and got 'Updates were rejected'. It says the remote has work I do not have. I also have a commit I need to keep. Get my change pushed without losing anyone's work."

---

## Clarifying Questions

- **What exactly did the push print?** `(fetch first)` means the remote branch moved; `(non-fast-forward)` after a rewrite means local history was rewritten.
- **Is the branch shared?** A shared branch rules out force-pushing; the histories must be reconciled.
- **Do you want a linear history or is a merge commit fine?** That decides rebase versus merge.
- **Have you fetched yet?** Nothing about the remote is known until a fetch updates the tracking refs.

---

## Diagnostic Path

### 1. Read the Rejection

```bash
git push origin main
```

Output:

```text
To git@github.com:acme/shop.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to 'git@github.com:acme/shop.git'
hint: Updates were rejected because the remote contains work that you do not
```

`(fetch first)` is the key phrase: someone pushed to `main` after your last fetch, so your push would not fast-forward. This is never fixed by `--force`.

### 2. Fetch and See the Divergence

```bash
git fetch origin
git status -sb
git log --oneline --graph --all -4
```

Output:

```text
## main...origin/main [ahead 1, behind 1]
* 03e71b3 Add region
| * dffdfa0 Add retries
|/
* 8a9b30c Add config
```

`[ahead 1, behind 1]` confirms a true divergence: your `Add region` and the remote's `Add retries` both sit on the shared base `8a9b30c`. Neither is an ancestor of the other, so the branches must be reconciled before a push.

---

## Root Causes

| Cause | Evidence | Fix |
|---|---|---|
| Remote moved, local also committed | `[ahead N, behind M]` after fetch | `git pull --rebase` (or merge), then push |
| Local history rewritten (amend/rebase) | Push says `(non-fast-forward)` on your own branch | `git push --force-with-lease` |
| Someone else force-pushed | `origin/<branch>` jumped to an unrelated commit | Coordinate; fetch and rebase onto the new tip |
| Wrong branch targeted | Push targets a protected or unexpected branch | Push the feature branch and open a PR instead |

---

## Fix

For a shared branch, reconcile with a rebase to keep history linear, then push. The commits touch different files here, so the rebase is clean.

```bash
git pull --rebase
```

Output:

```text
From git@github.com:acme/shop.git
   22453c2..98c70dc  main       -> origin/main
Successfully rebased and updated refs/heads/main.
```

Your commit is replayed on top of the remote work, so the branch is now ahead by one with nothing behind.

```bash
git status -sb
git push origin main
```

Output:

```text
## main...origin/main [ahead 1]
   dffdfa0..22453c2  main -> main
```

The push fast-forwards. A plain `git pull` (merge) would also work and would add a merge commit instead; choose it when a merge commit is acceptable or the branch policy prefers merges. If the rebase had conflicted, you would resolve, `git add`, and `git rebase --continue`.

!!! danger "Never resolve a rejected push with git push --force"
    `--force` overwrites the remote and deletes the commit the teammate pushed. Integrate first (`pull --rebase` or `pull`), and if you genuinely must overwrite your own branch after a rewrite, use `--force-with-lease` so a concurrent push still blocks you.

---

## Prevention

- Pull (or fetch) before starting and before pushing, so divergence stays small.
- Set `pull.rebase=true` for a linear history on personal branches, or `pull.ff=only` to be forced to reconcile explicitly.
- Do feature work on branches and open pull requests, so `main` rarely receives direct pushes from two people at once.
- Protect shared branches on the host so force pushes are rejected server-side.

---

## Related

- [Pushing and Pulling](../../03-remotes-and-collaboration/pushing-and-pulling.md): rejection messages, `pull --rebase`, and `--force-with-lease`
- [Remotes](../../03-remotes-and-collaboration/remotes.md): fetch versus pull and what `origin/main` means
- [Rebasing](../../02-branching-and-merging/rebasing.md): the replay that reconciles the divergence
- [Merge Conflict Resolution](merge-conflict-resolution.md): when the reconcile hits a conflict

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
