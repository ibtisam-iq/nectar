# Commit Conventions

A commit convention makes history machine-readable and human-scannable: a typed subject, an imperative summary, and a body that explains why. Interviewers ask about this because Conventional Commits drive automated changelogs and semantic version bumps, and because "one logical change per commit" is what makes review and `git revert` work.

**Track:** Workflow · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Conventional Commit | `type(scope): subject` | `git log --oneline` |
| Common types | `feat`, `fix`, `docs`, `refactor`, `test`, `chore` | the convention |
| Subject style | Imperative mood, no trailing period, about 50 chars | `git log` |
| Body | Blank line, then why and what, wrapped near 72 chars | `git show` |
| Breaking change | `type!:` and a `BREAKING CHANGE:` footer | `git show` |
| Sign-off | `git commit -s` adds `Signed-off-by:` (DCO) | `git show -s` |
| Trailers | `Key: value` lines at the end (`Co-authored-by`, `Refs`) | `git interpret-trailers` |
| Atomic commit | One logical change, builds and passes on its own | code review |
| Fix a message | `git commit --amend` (last) or interactive rebase | `git log -1` |
| feat vs fix | Drives minor vs patch version bumps | release tooling |
<!-- --8<-- [end:facts] -->

---

## The Conventional Commits Format

A Conventional Commit subject is `type(scope): summary`, where the type classifies the change and the optional scope names the area. This structure is what changelog and versioning tools parse.

```bash
git log --oneline
```

Output:

```text
48b6658 docs: document health endpoint
184b4da fix(api): handle nil request body
61a75b7 feat(api): add health endpoint
```

The log reads like a changelog because each subject states its type and effect. The common types and what they signal are worth memorising.

| Type | Use for | Version effect |
|---|---|---|
| `feat` | A new capability | Minor bump |
| `fix` | A bug fix | Patch bump |
| `docs` | Documentation only | None |
| `refactor` | Behaviour-preserving code change | None |
| `test` | Adding or fixing tests | None |
| `chore` | Build, tooling, dependencies | None |

---

## Subject and Body

The subject is one imperative line ("add", not "added" or "adds"), under about 50 characters, with no trailing period. The body, after a blank line, explains why the change was made and anything non-obvious.

```bash
git show -s --format='%s%n%n%b' HEAD~2
```

Output:

```text
feat(api): add health endpoint

Adds GET /healthz returning 200 for load balancer checks.
```

The blank line between subject and body is required: Git and its tooling treat the first line as the summary and the rest as the body. A subject that needs "and" usually should be two commits.

!!! tip "Write the subject to complete 'this commit will...'"
    "This commit will add health endpoint" reads correctly; "this commit will added" does not. The imperative mood matches Git's own generated messages (`Merge`, `Revert`) and keeps the log consistent.

---

## Sign-Off and Trailers

`git commit -s` appends a `Signed-off-by:` trailer, the Developer Certificate of Origin marker many projects require. Trailers are `Key: value` lines at the end of the message.

```bash
git commit -s -m "feat(api): add readiness probe"
git show -s --format='%s%n%n%b' HEAD
```

Output:

```text
feat(api): add readiness probe

Signed-off-by: Amina Yusuf <amina@example.com>
```

Other common trailers are `Co-authored-by:` for pair work and `Refs:` or `Fixes:` to link an issue. `git interpret-trailers` adds or parses them programmatically, which is how hooks enforce a sign-off.

---

## Linking Issues and Co-Authors

Trailers carry structured metadata: `Refs:` or `Fixes:` to link an issue, `Co-authored-by:` to credit a pair. They must sit in one block at the end of the message, separated from the body by a blank line and with no blank lines between them.

```bash
git show -s --format='%(trailers:only)' HEAD
```

Output:

```text
Refs: #482
Co-authored-by: Bilal Khan <bilal@example.com>
```

`git show` and log formats parse this block with `%(trailers)`, and `git interpret-trailers` adds or reads trailers programmatically, which is how a hook enforces a sign-off or a review tool aggregates co-authors. A trailer placed in its own separate paragraph is not recognised, so keep them together.

!!! note "Trailers must be one unbroken block at the end"
    A blank line between trailers, or a trailer followed by more prose, breaks parsing: `%(trailers)` reads only the final contiguous block. Put every `Key: value` line together as the last thing in the message.

---

## Breaking Changes

A breaking change is marked two ways: a `!` after the type or scope, and a `BREAKING CHANGE:` footer describing the impact. Release tooling reads either to force a major version bump.

```bash
git commit -m "feat(api)!: require auth token on all routes" \
  -m "BREAKING CHANGE: unauthenticated requests now receive 401."
git show -s --format='%s%n%n%b' HEAD
```

Output:

```text
feat(api)!: require auth token on all routes

BREAKING CHANGE: unauthenticated requests now receive 401.
```

The `!` is the scannable signal in the log; the footer is the detail for the changelog. A breaking change can ride on any type, but `feat!` and `fix!` are the usual ones.

---

## Atomic Commits

An atomic commit is one logical change that builds and passes tests on its own. It keeps review focused, makes `git bisect` precise, and lets `git revert` back out exactly one thing.

Mixed changes are split at staging time with `git add -p`, choosing the hunks for each commit. A bad message on the last commit is fixed with `git commit --amend`; older messages are fixed with an interactive rebase (`reword`).

```bash
git commit --amend -m "chore(api): tidy imports"
git log --oneline -1
```

Output:

```text
38446f2 chore(api): tidy imports
```

!!! warning "Amend and rebase rewrite history, so only reword unshared commits"
    Fixing a message with `--amend` or `rebase -i` gives the commit a new SHA. Do it before pushing; once shared, a message fix means a force-push and a rewritten history for everyone, the same golden rule as any rebase.

---

## Common Errors

### `Aborting commit due to empty commit message`

**Cause:** the editor was closed without writing a message, so Git has nothing to record and cancels the commit.

**Fix:** run `git commit` again and write a subject line, or pass `-m "<message>"`.

### `subject may not be empty [subject-empty]` from a commit-msg hook

**Cause:** a linter such as commitlint rejected the message for not matching the Conventional Commits format.

**Fix:** rewrite the message as `type(scope): summary`; the hook output names the rule that failed.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a Conventional Commit, and why use one?"
    **Say first:** it is a commit whose subject is `type(scope): summary` (for example `feat(api): add health endpoint`), which makes history scannable and lets tooling generate changelogs and decide version bumps automatically.

    **Proof:** `git log --oneline` reads like a changelog; `feat` maps to a minor bump and `fix` to a patch.

    **Follow-up:** How is a breaking change signalled in this scheme?

??? question "L1: What makes a commit atomic, and why does it matter?"
    **Say first:** an atomic commit is one logical change that builds and passes on its own, which keeps review focused, makes `git bisect` precise, and lets you revert exactly one thing.

    **Proof:** `git add -p` stages the hunks for one change so unrelated edits go in separate commits.

    **Follow-up:** How do you split a working tree with two unrelated changes into two commits?
<!-- --8<-- [end:l1] -->

??? question "L2: Add a sign-off to a commit for a project that requires the DCO."
    **Say first:** `git commit -s` appends the `Signed-off-by:` trailer from your configured identity.

    **Proof:**

    ```bash
    git commit -s -m "fix(api): handle nil body"
    git show -s --format=%b HEAD
    ```

    **Follow-up:** What is a trailer, and name two others you have used.

??? question "L2: Fix a badly worded message on the commit you most recently made."
    **Say first:** `git commit --amend` to reword the last commit; use an interactive rebase with `reword` for older ones.

    **Proof:** `git log --oneline -1` shows the new subject and a new SHA.

    **Follow-up:** Why is this unsafe once the commit is pushed?

??? question "L2: Credit a pair programmer and link the issue a commit fixes."
    **Say first:** add a trailer block at the end of the message with `Co-authored-by:` and `Refs:` (or `Fixes:`) lines, kept together with no blank lines between them.

    **Proof:**

    ```bash
    git commit -m "fix(api): validate token expiry" \
      -m "Refs: #482
    Co-authored-by: Bilal Khan <bilal@example.com>"
    git show -s --format='%(trailers:only)' HEAD
    ```

    **Follow-up:** Why does a trailer in its own separate paragraph fail to parse?

??? question "L3: A teammate's PR has commits like 'wip', 'fix', 'fix again'. Review is painful and the changelog will be noise. What do you advise?"
    **Say first:** ask them to rewrite the branch into atomic, conventionally-typed commits before merge, using an interactive rebase to squash and reword.

    **Proof:** `git rebase -i main` to `squash`/`fixup` the noise and `reword` the rest; `git log --oneline` then reads cleanly.

    **Follow-up:** How would a squash-merge at the platform hide this without a rebase?

??? question "L4: How does release tooling decide the next version number from commit messages?"
    **Say first:** it parses each commit's type since the last release: a `BREAKING CHANGE` (or `!`) forces a major bump, any `feat` a minor, and `fix` a patch, taking the highest that applies.

    **Proof:** the `type` and `BREAKING CHANGE:` footer are exactly the fields Conventional Commits standardises for this; `git log <lasttag>..HEAD` is the input range.

    **Don't say:** "It reads the diff to guess severity." It reads the structured message, not the code.

---

## Related

- [Staging and Committing](../01-core-workflow/staging-and-committing.md): `add -p` and `--amend` for atomic commits and message fixes
- [Interactive Rebase](../02-branching-and-merging/interactive-rebase.md): squashing and rewording a branch before review
- [Release and Versioning](release-and-versioning.md): how commit types drive semantic version bumps
- [Code Review with Git](code-review-with-git.md): reviewing the commits these conventions produce

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
