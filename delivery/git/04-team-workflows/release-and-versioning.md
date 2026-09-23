# Release and Versioning

A release turns a commit into a named, tagged version with a changelog, and semantic versioning encodes what changed in the number itself. Interviewers ask about this because the version bump should follow from the commits (a `feat` is a minor, a breaking change a major), which is what makes releases automatable.

**Track:** Workflow · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Semantic version | `MAJOR.MINOR.PATCH`, for example `1.4.2` | the tag |
| MAJOR | Incompatible (breaking) change | `BREAKING CHANGE` commits |
| MINOR | Backward-compatible feature | `feat` commits |
| PATCH | Backward-compatible fix | `fix` commits |
| Pre-release | `1.4.0-rc.1`, sorts before `1.4.0` | the tag |
| Release tag | Annotated (or signed) tag on the release commit | `git show <tag>` |
| Changelog input | `git log <lasttag>..HEAD` | `git log` |
| Current build | `git describe` names it from the last tag | `git describe` |
| Release branch | `release/1.4` to stabilise while `main` moves on | `git branch` |
| Bump source | The commit types since the last release | release tooling |
<!-- --8<-- [end:facts] -->

---

## Semantic Versioning

A semantic version is `MAJOR.MINOR.PATCH`, and each part answers "what will break if I upgrade". Consumers pin to a range based on this promise, so the number is a contract, not a label.

| Part | Increment when | Resets |
|---|---|---|
| MAJOR | An incompatible API change | MINOR and PATCH to 0 |
| MINOR | A backward-compatible feature | PATCH to 0 |
| PATCH | A backward-compatible bug fix | nothing |

A pre-release suffix like `-rc.1` or `-beta.2` marks a version as not yet final; it sorts before the same version without the suffix, so `1.4.0-rc.1` precedes `1.4.0`.

---

## Deciding the Bump from Commits

When commits follow the Conventional Commits format, the next version follows mechanically from the types since the last release: a `BREAKING CHANGE` forces a MAJOR bump, any `feat` a MINOR, and `fix` a PATCH, taking the highest that applies.

This is why the two disciplines pair: [Commit Conventions](commit-conventions.md) make the commit types reliable, and versioning reads them. Tools such as semantic-release automate the whole step, but the logic is simple enough to apply by hand.

!!! info "The highest-severity change wins the bump"
    A release with ten fixes and one feature is a MINOR bump, not a PATCH. One breaking change in a release of features makes it a MAJOR. Scan the range for the most severe change, not the most common one.

---

## Generating a Changelog

The commits between the last release tag and `HEAD` are the changelog. `git log <lasttag>..HEAD` with a format string produces a ready list, and filtering by type keeps it user-facing.

```bash
git log v1.0.0..HEAD --pretty=format:'- %s'
```

Output:

```text
- docs: update readme
- fix(api): correct status code
- feat(auth): add login
```

Filtering to the types users care about drops noise like `docs` and `chore`.

```bash
git log v1.0.0..HEAD --pretty=format:'- %s' | grep -E '^- (feat|fix)'
```

Output:

```text
- fix(api): correct status code
- feat(auth): add login
```

This range (`feat` plus `fix` since `v1.0.0`) also decides the bump: a feature is present, so the next version is `v1.1.0`, a MINOR increment.

---

## Cutting a Release

A release is an annotated (ideally signed) tag on the release commit, pushed explicitly. `git describe` then names any later build relative to it.

```bash
git tag -a v1.1.0 -m "1.1.0"
git describe
```

Output:

```text
v1.1.0
```

On a commit past the tag, `git describe` prints `v1.1.0-<n>-g<sha>`, which is a useful build identifier. The tag mechanics (lightweight versus annotated, pushing, signing) are covered in [Tags and Releases](../03-remotes-and-collaboration/tags-and-releases.md).

For software that supports old versions, a `release/1.x` branch lets a version be patched after `main` has moved on: cut it from the release commit, apply fixes there, tag patch releases from it, and merge the fixes forward into `main`.

!!! warning "Tag the exact commit you release, and never move it"
    A release tag must point at the commit that was built and shipped, so consumers can reproduce it. Moving a published tag makes two clones disagree on what a version is; cut a new patch version instead.

---

## Common Errors

### `fatal: No names found, cannot describe anything`

**Cause:** `git describe` ran in a repository with no annotated tags reachable from `HEAD`.

**Fix:** create a release tag, or use `git describe --tags` to also consider lightweight tags, or `--always` to fall back to a short SHA.

### A version jumps from `1.4.0` straight to `2.0.0` unexpectedly

**Cause:** a commit carried a `BREAKING CHANGE` footer or a `!`, so the tooling forced a MAJOR bump.

**Fix:** confirm the change is genuinely breaking; if it was a mislabel, correct the commit message before releasing.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What do the three numbers in a semantic version mean?"
    **Say first:** `MAJOR.MINOR.PATCH`: MAJOR for an incompatible change, MINOR for a backward-compatible feature, PATCH for a backward-compatible fix.

    **Proof:** a consumer can safely upgrade within the same MAJOR; a MAJOR bump warns of a breaking change.

    **Follow-up:** How do you decide the bump from the commits in a release?

??? question "L1: How do commit types map to a version bump?"
    **Say first:** a `BREAKING CHANGE` forces MAJOR, any `feat` gives MINOR, and `fix` gives PATCH; you take the highest that applies across the range.

    **Proof:** `git log <lasttag>..HEAD` lists the types; one `feat` among fixes makes it a MINOR.

    **Follow-up:** How would you generate the changelog from the same range?
<!-- --8<-- [end:l1] -->

??? question "L2: Produce a changelog of user-facing changes since the last release."
    **Say first:** log the range since the last tag and filter to `feat` and `fix`.

    **Proof:**

    ```bash
    git log v1.0.0..HEAD --pretty=format:'- %s' | grep -E '^- (feat|fix)'
    ```

    **Follow-up:** What determines the next version number from this list?

??? question "L2: Cut and identify a release for the current commit."
    **Say first:** create an annotated tag, then use `git describe` to name later builds relative to it.

    **Proof:** `git tag -a v1.1.0 -m "1.1.0"`; `git describe` prints `v1.1.0` on the tagged commit.

    **Follow-up:** How do you patch `1.1.x` after `main` has already moved to `2.0` work?

??? question "L3: A patch release must go out for version 1.4, but main is already deep into 2.0 features. How do you ship it?"
    **Say first:** cut or reuse a `release/1.4` branch from the `v1.4.0` tag, apply the fix there, tag `v1.4.1` from it, then merge the fix forward into `main`.

    **Proof:** `git switch -c release/1.4 v1.4.0`, fix, `git tag -a v1.4.1`, then merge to `main` so the fix is not lost.

    **Follow-up:** Why merge the fix forward rather than leave it only on the release branch?

??? question "L2: Ship a release candidate before the final version."
    **Say first:** tag it with a pre-release suffix, `v1.5.0-rc.1`; by the semver spec it precedes `v1.5.0`.

    **Proof:**

    ```bash
    git tag -a v1.5.0-rc.1 -m "1.5.0 release candidate 1"
    git config versionsort.suffix -rc   # so version sort places -rc before the final
    git tag --sort=version:refname
    ```

    **Follow-up:** Why does Git need `versionsort.suffix` to sort `-rc.1` before the final release?

---

## Related

- [Commit Conventions](commit-conventions.md): the commit types that drive the version bump
- [Tags and Releases](../03-remotes-and-collaboration/tags-and-releases.md): annotated tags, signing, pushing and `describe`
- [Branching Strategies](branching-strategies.md): where release branches fit in a strategy
- [Inspecting History](../01-core-workflow/inspecting-history.md): the ranges a changelog is built from

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
