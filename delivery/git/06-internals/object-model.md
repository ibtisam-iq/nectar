# Object Model

Git stores everything as four kinds of object addressed by the hash of their content: blobs, trees, commits and tags. Interviewers ask about this because it explains snapshots, deduplication, integrity and why history is immutable, and because `cat-file` lets you prove it in three commands.

**Track:** Advanced · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Blob | File content, no name or metadata | `git cat-file -p <blob>` |
| Tree | A directory: names, modes, and blob/tree SHAs | `git cat-file -p <tree>` |
| Commit | A tree plus parent(s), author, committer, message | `git cat-file -p HEAD` |
| Tag object | An annotated tag: target, tagger, message | `git cat-file -t <tag>` |
| Object id | Hash of `type + size + content` | `git hash-object` |
| Content addressed | Identical content, identical SHA (dedup) | `git ls-tree HEAD` |
| Type of an object | `git cat-file -t <sha>` | `git cat-file -t HEAD` |
| Size of an object | `git cat-file -s <sha>` | `git cat-file -s HEAD` |
| Snapshot | Each commit points at a full tree, not a diff | `git cat-file -p HEAD` |
| Immutability | Changing content changes the SHA, so a commit is fixed | `git hash-object` |
<!-- --8<-- [end:facts] -->

---

## Four Object Types

Every piece of a repository is one of four object types, each stored once and named by its hash.

| Object | Holds | Points to |
|---|---|---|
| Blob | Raw file content | nothing |
| Tree | A directory listing | blobs and subtrees |
| Commit | A snapshot and metadata | one tree, and parent commit(s) |
| Tag | Annotated-tag metadata | one object (usually a commit) |

A blob is content with no filename; the name lives in the tree that references it. A commit ties a tree (the snapshot) to its parents (the history).

---

## The Commit Object

`git cat-file -p HEAD` prints a commit's stored form: a `tree` line, zero or more `parent` lines, author and committer with timestamps, and the message.

```bash
git cat-file -p HEAD
```

Output:

```text
tree a4c85bd8861b37fa8e61fea725010f6ef70a0249
author Amina Yusuf <amina@example.com> 1789876800 +0500
committer Amina Yusuf <amina@example.com> 1789876800 +0500

Initial commit
```

The commit itself holds no files; it references a `tree` that is the complete snapshot. `git cat-file -t HEAD` confirms the type is `commit`, and a first commit has no `parent` line.

---

## Trees and Blobs

A tree is a directory: each entry is a mode, a type, a SHA and a name. Entries are either blobs (files) or subtrees (subdirectories).

```bash
git cat-file -p HEAD^{tree}
```

Output:

```text
100644 blob a00621bb3a9b990ee018f8d04c2d3140800d6ca6	README.md
040000 tree 212c4fdae26c1d9b9ecee80ce328176151064663	src
```

`README.md` is a blob; `src` is a subtree, which is another tree object listing its own entries. Following a subtree reaches its files, and a blob is only the bytes.

```bash
git cat-file -p HEAD^{tree}:src
```

Output:

```text
100644 blob b80e3222ab264bd7cafb376749bd18814fd66776	app.py
```

The mode `100644` is a normal file, `100755` an executable, and `040000` a directory. This tree-of-trees is the snapshot: reproducing it reproduces the working directory exactly.

---

## Content Addressing

An object's id is the SHA of its type, size and content, so identical content always yields the same id. `git hash-object` computes it, and it matches the blob already in the tree.

```bash
printf '# Shop\n' | git hash-object --stdin
```

Output:

```text
a00621bb3a9b990ee018f8d04c2d3140800d6ca6
```

That is the same SHA as `README.md` in the tree above. Because the id is the content, two identical files store one blob, referenced twice.

```bash
git ls-tree HEAD | grep -E 'README|COPY'
```

Output:

```text
100644 blob a00621bb3a9b990ee018f8d04c2d3140800d6ca6	COPY.md
100644 blob a00621bb3a9b990ee018f8d04c2d3140800d6ca6	README.md
```

Both files point at one blob. This is why Git does not bloat when a file is copied or unchanged across commits: the blob is stored once.

!!! info "Content addressing gives dedup, integrity and immutability at once"
    Because the id is the hash of the content, unchanged files are shared (dedup), any corruption changes the hash and is detectable (integrity), and editing a commit produces a different id rather than mutating it (immutability). All three properties fall out of the same design.

---

## Writing an Object by Hand

Plumbing commands read and write objects directly, which shows the store has no magic. `git hash-object -w` writes a blob and returns its SHA; `git cat-file -p` reads any object back by SHA.

```bash
echo 'hello internals' | git hash-object -w --stdin
git cat-file -p 7fb30904241a9ffd036dc6695c5de5b1d977c7fc
```

Output:

```text
7fb30904241a9ffd036dc6695c5de5b1d977c7fc
hello internals
```

The blob now exists in `.git/objects` with no commit or tree referencing it, a dangling object until something points at it. This is the layer `git add` builds on internally.

!!! note "The empty tree has a constant, universal SHA"
    `git hash-object -t tree /dev/null` always yields `4b825dc642cb6eb9a060e54bf8d69288fbee4904` in every SHA-1 repository, because the empty tree's content is fixed. Tools use it as a stable base, for example diffing a first commit against the empty tree.

---

## How It Fits Together

The objects form a directed acyclic graph. A branch ref points at a commit; the commit points at a tree and its parent commits; the tree points at blobs and subtrees.

Walking `commit -> tree -> blobs` reconstructs a snapshot, and walking `commit -> parent -> parent` walks history. Nothing points forward, and every edge is a content hash, which is why the whole graph is verifiable and why a commit's id fixes everything reachable from it.

---

## Common Errors

### `fatal: Not a valid object name HEAD^{tree}` in a new repository

**Cause:** the repository has no commits, so `HEAD` does not resolve to a commit or tree.

**Fix:** make the first commit; the object graph exists only once something is committed.

### `error: object file .git/objects/... is empty` or a corrupt-object message

**Cause:** an object in the store is damaged, which content addressing detects because the hash no longer matches.

**Fix:** `git fsck` reports the bad object; recover it from another clone (its SHA is identical everywhere) or a backup.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are Git's object types, and what does each hold?"
    **Say first:** blob (file content), tree (a directory of names pointing at blobs and subtrees), commit (a tree plus parents and metadata), and tag (annotated-tag metadata pointing at an object).

    **Proof:** `git cat-file -t <sha>` names the type; `git cat-file -p HEAD` shows a commit referencing a tree.

    **Follow-up:** Where is a file's name stored, given that a blob has none?

??? question "L1: What does it mean that Git is content-addressed?"
    **Say first:** an object's id is the hash of its content, so identical content always has the same id; this gives deduplication, integrity checking and immutability.

    **Proof:** `git hash-object` of a file matches its blob SHA in the tree; two identical files share one blob.

    **Follow-up:** Why does this mean a commit cannot be edited in place?
<!-- --8<-- [end:l1] -->

??? question "L2: Show that a commit references a snapshot, then walk from the commit to a file's content."
    **Say first:** print the commit, follow its tree, then a subtree, then the blob.

    **Proof:**

    ```bash
    git cat-file -p HEAD
    git cat-file -p HEAD^{tree}
    git cat-file -p HEAD^{tree}:src
    ```

    **Follow-up:** How does Git avoid re-storing an unchanged file in the next commit?

??? question "L2: Write a blob into the object store by hand and read it back."
    **Say first:** `git hash-object -w` writes it and returns the SHA; `git cat-file -p <sha>` reads it back.

    **Proof:**

    ```bash
    echo 'x' | git hash-object -w --stdin
    git cat-file -p <sha>
    ```

    **Follow-up:** What is that object called until a tree or commit references it?

??? question "L3: git fsck reports a corrupt object. How is that even detectable, and how do you recover?"
    **Say first:** the object's stored hash no longer matches its content, which content addressing makes detectable; recover the object from another clone, where its SHA is identical.

    **Proof:** `git fsck` names the bad SHA; `git cat-file -t` on it fails; copying the object from a good clone restores it.

    **Follow-up:** Why is the same object guaranteed to have the same SHA in every clone?

??? question "L4: Exactly what bytes does Git hash to produce a blob's SHA?"
    **Say first:** it hashes a header of the object type and content length, a NUL byte, then the raw content: `blob <size>\0<content>`, and the SHA of that is the object id.

    **Proof:** `printf '# Shop\n' | git hash-object --stdin` reproduces the blob SHA exactly, matching the tree entry.

    **Don't say:** "It hashes only the file content." The type-and-size header is part of the hashed bytes, which is why a blob and a tag of the same bytes differ.

---

## Related

- [Refs and HEAD](refs-and-head.md): the refs that point into this object graph
- [How Merge and Rebase Work](how-merge-and-rebase-work.md): operations over the commit DAG
- [Packfiles and GC](packfiles-and-gc.md): how these objects are compressed and stored on disk
- [What Is Git](../00-foundations/what-is-git.md): the snapshot model these objects implement

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
