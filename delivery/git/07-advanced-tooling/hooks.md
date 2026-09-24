# Hooks

Hooks are scripts Git runs at fixed points in its workflow, such as before a commit or before a push. Interviewers ask about them because they are how teams enforce standards locally, and because a candidate who knows they are bypassable understands their real security value.

**Track:** Advanced · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Location | `.git/hooks/`, one executable per hook name | `ls .git/hooks` |
| Not committed | `.git/` is local, so hooks do not travel with a clone | clone and check |
| Shared hooks | Version a directory and point `core.hooksPath` at it | `git config core.hooksPath` |
| Client hooks | `pre-commit`, `commit-msg`, `pre-push`, `post-checkout` | run locally |
| Server hooks | `pre-receive`, `update`, `post-receive` | run on the remote |
| Exit code | Non-zero from a `pre-*` hook aborts the action | the hook output |
| Bypass | `git commit --no-verify` skips `pre-commit`/`commit-msg` | the commit succeeds |
| Sample hooks | `.sample` suffix means disabled; rename to enable | `ls .git/hooks` |
| pre-commit framework | A tool that manages hooks from a config file | `.pre-commit-config.yaml` |
| Enforcement | Local hooks are advisory; CI is the real gate | team policy |
<!-- --8<-- [end:facts] -->

---

## Where Hooks Live

Every repository ships a set of sample hooks in `.git/hooks/`, each with a `.sample` suffix so Git ignores it. Renaming one to drop the suffix and making it executable enables it.

```bash
ls .git/hooks
```

Output:

```text
applypatch-msg.sample     pre-merge-commit.sample   prepare-commit-msg.sample
commit-msg.sample         pre-push.sample           push-to-checkout.sample
fsmonitor-watchman.sample pre-rebase.sample         sendemail-validate.sample
post-update.sample        pre-receive.sample        update.sample
pre-applypatch.sample     pre-commit.sample
```

A hook is any executable named exactly for the event (`pre-commit`, no suffix). Git runs it at that point and reads its exit code.

---

## A pre-commit Hook That Blocks Bad Content

The `pre-commit` hook runs before the commit message is requested. A non-zero exit aborts the commit, which is how a check refuses to let something in.

```bash
cat .git/hooks/pre-commit
```

Output:

```text
#!/bin/sh
if git diff --cached | grep -q 'TODO'; then
	echo "pre-commit: staged change contains a TODO marker; aborting."
	exit 1
fi
```

Staging a change with a `TODO` and committing shows the hook refusing it.

```bash
git commit -m "Add app"
```

Output:

```text
pre-commit: staged change contains a TODO marker; aborting.
```

The commit did not happen; the exit code of `1` stopped it. Removing the marker and committing again succeeds, because the hook exits `0`.

---

## Bypassing a Hook

Client hooks live in `.git/`, which the author controls, so they are advisory rather than enforced. `git commit --no-verify` skips both `pre-commit` and `commit-msg`.

```bash
git commit --no-verify -m "Add note (bypassed)"
```

The commit succeeds even though its content would have tripped the hook. This is the point interviewers probe: a local hook catches honest mistakes early, but it cannot enforce policy, because anyone can skip it or delete the file.

!!! warning "Local hooks are advisory, not a security control"
    A `pre-commit` or `pre-push` hook helps the author, and `--no-verify` removes it in one flag. Real enforcement lives on the server (`pre-receive`) or in CI, where the author cannot bypass it. Treat client hooks as fast feedback, not a gate.

---

## commit-msg: Validating the Message

The `commit-msg` hook receives the path to a file holding the draft message, so it can check or reject the wording. This one requires a Conventional Commits prefix.

```bash
cat .git/hooks/commit-msg
git commit -m "bad message"
```

Output:

```text
commit-msg: message must start with feat/fix/docs/chore:
```

The commit is refused until the message matches, for example `fix: correct message format`. The full commit-message convention this enforces is in [Commit Conventions](../04-team-workflows/commit-conventions.md).

---

## Sharing Hooks With a Team

Because `.git/hooks/` is never cloned, a hook one person writes does not reach anyone else. The fix is to commit the hooks into a tracked directory and point `core.hooksPath` at it.

```bash
git config core.hooksPath .githooks
git config core.hooksPath
```

Output:

```text
.githooks
```

Now the versioned `.githooks/` directory supplies the hooks, so a clone plus this one config line gives everyone the same checks. In practice most teams use the pre-commit framework, which manages this from a `.pre-commit-config.yaml` and installs the hook for each developer.

!!! tip "Use core.hooksPath or the pre-commit framework for shared hooks"
    Committing hooks under `.githooks/` and setting `core.hooksPath` makes them reviewable and shared. The [pre-commit](https://pre-commit.com) framework goes further: it pins hook versions in a config file and runs linters and secret scanners without each person copying scripts by hand.

---

## Client Versus Server Hooks

The distinction that matters in interviews is where the hook runs and therefore who can skip it.

| Kind | Examples | Runs on | Bypassable by author |
|---|---|---|---|
| Client | `pre-commit`, `commit-msg`, `pre-push` | the developer's machine | yes (`--no-verify`) |
| Server | `pre-receive`, `update`, `post-receive` | the remote repository | no |

Server hooks are the enforcement layer: a `pre-receive` hook on the remote can reject a push that violates policy, and no client flag removes it. On hosted platforms this role is usually filled by branch protection and required status checks, covered in [CODEOWNERS](../../github/codeowners.md).

---

## Common Errors

### `hint: The '.git/hooks/pre-commit' hook was ignored because it's not set as executable`

**Cause:** the hook file exists but lacks the execute bit, so Git skips it.

**Fix:** `chmod +x .git/hooks/pre-commit`.

### A hook does not run at all after setting `core.hooksPath`

**Cause:** `core.hooksPath` overrides `.git/hooks/` entirely, so a hook still sitting in the old location is ignored.

**Fix:** move the hook into the directory named by `core.hooksPath`, or unset the config with `git config --unset core.hooksPath`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a Git hook, and where do hooks live?"
    **Say first:** a hook is a script Git runs at a set point in its workflow (before a commit, before a push), stored as an executable in `.git/hooks/` named for the event.

    **Proof:** `ls .git/hooks` shows the `.sample` templates; renaming one to drop `.sample` and making it executable enables it.

    **Follow-up:** Do hooks travel with a clone?

??? question "L1: Are client hooks a security control?"
    **Say first:** no; they are advisory, because they live in local `.git/` and `git commit --no-verify` skips them, so real enforcement belongs on the server or in CI.

    **Proof:** a `pre-commit` that blocks a pattern is bypassed by `--no-verify`, and the commit still lands.

    **Follow-up:** Which hooks cannot be bypassed by the author?
<!-- --8<-- [end:l1] -->

??? question "L2: Write a pre-commit hook that fails the commit, and show it firing."
    **Say first:** put an executable `pre-commit` in `.git/hooks/` that exits non-zero on the condition; a non-zero exit aborts the commit.

    **Proof:**

    ```bash
    printf '#!/bin/sh\ngit diff --cached | grep -q TODO && exit 1\n' > .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    git commit -m "x"   # aborts if a staged line has TODO
    ```

    **Follow-up:** How would you let a teammate get the same hook automatically?

??? question "L2: Share one hook across a whole team's clones."
    **Say first:** commit the hooks into a tracked directory and set `core.hooksPath` to it, or adopt the pre-commit framework.

    **Proof:**

    ```bash
    git config core.hooksPath .githooks
    ```

    **Follow-up:** Why does a plain `.git/hooks/` script not solve this?

??? question "L3: A teammate says a required pre-commit check keeps being skipped in CI-passing PRs. What is going on and how do you fix the enforcement?"
    **Say first:** client hooks are bypassable with `--no-verify` and are not cloned, so relying on `pre-commit` for enforcement is the mistake; move the check to a required CI job or a server-side `pre-receive`.

    **Proof:** the same check as a CI status gate cannot be skipped by a local flag; branch protection then blocks the merge until it passes.

    **Follow-up:** What is the legitimate use of the client hook once CI enforces the rule?

??? question "L2: A hook you created is silently not running. What do you check first?"
    **Say first:** the execute bit and the exact filename, then whether `core.hooksPath` is redirecting Git elsewhere.

    **Proof:** `ls -l .git/hooks/pre-commit` shows the mode; `git config core.hooksPath` shows any override.

    **Follow-up:** What does `core.hooksPath` do to the default `.git/hooks/` directory?

---

## Related

- [Commit Conventions](../04-team-workflows/commit-conventions.md): the message format a `commit-msg` hook enforces
- [Credentials and Signing](credentials-and-signing.md): signing enforced at commit time
- [CODEOWNERS](../../github/codeowners.md): branch protection and required review, the server-side enforcement layer
- [Static Site Deployment](../../github-actions/static-site-deployment.md): CI as the real gate hooks cannot replace

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
