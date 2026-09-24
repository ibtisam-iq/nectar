# History Surgery

Reshape history safely: squash a messy branch into one clean commit, amend its message, then purge a leaked secret from all of history and update a remote with a safe force. The rule throughout is the golden rule: rewrite only local or personal branches, and never a shared one without agreement.

---

## Setup

Use a throwaway repository with a bare remote so the force-push step is real.

```bash
mkdir -p /tmp/git-surgery && cd /tmp/git-surgery
git init --bare origin.git
git clone ./origin.git work && cd work
git config user.name "Amina Yusuf"
git config user.email "amina@example.com"
```

`git-filter-repo` must be installed (`pip install git-filter-repo`); it is a separate tool, not part of core Git. Delete the directory when done.

!!! warning "These steps rewrite history and force-push"
    Every task here creates new SHAs and, at the end, overwrites a remote branch. Do this only on a throwaway repo or a branch that is genuinely yours. On a shared branch, agree with the team first, or use `git revert` instead.

---

## Squashing a Messy Branch

### 1. Create a Messy Feature Branch

Build a branch of `wip`/`fix`/`fix again` commits, the kind you would tidy before a PR.

??? tip "Solution"
    ```bash
    git commit --allow-empty -m "feat: base" && git push -u origin main
    git switch -c feature
    for m in "wip" "fix" "fix again please"; do
      printf 'change %s\n' "$m" >> app.txt; git add app.txt; git commit -m "$m"
    done
    git log --oneline main..feature
    ```

    Output:

    ```text
    0012390 fix again please
    584883d fix
    cc5acc8 wip
    ```

    Three commits that say nothing useful. The plan is to collapse them into one before review.

### 2. Squash Them into One Commit

Use an interactive rebase onto `main`, marking every commit after the first as `squash` (or `fixup`).

??? tip "Solution"
    ```bash
    git rebase -i main
    # in the editor: keep the first as 'pick', change the rest to 'squash'
    ```

    Output:

    ```text
    Successfully rebased and updated refs/heads/feature.
    ```

    ```bash
    git log --oneline main..feature
    ```

    Output:

    ```text
    b236c01 feat: add three lines to app
    ```

    The three commits are now one, with new SHAs. This is safe because `feature` is local and unshared.

### 3. Fix the Message with Amend

Rewrite the single commit's message without changing its content.

??? tip "Solution"
    ```bash
    git commit --amend -m "feat: add three configuration lines to app"
    git log --oneline main..feature
    ```

    Output:

    ```text
    e9e467d feat: add three configuration lines to app
    ```

    `--amend` replaces the last commit with a new one carrying the better message. The SHA changes again, which is why amend is safe only before sharing.

---

## Purging a Secret

### 4. Confirm a Secret Is in History

In a fresh clone, a `.env` was committed and pushed, then deleted in a later commit. Prove the secret still lives in history.

??? tip "Solution"
    ```bash
    git log --all -p | grep -c 'sk_live_abc123SECRET'
    ```

    Output:

    ```text
    2
    ```

    Two objects still contain the token (the add and the content), even though the file was later removed. Deleting a file in a new commit does not erase its past. Rotate the credential first at its provider; the rest is cleanup.

### 5. Remove It from Every Commit

Rewrite history with `git filter-repo` to drop the file entirely.

??? tip "Solution"
    ```bash
    git filter-repo --path .env --invert-paths --force
    git log --all -p | grep -c 'sk_live_abc123SECRET'
    ```

    Output:

    ```text
    0
    ```

    No object holds the secret now. If the secret lived inside a file you must keep, use `git filter-repo --replace-text rules.txt` instead, mapping the string to a placeholder.

---

## Updating the Remote Safely

### 6. Force-Push the Rewritten History

`filter-repo` removes the remote as a safety measure. Re-add it, and use `--force-with-lease` to overwrite the branch without clobbering unseen work.

??? tip "Solution"
    ```bash
    git remote add origin ../origin.git
    git push --force-with-lease origin main
    ```

    Output:

    ```text
    To origin
     ! [rejected]        main -> main (stale info)
    error: failed to push some refs to 'origin'
    ```

    The lease has no remote-tracking ref to compare against yet, so it refuses. Fetch first to establish it, then push again.

    ```bash
    git fetch origin
    git push --force-with-lease origin main
    ```

    Output:

    ```text
    To origin
     + 1bc8595...66d7f4c main -> main (forced update)
    ```

    The remote is updated, and `--force-with-lease` confirmed the remote was where you last saw it before overwriting. After this, every collaborator must re-clone, because their old history still holds the secret.

---

## Cleanup

```bash
cd /tmp && rm -rf git-surgery
```

You squashed a branch, amended a message, purged a secret from all history, and force-pushed safely. Two rules carried through: rewrite only before sharing, and after any secret leak, rotate the credential regardless of the rewrite.

---

## Related

- [Rewriting History](../05-history-and-recovery/rewriting-history.md): amend, reset, rebase and the golden rule
- [Filter-Repo and Secrets](../05-history-and-recovery/filter-repo-and-secrets.md): the purge tool and the rotate-first rule
- [Interactive Rebase](../02-branching-and-merging/interactive-rebase.md): squash, fixup, reword and reorder
- [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md): `--force-with-lease` and the `(stale info)` refusal

Captured on macOS 26 with git 2.50.1 and git-filter-repo (throwaway local repositories), 2026-09.
