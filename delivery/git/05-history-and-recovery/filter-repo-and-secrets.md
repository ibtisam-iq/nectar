# Filter-Repo and Secrets

A committed secret does not go away when you delete the file in a new commit; it stays in history and in every clone. Interviewers ask about this because the correct response is two steps that people forget to pair: rotate the credential (it is already compromised) and rewrite history with `git filter-repo` to purge it.

**Track:** Advanced · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| First response | Rotate the secret; assume it is already leaked | the provider |
| Tool | `git filter-repo` (separate install, not built in) | `git filter-repo --version` |
| Remove a file | `git filter-repo --path <file> --invert-paths` | `git log -- <file>` |
| Scrub a string | `git filter-repo --replace-text <rules>` | `git log -p` |
| Replacement rule | `secret==>REDACTED` per line in the rules file | the file |
| Rewrites everything | Every affected commit gets a new SHA | `git log --oneline` |
| Old tool | `git filter-branch` is slow and error-prone; avoid | Git docs |
| Alternative | BFG Repo-Cleaner, fast for blobs and strings | BFG docs |
| After rewrite | Force-push, and every clone must re-clone or reset | team coordination |
| Not a substitute | Rewriting does not un-leak; rotation does | incident process |
<!-- --8<-- [end:facts] -->

---

## Why gitignore Is Not Enough

Adding a secret file to `.gitignore` or removing it in a new commit leaves it in every earlier commit, so anyone with the history (or a fork, or a cached view) can still read it. The secret is compromised the moment it is pushed.

So the response is two independent steps. First, rotate the credential, because history rewriting cannot recall what others already fetched. Second, rewrite history to remove the secret from the repository going forward.

!!! danger "Rotate first: rewriting history does not un-leak a secret"
    By the time you notice, the secret may be in clones, forks, CI logs and backups. Rewriting your repository removes it there but cannot reach those copies. Treat any committed credential as burned and rotate it immediately; the history rewrite is cleanup, not containment.

---

## Removing a File from All History

`git filter-repo --path <file> --invert-paths` rewrites every commit to exclude the file, as if it had never been committed. `filter-repo` is a separate tool (installed via `pip install git-filter-repo` or a package manager), not part of core Git.

```bash
git filter-repo --path .env --invert-paths --force
git log --oneline
```

Output:

```text
609a730 Add feature
7fe301d Add app
```

The `Add config (oops, secret)` commit is gone, and `git log -- .env` now returns nothing: no commit touches the file. Commits after the removed content have new SHAs, because history was rewritten.

---

## Scrubbing a Secret String

When the secret sits inside a file you want to keep, `--replace-text` swaps the string in every version of the file. The rules file holds one `pattern==>replacement` per line.

```bash
printf 'sk_live_abcd1234SECRET==>REDACTED\n' > replacements.txt
git filter-repo --replace-text replacements.txt --force
git log -p --all | grep -i 'token:' | sort -u
```

Output:

```text
 token: REDACTED
+token: REDACTED
```

Every historical version of the token now reads `REDACTED`; the original string appears in no commit. This keeps the config file and its other history intact while purging only the secret.

---

## After the Rewrite

Rewriting history changes SHAs, so the rewritten branch must be force-pushed, and every other clone is now incompatible. The team must re-clone or hard-reset to the rewritten history, because a normal pull would reintroduce the old commits.

Coordinate the force-push, tell everyone to re-clone, and have the host garbage-collect (on a hosted platform, open a support request to purge cached views and pull-request refs). `git filter-repo` also removes the origin remote by default, a deliberate guard so you do not push a half-finished rewrite.

!!! note "filter-repo replaces filter-branch; BFG is an alternative"
    `git filter-branch` is the old built-in and is slow, error-prone and officially discouraged. Use `git filter-repo` for path and text rewrites, or the BFG Repo-Cleaner for a fast pass over large blobs and secret strings. Do not reach for `filter-branch`.

---

## Common Errors

### `git: 'filter-repo' is not a git command`

**Cause:** `git-filter-repo` is not installed; it is a separate tool, not part of core Git.

**Fix:** install it (`pip install git-filter-repo`, or via your package manager), then re-run.

### `Aborting: Refusing to destructively overwrite repo history since this does not look like a fresh clone`

**Cause:** `filter-repo` guards against running on a repository with other state, to avoid a half-done rewrite.

**Fix:** run it on a fresh clone, or pass `--force` when you are sure; keep a backup clone first.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: You committed and pushed a secret. What is the first thing you do?"
    **Say first:** rotate the secret immediately; it is already exposed, and no history rewrite can recall what others have fetched. Then rewrite history to purge it.

    **Proof:** the secret sits in every earlier commit and every clone; rotation invalidates it, `git filter-repo` removes it from the repo.

    **Follow-up:** Why is deleting the file in a new commit not enough?
<!-- --8<-- [end:l1] -->

??? question "L2: Remove a committed secrets file from the entire history of a repository."
    **Say first:** use `git filter-repo --path <file> --invert-paths` on a fresh clone, then force-push and have everyone re-clone.

    **Proof:**

    ```bash
    git filter-repo --path .env --invert-paths
    git log -- .env   # now empty
    ```

    **Follow-up:** What if the secret is a string inside a file you need to keep?

??? question "L2: Scrub an API token string from all history while keeping the file it lived in."
    **Say first:** `git filter-repo --replace-text` with a rules file mapping the secret to a placeholder.

    **Proof:** `printf 'TOKEN==>REDACTED\n' > rules.txt; git filter-repo --replace-text rules.txt`; the string is gone from every version.

    **Follow-up:** Why prefer `filter-repo` over `git filter-branch`?

??? question "L2: After purging a secret and force-pushing, a teammate's next push brings it back. Why?"
    **Say first:** their clone still has the old history, so pushing (or merging) reintroduces the removed commits; everyone must re-clone or hard-reset to the rewritten history.

    **Proof:** their `git log` still shows the old SHAs; a fresh clone or `git reset --hard origin/main` after the rewrite aligns them.

    **Follow-up:** What host-side cleanup is still needed for cached views and PR refs?

??? question "L3: A secret was in the repo for months across many branches and a few forks. What is your full plan?"
    **Say first:** rotate the credential first, then rewrite all refs with `filter-repo`, force-push every branch, ask contributors to re-clone, and ask the host to purge caches and PR refs; treat the fork copies as still exposed.

    **Proof:** `git filter-repo --replace-text` (or `--path`) over `--all`; coordinate the force-push and platform cleanup; monitor for use of the old credential.

    **Follow-up:** Which of these steps actually contains the leak, and which are cleanup?

??? question "L4: Why does removing a file from history change commit SHAs, and what does that force on collaborators?"
    **Say first:** each commit's tree changes when the file is dropped, and a commit's SHA hashes its tree and parent, so the touched commits and all their descendants get new ids; collaborators' clones then reference commits that no longer exist and must re-clone or reset.

    **Proof:** `git log --oneline` shows new SHAs after `filter-repo`; a normal pull would reintroduce the old history, which is why re-cloning is required.

    **Don't say:** "You can force-push and everyone keeps working." Their old commits would merge the secret back in.

---

## Related

- [Rewriting History](rewriting-history.md): what rewriting means and the golden rule
- [Ignoring and Attributes](../01-core-workflow/ignoring-and-attributes.md): keeping secrets out with `.gitignore` in the first place
- [Committed a Secret](../interview/scenarios/committed-a-secret.md): this response worked as a full incident
- [Reflog and Recovery](reflog-and-recovery.md): why old objects linger until `gc`, relevant when purging

Captured on macOS 26 with git 2.50.1 and git-filter-repo (throwaway local repositories), 2026-09.
