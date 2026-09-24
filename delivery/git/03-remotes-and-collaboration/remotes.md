# Remotes

A remote is a named URL for another copy of the repository, and remote-tracking branches are the local cache of where that copy's branches were at the last fetch. Interviewers start here because "fetch versus pull" and "what is `origin/main`" separate people who understand Git's distributed model from those who memorised commands.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Remote | A named URL for another repository | `git remote -v` |
| `origin` | The default name for the clone source | `git remote` |
| Remote-tracking branch | `origin/main`, a local cache of the remote's `main` | `git branch -r` |
| `git fetch` | Updates remote-tracking refs only; no working change | `git branch -r` |
| `git pull` | `git fetch` then integrate (merge or rebase) | `git status -sb` |
| Add | `git remote add <name> <url>` | `git remote -v` |
| Rename | `git remote rename <old> <new>` | `git remote` |
| Change URL | `git remote set-url <name> <url>` | `git remote -v` |
| Inspect | `git remote show <name>` | the output |
| Prune stale | `git remote prune <name>` or `git fetch --prune` | `git branch -r` |
| Ahead/behind | `git status -sb` against the upstream | `git status -sb` |
<!-- --8<-- [end:facts] -->

---

## What a Remote Is

Cloning records the source URL under the name `origin`, and `git remote -v` prints each remote's fetch and push URLs. A repository can have several remotes (for example `origin` and an `upstream` fork source).

```bash
git remote -v
```

Output:

```text
origin	git@github.com:acme/shop.git (fetch)
origin	git@github.com:acme/shop.git (push)
```

The fetch and push URLs are usually identical, but they can differ, for example to fetch over HTTPS and push over SSH. A remote is only a label and a URL; it holds no branches itself until a fetch populates the tracking refs.

---

## Inspecting a Remote

`git remote show <name>` queries the remote and reports its branches, which local branch tracks which, and whether each is up to date.

```bash
git remote show origin
```

Output:

```text
* remote origin
  Fetch URL: git@github.com:acme/shop.git
  Push  URL: git@github.com:acme/shop.git
  HEAD branch: main
  Remote branch:
    main tracked
  Local branch configured for 'git pull':
    main merges with remote main
  Local ref configured for 'git push':
    main pushes to main (up to date)
```

"HEAD branch" is the remote's default branch, the one a fresh clone checks out. The "configured for git pull" and "configured for git push" lines show the tracking relationships that let `git pull` and `git push` run with no arguments.

---

## Remote-Tracking Branches

`origin/main` is not the remote's branch; it is a local, read-only pointer recording where `origin`'s `main` was at the last fetch. `git branch -r` lists these tracking refs.

```bash
git branch -r
```

Output:

```text
  origin/HEAD -> origin/main
  origin/feature/promo
  origin/main
```

`origin/HEAD` is a symbolic ref naming the remote's default branch. These refs move only when you fetch; they are the baseline `git status` uses to say how far ahead or behind your local branch is.

!!! info "origin/main is a cache, not the live remote"
    `git log origin/main` shows the remote's history as of your last fetch, not its current state. To know whether the remote moved, you must `git fetch` first; nothing about the remote updates on its own.

---

## Fetch Versus Pull

`git fetch` downloads new commits and updates the remote-tracking refs, but does not touch your working branch or files. It is always safe.

```bash
git fetch origin
```

Output:

```text
From git@github.com:acme/shop.git
   059ac4e..d7566c0  main          -> origin/main
 * [new branch]      feature/promo -> origin/feature/promo
```

After the fetch, the local branch is unchanged, so `git status` reports it as behind.

```bash
git status -sb
```

Output:

```text
## main...origin/main [behind 1]
```

`git pull` is `git fetch` followed by integrating the upstream into the current branch. When the local branch has no commits of its own, that integration is a fast-forward.

```bash
git pull origin main
```

Output:

```text
From git@github.com:acme/shop.git
 * branch            main       -> FETCH_HEAD
Updating 059ac4e..d7566c0
Fast-forward
 service.yml | 1 +
 1 file changed, 1 insertion(+)
```

Fetch first when you only want to see what changed; pull when you are ready to integrate it. The merge-versus-rebase choice `pull` makes is the subject of [Pushing and Pulling](pushing-and-pulling.md).

---

## Pruning Stale Tracking Branches

When a branch is deleted on the remote, its tracking ref lingers locally until pruned. `git remote prune` (or `git fetch --prune`) removes refs whose remote branch is gone.

```bash
git remote prune origin
```

Output:

```text
Pruning origin
URL: git@github.com:acme/shop.git
 * [pruned] origin/feature/promo
```

Set `fetch.prune=true` to make every `git fetch` prune automatically, which keeps `git branch -r` honest on a busy repository. Pruning removes only the stale tracking ref, never a local branch.

---

## Managing Remotes

Most remote management commands print nothing on success; confirm with `git remote -v`.

| Task | Command |
|---|---|
| Add a remote | `git remote add upstream <url>` |
| Rename a remote | `git remote rename origin old-origin` |
| Remove a remote | `git remote remove <name>` |
| Change a remote's URL | `git remote set-url origin <new-url>` |
| Add a push-only mirror URL | `git remote set-url --add --push origin <url>` |

A common setup for a fork adds `upstream` for the original repository while `origin` stays the fork, which is covered in [Forks and Pull Requests](forks-and-pull-requests.md).

!!! note "Switching SSH and HTTPS is a set-url, not a re-clone"
    A "permission denied (publickey)" or repeated password prompt is often the wrong protocol on the remote URL. `git remote set-url origin` swaps between the `git@host:owner/repo.git` (SSH) and `https://host/owner/repo.git` (HTTPS) forms without re-cloning.

---

## Common Errors

### `fatal: 'origin' does not appear to be a git repository`

**Cause:** no remote named `origin` exists, often in a repository created with `git init` that was never given a remote.

**Fix:** add one with `git remote add origin <url>`; confirm with `git remote -v`.

### `fatal: couldn't find remote ref <branch>`

**Cause:** a fetch or pull named a branch that does not exist on the remote, usually a typo or a branch deleted upstream.

**Fix:** list remote branches with `git ls-remote --heads origin`; fetch the correct name, or `git remote prune origin` if it was deleted.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between git fetch and git pull?"
    **Say first:** `git fetch` downloads new commits and updates remote-tracking refs but leaves your branch and files untouched; `git pull` is a `fetch` followed by integrating the upstream into your current branch.

    **Proof:** after `git fetch`, `git status` shows the branch as "behind"; `git pull` then fast-forwards or merges it.

    **Follow-up:** What exactly is `origin/main`?

??? question "L1: What is origin/main, and does it show the remote's current state?"
    **Say first:** it is a local remote-tracking branch, a read-only cache of where `origin`'s `main` was at your last fetch, not the remote's live state.

    **Proof:** `git branch -r` lists it; it only moves when you `git fetch`.

    **Follow-up:** How do you find out whether the remote has moved since you last looked?
<!-- --8<-- [end:l1] -->

??? question "L2: You cloned over HTTPS but want to push over SSH without re-cloning. How?"
    **Say first:** change the remote URL with `git remote set-url`.

    **Proof:**

    ```bash
    git remote set-url origin git@github.com:acme/shop.git
    git remote -v
    ```

    **Follow-up:** How would you fetch over HTTPS but push over SSH on the same remote?

??? question "L2: A deleted upstream branch still shows in git branch -r. Clean it up."
    **Say first:** `git remote prune origin` (or `git fetch --prune`) removes tracking refs whose remote branch is gone.

    **Proof:** `git branch -r` no longer lists the pruned ref.

    **Follow-up:** How do you make every fetch prune automatically?

??? question "L3: A teammate says they pushed a fix an hour ago, but you do not see it. Walk through what you check."
    **Say first:** your remote-tracking refs are a cache, so fetch first, then compare; the fix may be there but not yet fetched, on a different branch, or not actually pushed.

    **Proof:** `git fetch origin`, then `git log --oneline origin/main -3` and `git status -sb`; `git ls-remote origin` confirms what the remote actually holds.

    **Follow-up:** What would `git ls-remote` show that `git branch -r` would not?

??? question "L4: How does Git know which remote branch your local branch tracks, and where is that stored?"
    **Say first:** the tracking relationship is stored in `.git/config` as `branch.<name>.remote` and `branch.<name>.merge`, set by `clone` or `push -u`, and it is what lets `git pull`/`git push` run with no arguments.

    **Proof:** `git config branch.main.remote` prints `origin`; `git remote show origin` reports the same "configured for git pull/push" lines.

    **Don't say:** "The name `origin/main` by itself makes it track." The config keys, not the ref name, define tracking.

---

## Related

- [Pushing and Pulling](pushing-and-pulling.md): upstreams, `pull --rebase`, and safe force-pushing
- [Branches](../02-branching-and-merging/branches.md): local branches and the upstream they track
- [Forks and Pull Requests](forks-and-pull-requests.md): the `origin` plus `upstream` remote setup
- [Diverged Branches, Push Rejected](../interview/scenarios/diverged-branches-push-rejected.md): what happens when local and remote both moved

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
