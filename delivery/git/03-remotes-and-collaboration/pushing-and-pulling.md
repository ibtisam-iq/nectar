# Pushing and Pulling

Pushing sends local commits to a remote; pulling brings remote commits into a local branch. Interviewers focus here on two decisions that break teams: whether a pull merges or rebases, and why `--force-with-lease` is the only safe way to overwrite a shared branch.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Set upstream | `git push -u origin <branch>` on the first push | `git status -sb` |
| Push | `git push` once an upstream is set | `git status -sb` |
| Rejected push | Remote moved: `! [rejected] ... (fetch first)` | the push output |
| Pull (merge) | `git pull` (default) fetches then merges | `git log --graph` |
| Pull (rebase) | `git pull --rebase` replays local commits on top | `git log --oneline` |
| Config the default | `pull.rebase=true`, or `pull.ff=only` | `git config pull.rebase` |
| Force (unsafe) | `git push --force` overwrites whatever is there | remote history |
| Force safely | `git push --force-with-lease` refuses if the remote moved | the push output |
| Delete remote branch | `git push origin --delete <branch>` | `git branch -r` |
| Push tags | `git push --tags` or `git push origin <tag>` | `git ls-remote --tags` |
<!-- --8<-- [end:facts] -->

---

## Pushing and the Upstream

The first push of a new branch uses `-u` (`--set-upstream`) to record which remote branch it tracks, so later `git push` and `git pull` need no arguments.

```bash
git push -u origin feature/checkout
```

Output:

```text
To git@github.com:acme/shop.git
 * [new branch]      feature/checkout -> feature/checkout
branch 'feature/checkout' set up to track 'origin/feature/checkout'.
```

The tracking relationship shows up in the status header.

```bash
git status -sb
```

Output:

```text
## feature/checkout...origin/feature/checkout
```

The `...origin/feature/checkout` suffix confirms the upstream is set. Without it, a bare `git push` would ask which remote and branch to use.

---

## When a Push Is Rejected

A push only fast-forwards the remote branch. If the remote moved since your last fetch, the push is rejected to avoid discarding those commits.

```bash
git push origin main
```

Output:

```text
To git@github.com:acme/shop.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to 'git@github.com:acme/shop.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
```

`(fetch first)` means someone pushed to `main` after you last fetched. The fix is never `--force`; it is to integrate the remote work, then push.

---

## Reconciling: Rebase or Merge

`git pull --rebase` fetches the remote commits and replays your local commits on top, producing a linear history with no merge commit.

```bash
git pull --rebase origin main
```

Output:

```text
From git@github.com:acme/shop.git
 * branch            main       -> FETCH_HEAD
   82f35ba..0f89206  main       -> origin/main
Successfully rebased and updated refs/heads/main.
```

The push then fast-forwards, because the local branch now sits directly on top of the remote tip.

```bash
git push origin main
git log --oneline -3
```

Output:

```text
   0f89206..29ea727  main -> main
29ea727 Add region config
0f89206 Enable metrics
82f35ba Set timeout
```

The local `Add region config` was replayed on top of the teammate's `Enable metrics`, keeping history straight. A plain `git pull` would instead create a merge commit; set `pull.rebase=true` to make rebase the default, or `pull.ff=only` to refuse to auto-merge and force an explicit choice.

!!! warning "Rebasing during a pull rewrites your local commits"
    `git pull --rebase` gives new SHAs to the commits it replays, which is fine for local, unpushed work. Do not rebase commits you have already pushed and shared, the same golden rule as any rebase.

---

## Force-With-Lease Versus Force

Rewriting a pushed branch (an amend or rebase) makes the next push non-fast-forward, so it is rejected.

```bash
git commit --amend -m "Add checkout"
git push origin feature/checkout
```

Output:

```text
To git@github.com:acme/shop.git
 ! [rejected]        feature/checkout -> feature/checkout (non-fast-forward)
```

`--force-with-lease` overwrites the remote branch, but only if it still points where your last fetch said, so it cannot clobber a commit someone pushed in the meantime.

```bash
git push --force-with-lease origin feature/checkout
```

Output:

```text
To git@github.com:acme/shop.git
 + 4dc90fd...e468797 feature/checkout -> feature/checkout (forced update)
```

If a teammate had pushed to the branch since your last fetch, the lease check fails and the push is refused.

```bash
git push --force-with-lease origin feature/checkout
```

Output:

```text
To git@github.com:acme/shop.git
 ! [rejected]        feature/checkout -> feature/checkout (stale info)
error: failed to push some refs to 'git@github.com:acme/shop.git'
```

`(stale info)` is the safety net: the remote moved, so the force is blocked. A plain `git push --force` would have overwritten the teammate's commit without warning, which is why `--force-with-lease` is the correct default.

!!! danger "Never git push --force to a shared branch"
    `--force` overwrites the remote regardless of what is there, silently deleting commits others pushed. Always use `--force-with-lease`, and fetch first so the lease reflects the true remote state; better still, only force branches that are yours alone.

---

## Common Errors

### `! [rejected] <branch> -> <branch> (fetch first)`

**Cause:** the remote branch has commits your local branch does not, so a fast-forward is impossible.

**Fix:** `git pull` (or `git pull --rebase`) to integrate, then push; never `--force` to resolve this.

### `fatal: The current branch <name> has no upstream branch`

**Cause:** the branch was never pushed with `-u`, so `git push` does not know where to send it.

**Fix:** `git push -u origin <name>` once; subsequent pushes need no arguments.

### `! [rejected] <branch> -> <branch> (stale info)`

**Cause:** a `--force-with-lease` push found the remote branch had moved since your last fetch, so the lease check refused it.

**Fix:** `git fetch`, review the new commits, and only re-force if you are sure they should be overwritten.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Your push was rejected with 'fetch first'. What does that mean and what do you do?"
    **Say first:** the remote branch has commits you do not have, so the push cannot fast-forward; you integrate the remote work with `git pull` (or `pull --rebase`), then push.

    **Proof:** the rejection names `(fetch first)`; after `git pull --rebase origin main` the push fast-forwards.

    **Follow-up:** Why is `git push --force` the wrong answer here?

??? question "L1: What is the difference between git pull and git pull --rebase?"
    **Say first:** plain `git pull` fetches then merges, creating a merge commit when both sides moved; `git pull --rebase` fetches then replays your local commits on top, keeping history linear.

    **Proof:** after `--rebase`, `git log --oneline` shows your commit above the remote's with no merge commit.

    **Follow-up:** How do you make rebase the default for pulls?
<!-- --8<-- [end:l1] -->

??? question "L2: Push a brand-new branch and set it to track its remote."
    **Say first:** `git push -u origin <branch>` pushes and records the upstream in one step.

    **Proof:**

    ```bash
    git push -u origin feature/checkout
    git status -sb   # shows ...origin/feature/checkout
    ```

    **Follow-up:** What does the `-u` actually write, and where?

??? question "L2: You amended a commit you already pushed on your own feature branch. Update the remote safely."
    **Say first:** `git push --force-with-lease`, which overwrites only if the remote is still where you last saw it.

    **Proof:** a plain push is rejected `(non-fast-forward)`; `--force-with-lease` succeeds with `(forced update)`.

    **Follow-up:** What does `--force-with-lease` do that `--force` does not?

??? question "L3: You force-pushed and a teammate says their commit vanished from the branch. What happened and how do you recover it?"
    **Say first:** a plain `--force` overwrote the remote and dropped their commit; it is recoverable because the commit still exists in a reflog or their local clone.

    **Proof:** the teammate's `git reflog` or `git log origin/<branch>@{1}` names the lost tip; re-push it or cherry-pick it back.

    **Follow-up:** How would `--force-with-lease` have prevented this in the first place?

??? question "L4: How does --force-with-lease know the remote moved, when git push cannot see the remote's live state?"
    **Say first:** it compares the remote-tracking ref from your last fetch against the remote's current value during the push; if they differ, the lease is stale and the push is refused.

    **Proof:** the refusal prints `(stale info)`; a `git fetch` that updates the tracking ref changes the lease and can make the same push succeed.

    **Don't say:** "It checks the remote in real time before deciding." It relies on your last-fetched tracking ref as the expected value.

---

## Related

- [Remotes](remotes.md): remote-tracking refs and fetch versus pull
- [Rebasing](../02-branching-and-merging/rebasing.md): the replay that `pull --rebase` performs, and the golden rule
- [Diverged Branches, Push Rejected](../interview/scenarios/diverged-branches-push-rejected.md): the rejected-push symptom worked end to end
- [Tags and Releases](tags-and-releases.md): pushing tags, which do not travel with a normal push

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
