# Forks and Pull Requests

A fork is a server-side copy of a repository you do not have write access to, and the pull request is how you propose your changes back. Interviewers ask about the fork model to check the two-remote setup (`origin` for your fork, `upstream` for the original) and how you keep a fork in sync.

**Track:** Workflow · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Fork | A server-side copy of a repo you can push to | the hosting platform |
| `origin` | Your fork (you have push access) | `git remote -v` |
| `upstream` | The original repository (usually read-only) | `git remote -v` |
| Add upstream | `git remote add upstream <original-url>` | `git remote -v` |
| Sync a fork | `git fetch upstream`, then update `main` from `upstream/main` | `git log` |
| Fast-forward only | `git merge --ff-only upstream/main` (no merge commit) | `git status -sb` |
| Contribute | Branch, push to `origin`, open a pull request | the platform |
| PR review, CODEOWNERS | Platform features, not Git itself | `delivery/github/` |
| Keep `main` clean | Work on branches, never commit to your fork's `main` | `git branch` |
<!-- --8<-- [end:facts] -->

---

## The Fork Model

You cannot push to a repository you do not have write access to, so the platform gives you a fork: your own server-side copy. You clone the fork (that clone's `origin`), and add the original repository as a second remote named `upstream` to pull its updates.

```bash
git remote add upstream git@github.com:acme/shop.git
git remote -v
```

Output:

```text
origin	git@github.com:me/shop.git (fetch)
origin	git@github.com:me/shop.git (push)
upstream	git@github.com:acme/shop.git (fetch)
upstream	git@github.com:acme/shop.git (push)
```

`origin` is your fork, where you push branches. `upstream` is the source; you fetch from it but normally do not push to it. Some teams set the `upstream` push URL to a dummy value to prevent an accidental push.

---

## Syncing Your Fork

A fork does not update itself when the original moves. Fetch `upstream` and fast-forward your `main` to `upstream/main`, then push that to your fork.

```bash
git fetch upstream
```

Output:

```text
From git@github.com:acme/shop.git
 * [new branch]      main       -> upstream/main
```

```bash
git switch main
git merge --ff-only upstream/main
```

Output:

```text
Updating ede4502..bce424e
Fast-forward
 app.py | 1 +
 1 file changed, 1 insertion(+)
```

`--ff-only` refuses to create a merge commit, which keeps your `main` an exact mirror of upstream. If it refuses because your `main` has its own commits, that is the signal you committed to `main` by mistake; move those commits to a branch first. Finish by pushing the synced `main` to your fork with `git push origin main`.

!!! note "Keep your fork's main a mirror, work on branches"
    Never commit directly to your fork's `main`. Keeping it identical to `upstream/main` means `--ff-only` always succeeds and every feature branch starts from the true upstream state, which avoids painful conflicts at pull-request time.

---

## The Pull Request Flow

Work goes on a branch pushed to your fork, and the pull request asks the original repository to merge it. The Git side is an ordinary branch and push.

```bash
git switch -c fix/typo
git push -u origin fix/typo
```

Output:

```text
To git@github.com:me/shop.git
 * [new branch]      fix/typo -> fix/typo
branch 'fix/typo' set up to track 'origin/fix/typo'.
```

Opening the pull request, requesting review, and the merge itself are platform features, not Git commands. Those live in the GitHub folder: pull request templates, CODEOWNERS review routing, and the merge strategies a maintainer picks.

!!! info "The pull request is a platform layer on top of Git"
    Git only pushes a branch to your fork. The comparison, review, checks and merge belong to the host. This split is why this folder covers the Git side and links out for the platform side rather than duplicating it.

---

## Common Errors

### `fatal: 'upstream' does not appear to be a git repository`

**Cause:** the `upstream` remote was never added, so a `git fetch upstream` has nothing to contact.

**Fix:** `git remote add upstream <original-url>`; confirm with `git remote -v`.

### `fatal: Not possible to fast-forward, aborting` on `git merge --ff-only upstream/main`

**Cause:** your `main` has commits that `upstream/main` does not, so a fast-forward is impossible; you committed to `main` directly.

**Fix:** move those commits to a branch (`git branch feature/x`; `git reset --hard upstream/main`), then re-sync.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a fork, and how does it differ from a branch?"
    **Say first:** a fork is a separate server-side copy of a repository you do not have write access to; a branch is a line of work inside one repository. You push to your fork and propose changes back with a pull request.

    **Proof:** `git remote -v` on a fork clone shows `origin` (your fork) and usually an added `upstream` (the original).

    **Follow-up:** How do you keep your fork up to date with the original?

??? question "L1: How do you keep a fork in sync with the upstream repository?"
    **Say first:** add the original as `upstream`, `git fetch upstream`, fast-forward your `main` to `upstream/main`, and push it to your fork.

    **Proof:** `git merge --ff-only upstream/main` updates `main` with no merge commit; `git push origin main` publishes it.

    **Follow-up:** What does `--ff-only` protect you from?
<!-- --8<-- [end:l1] -->

??? question "L2: Set up a fresh fork clone so you can pull upstream changes and push your own."
    **Say first:** clone your fork (that is `origin`), then add the original as `upstream`.

    **Proof:**

    ```bash
    git clone git@github.com:me/shop.git
    git remote add upstream git@github.com:acme/shop.git
    ```

    **Follow-up:** Why might you disable the push URL on `upstream`?

??? question "L2: Prepare a change for a pull request from your fork."
    **Say first:** branch from an up-to-date `main`, commit, and push the branch to `origin`.

    **Proof:** `git switch -c fix/typo` then `git push -u origin fix/typo`; open the PR on the platform.

    **Follow-up:** Which parts of the pull request are Git and which are the hosting platform?

??? question "L3: Your fast-forward sync suddenly fails, saying it cannot fast-forward. What happened?"
    **Say first:** your `main` diverged from `upstream/main`, almost always because a commit landed on `main` directly instead of a branch.

    **Proof:** `git log upstream/main..main` lists the stray commits; move them to a branch, then `git reset --hard upstream/main`.

    **Follow-up:** How would you prevent committing to `main` on a fork in future?

??? question "L2: Rebase your feature branch onto the latest upstream before opening a pull request."
    **Say first:** sync `main` from `upstream`, then rebase the feature branch onto it so the PR applies cleanly.

    **Proof:**

    ```bash
    git fetch upstream
    git rebase upstream/main    # while on the feature branch
    git push --force-with-lease origin <branch>
    ```

    **Follow-up:** Why is `--force-with-lease` needed after the rebase?

---

## Related

- [Remotes](remotes.md): the `origin` plus `upstream` two-remote setup
- [Pushing and Pulling](pushing-and-pulling.md): pushing the branch a pull request is built from
- [Accidental Commit to Main](../interview/scenarios/accidental-commit-to-main.md): fixing the stray-commit-on-main case that breaks a fork sync
- [CODEOWNERS](../../github/codeowners.md): the platform side of pull request review

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
