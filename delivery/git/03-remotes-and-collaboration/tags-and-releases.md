# Tags and Releases

A tag is a fixed name for one commit, used to mark releases. Interviewers ask about tags to check that a candidate knows an annotated tag is a real object with its own metadata, while a lightweight tag is only a ref, and that tags do not travel with a normal push.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Lightweight tag | A ref pointing at a commit, no metadata | `git cat-file -t <tag>` shows `commit` |
| Annotated tag | Its own object: tagger, date, message | `git cat-file -t <tag>` shows `tag` |
| Create lightweight | `git tag <name> [<commit>]` | `git tag` |
| Create annotated | `git tag -a <name> -m "<msg>"` | `git show <tag>` |
| List | `git tag` (add `-l "<pattern>"` to filter) | `git tag` |
| Describe a build | `git describe` = nearest annotated tag, distance, SHA | `git describe` |
| Push one tag | `git push origin <tag>` | `git ls-remote --tags` |
| Push all tags | `git push --tags` | `git ls-remote --tags` |
| Delete local | `git tag -d <name>` | `git tag` |
| Delete remote | `git push origin --delete <tag>` | `git ls-remote --tags` |
| Signed tag | `git tag -s <name>` (GPG or SSH) | `git tag -v <name>` |
<!-- --8<-- [end:facts] -->

---

## Lightweight Versus Annotated

A lightweight tag is a name that points straight at a commit, like a branch that never moves. An annotated tag is a full object storing who tagged it, when, and a message, which is what a release should use.

```bash
git tag v0.9.0 HEAD~2
git tag -a v1.0.0 -m "Release 1.0.0"
git tag
```

Output:

```text
v0.9.0
v1.0.0
```

Both appear in `git tag`, but they differ underneath. Asking for each one's object type shows the difference.

```bash
git cat-file -t v0.9.0
git cat-file -t v1.0.0
```

Output:

```text
commit
tag
```

`v0.9.0` resolves directly to a `commit`, because a lightweight tag is only a ref. `v1.0.0` is a `tag` object that in turn points at the commit, which is why it can carry a message and a tagger.

---

## The Annotated Tag Object

`git show <tag>` prints an annotated tag's metadata before the commit it marks, which is the record a release needs.

```bash
git show v1.0.0
```

Output:

```text
tag v1.0.0
Tagger: Amina Yusuf <amina@example.com>
Date:   Thu Sep 17 10:15:00 2026 +0500

Release 1.0.0

commit 05626b6a11198eda3564b25bf5c0fe9a60b4934e
Author: Amina Yusuf <amina@example.com>
```

The tag object records the tagger and date independently of the commit's author. Signing a tag with `git tag -s` adds a GPG or SSH signature to this object, verified with `git tag -v`; the signing setup lives in the advanced tooling module.

!!! note "Use annotated tags for anything shared"
    A lightweight tag has no author, date or message, so it cannot be signed and carries no release context. Reserve lightweight tags for private, throwaway markers and use `git tag -a` (or `-s`) for every release.

---

## Describing a Build

`git describe` names the current commit relative to the nearest annotated tag, which turns a commit into a human-readable version string for build metadata.

```bash
git describe
```

Output:

```text
v1.0.0-1-g733e81c
```

The parts are the nearest tag (`v1.0.0`), the number of commits since it (`1`), and `g` plus the short SHA (`g733e81c`). On the tagged commit itself, `git describe` prints only the tag; add `--tags` to also consider lightweight tags.

---

## Pushing Tags

A normal `git push` sends commits, not tags. Tags must be pushed explicitly, which is a frequent surprise when a release tag never appears on the remote.

```bash
git push origin v1.0.0
```

Output:

```text
To git@github.com:acme/shop.git
 * [new tag]         v1.0.0 -> v1.0.0
```

`git push --tags` pushes every local tag at once; `git push origin <tag>` pushes one. Deleting a tag remotely needs its own command, `git push origin --delete <tag>`, because a local `git tag -d` only removes the local copy.

!!! warning "Moving a published tag breaks other clones"
    Re-pointing a tag that others have fetched (`git tag -f` then a force push) means their tag and yours name different commits. Treat a pushed release tag as immutable; cut a new tag instead of moving one.

---

## Common Errors

### `fatal: tag 'v1.0.0' already exists`

**Cause:** the tag name is already in use, and `git tag` refuses to overwrite it by default.

**Fix:** pick a new version, or `git tag -f v1.0.0` to move it (only if it was never pushed); do not move a published tag.

### A release tag is missing on the remote after `git push`

**Cause:** a plain `git push` does not transfer tags; only commits were sent.

**Fix:** push the tag explicitly with `git push origin <tag>`, or `git push --tags` for all of them.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a lightweight and an annotated tag?"
    **Say first:** a lightweight tag is only a ref pointing at a commit; an annotated tag is its own object storing a tagger, date and message, and it can be signed.

    **Proof:** `git cat-file -t` shows `commit` for a lightweight tag and `tag` for an annotated one.

    **Follow-up:** Which should you use for a release, and why?

??? question "L1: You tagged a release and pushed, but the tag is not on the remote. Why?"
    **Say first:** a normal `git push` sends commits, not tags; tags must be pushed explicitly.

    **Proof:** `git push origin <tag>` (or `git push --tags`) transfers it; `git ls-remote --tags` then lists it.

    **Follow-up:** How do you delete a tag that was pushed by mistake?
<!-- --8<-- [end:l1] -->

??? question "L2: Create and publish an annotated release tag for the current commit."
    **Say first:** `git tag -a v1.2.0 -m "Release 1.2.0"` then `git push origin v1.2.0`.

    **Proof:**

    ```bash
    git tag -a v1.2.0 -m "Release 1.2.0"
    git push origin v1.2.0
    ```

    **Follow-up:** How would you sign the tag so its authenticity can be verified?

??? question "L2: Produce a version string that shows how far the current build is past the last release."
    **Say first:** `git describe` prints the nearest annotated tag, the commit count since it, and the short SHA.

    **Proof:** the output looks like `v1.0.0-1-g733e81c`.

    **Follow-up:** What does `--tags` change about which tags `git describe` considers?

??? question "L3: Two clones disagree on which commit v1.0.0 points to. What happened and how do you resolve it?"
    **Say first:** the tag was moved and force-pushed after others had already fetched it, so their tag still names the old commit.

    **Proof:** `git ls-remote --tags origin` versus each clone's `git rev-parse v1.0.0` shows the mismatch; everyone must delete and re-fetch, or a new tag is cut.

    **Follow-up:** Why is cutting a new tag preferable to moving the old one?

??? question "L4: Why can an annotated tag be signed but a lightweight tag cannot?"
    **Say first:** a signature is stored inside the tag object alongside the tagger and message; a lightweight tag has no object, only a ref, so there is nothing to hold a signature.

    **Proof:** `git cat-file -t` shows `tag` (an object) for annotated and `commit` for lightweight; `git tag -v` verifies the signature on the tag object.

    **Don't say:** "You can sign any tag by adding `-s`." `-s` implies an annotated tag object; it cannot make a lightweight one signable.

---

## Related

- [Pushing and Pulling](pushing-and-pulling.md): why tags need an explicit push
- [Remotes](remotes.md): listing remote tags with `git ls-remote --tags`
- [Inspecting History](../01-core-workflow/inspecting-history.md): `git describe` and reading a tagged history
- [Error Messages](../reference/error-messages.md): tag and push errors, with fixes

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
