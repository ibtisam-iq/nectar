# Refs and HEAD

A ref is a name that points at a commit, stored as a small file holding a SHA, and `HEAD` is the special ref that names where you are. Interviewers ask about this because branches, tags and `HEAD` are all refs into the object graph, which demystifies switching, detaching and how a commit advances a branch.

**Track:** Advanced · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Ref | A name pointing at an object, usually a commit | `git for-each-ref` |
| Branch ref | `refs/heads/<name>`, a file with one SHA | `cat .git/refs/heads/main` |
| Tag ref | `refs/tags/<name>` | `git rev-parse <tag>` |
| Remote ref | `refs/remotes/origin/<name>` | `git branch -r` |
| `HEAD` | A symbolic ref to the current branch | `cat .git/HEAD` |
| Detached `HEAD` | `HEAD` holds a raw SHA, not a `ref:` | `cat .git/HEAD` |
| Symbolic ref | A ref pointing at another ref | `git symbolic-ref HEAD` |
| Loose ref | A file under `.git/refs/` | `ls .git/refs/heads` |
| Packed ref | Collected into `.git/packed-refs` | `cat .git/packed-refs` |
| Peeled tag | An annotated tag ref dereferenced to its commit | `git rev-parse <tag>^{commit}` |
<!-- --8<-- [end:facts] -->

---

## A Ref Is a File with a SHA

A branch is not a container of commits; it is a 41-byte file under `refs/heads/` holding one commit SHA. Committing rewrites that file to the new commit's SHA.

```bash
cat .git/refs/heads/main
```

Output:

```text
b8f0e9b1b6ce72368df3b2463f835e84faf51e7e
```

That single SHA is the whole branch. Creating a branch writes a new such file, and deleting one removes the file, which is why both are constant-time regardless of history size.

---

## HEAD as a Symbolic Ref

`HEAD` tells Git which branch a new commit extends. On a branch it is a symbolic ref: a file containing `ref: refs/heads/<name>` rather than a SHA.

```bash
cat .git/HEAD
git symbolic-ref HEAD
```

Output:

```text
ref: refs/heads/main
refs/heads/main
```

Resolving `HEAD` takes two hops: `HEAD` names the branch, and the branch names the commit. `git rev-parse HEAD` follows both to the commit SHA. When you check out a commit directly, `HEAD` instead holds a raw SHA, which is the detached state covered in [Branches](../02-branching-and-merging/branches.md).

---

## Listing Refs

`git for-each-ref` prints every ref with its type and target, the reliable way to see branches, tags and remote-tracking refs together.

```bash
git for-each-ref --format='%(refname) %(objecttype) %(objectname:short)'
```

Output:

```text
refs/heads/feature/x commit 554736e
refs/heads/main commit b8f0e9b
refs/tags/v1.0.0 tag 8c30e31
```

Branches point at `commit` objects; the annotated tag points at a `tag` object, not directly at a commit. That extra hop is what lets an annotated tag carry its own message and signature.

---

## Loose Versus Packed Refs

New refs are stored loose, one file each. `git gc` (or `git pack-refs`) collects them into a single `.git/packed-refs` file for efficiency on repositories with many refs.

```bash
git pack-refs --all
cat .git/packed-refs
```

Output:

```text
# pack-refs with: peeled fully-peeled sorted
554736e3c60024023c89a27546284dbd7d4ca42d refs/heads/feature/x
b8f0e9b1b6ce72368df3b2463f835e84faf51e7e refs/heads/main
8c30e31480b4e1e88f27f436682548ae6784f77b refs/tags/v1.0.0
^b8f0e9b1b6ce72368df3b2463f835e84faf51e7e
```

After packing, the loose files under `.git/refs/heads/` are gone and Git reads `packed-refs` instead. The `^` line under the tag is the peeled value: the commit the annotated tag points to, cached so Git need not re-dereference it.

```bash
git rev-parse v1.0.0
git rev-parse v1.0.0^{commit}
```

Output:

```text
8c30e31480b4e1e88f27f436682548ae6784f77b
b8f0e9b1b6ce72368df3b2463f835e84faf51e7e
```

`v1.0.0` resolves to the tag object; `v1.0.0^{commit}` peels it to the commit. Lightweight tags skip this indirection and point straight at the commit.

!!! info "Loose and packed refs are read the same way"
    Git checks `.git/refs/` first, then falls back to `packed-refs`, so a ref works identically whether loose or packed. You never choose; `gc` packs them, and creating a ref writes a loose file that a later `gc` folds in.

---

## How Commands Use Refs

Refs are the entry points into the commit DAG. `git log main` starts walking from whatever `refs/heads/main` points at; `git commit` updates the current branch's ref to the new commit; `git update-ref` sets a ref directly for scripting.

Because a ref is only a pointer, high-level operations reduce to moving refs: a branch switch rewrites `HEAD`, a fast-forward merge moves the branch ref forward, and a reset moves it anywhere. Understanding refs turns those commands from magic into pointer edits.

!!! warning "Move refs with git update-ref, not by editing files"
    Hand-editing `.git/refs/*` or `packed-refs` skips the reflog and can corrupt state, and it silently fails when the ref is packed rather than loose. Use `git update-ref` (or the porcelain that wraps it), which writes atomically and records a reflog entry.

---

## Common Errors

### `fatal: ref HEAD is not a symbolic ref`

**Cause:** `git symbolic-ref HEAD` was run while `HEAD` is detached, so it holds a SHA, not a `ref:`.

**Fix:** switch to a branch (`git switch <name>`); a detached `HEAD` has no symbolic target to print.

### `error: cannot lock ref 'refs/heads/main': is at <sha> but expected <sha>`

**Cause:** a ref update (often a push or a concurrent operation) found the ref had moved since it was read.

**Fix:** fetch or re-read the current value and retry; this is the low-level form of a non-fast-forward rejection.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a branch, really, at the storage level?"
    **Say first:** a branch is a ref: a small file under `refs/heads/` containing one commit SHA, which `git commit` advances to the new commit.

    **Proof:** `cat .git/refs/heads/main` prints a single 40-character SHA.

    **Follow-up:** What does `HEAD` contain when you are on a branch?

??? question "L1: What is HEAD, and how does it differ when detached?"
    **Say first:** `HEAD` is a symbolic ref pointing at the current branch (`ref: refs/heads/<name>`); when detached it holds a raw commit SHA instead, so new commits belong to no branch.

    **Proof:** `cat .git/HEAD` shows `ref: refs/heads/main` normally, or a bare SHA when detached.

    **Follow-up:** How many hops does resolving `HEAD` to a commit take?
<!-- --8<-- [end:l1] -->

??? question "L2: List every ref in the repository with what it points to."
    **Say first:** `git for-each-ref` prints branches, tags and remote refs with their types and targets.

    **Proof:**

    ```bash
    git for-each-ref --format='%(refname) %(objecttype) %(objectname:short)'
    ```

    **Follow-up:** Why does an annotated tag show `tag` rather than `commit`?

??? question "L2: Your repo has thousands of refs and operations feel slow to enumerate. What can help?"
    **Say first:** pack the refs with `git pack-refs --all` (or let `git gc` do it), collecting loose ref files into one `packed-refs` file.

    **Proof:** after packing, `.git/refs/heads/` is empty and `cat .git/packed-refs` lists them; Git reads them identically.

    **Follow-up:** What is the `^` line under a tag in `packed-refs`?

??? question "L3: A push failed with 'cannot lock ref ... is at X but expected Y'. What does that mean?"
    **Say first:** the ref moved between when Git read it and when it tried to update it, so the compare-and-swap failed; it is the low-level non-fast-forward case.

    **Proof:** the remote's `refs/heads/<branch>` no longer holds the value the push expected; fetching and retrying resolves it.

    **Follow-up:** How does this relate to `--force-with-lease`?

??? question "L4: How does an annotated tag reach a commit, and how does git rev-parse peel it?"
    **Say first:** `refs/tags/<name>` points at a tag object, which stores the target object's SHA plus tagger and message; `<tag>^{commit}` dereferences (peels) the tag object to the commit it finally names.

    **Proof:** `git rev-parse v1.0.0` returns the tag object SHA; `git rev-parse v1.0.0^{commit}` returns the commit; `packed-refs` caches the peeled value on a `^` line.

    **Don't say:** "A tag ref points directly at the commit." That is only true for a lightweight tag; an annotated tag adds an object in between.

---

## Related

- [Object Model](object-model.md): the objects that refs point into
- [Branches](../02-branching-and-merging/branches.md): branches and `HEAD` from the user's side
- [How Merge and Rebase Work](how-merge-and-rebase-work.md): operations that move refs around the DAG
- [Packfiles and GC](packfiles-and-gc.md): what `git gc` does to refs and objects

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
