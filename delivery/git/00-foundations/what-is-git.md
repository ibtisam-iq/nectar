# What Is Git

Git is a distributed version control system that records the history of a project as a series of full snapshots addressed by content hash. Interviewers open here to check that a candidate knows why Git is distributed and why it stores snapshots rather than file diffs, because those two facts explain most of its behaviour.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Type | Distributed VCS: every clone is a full repository with complete history | `git log` works offline |
| Storage model | Snapshots of the whole tree per commit, not per-file diffs | `git cat-file -p HEAD` |
| Object id | Content hash (SHA-1, SHA-256 for new repos); identical content, identical id | `git hash-object` |
| A commit | A tree plus parent(s), author, committer and message | `git cat-file -p HEAD` |
| The three areas | Working tree, index (staging area), repository | `git status` |
| Integrity | Every object is checksummed; corruption is detectable | `git fsck` |
| Local first | Commit, branch, diff and log need no network | any command offline |
| Created | Linus Torvalds, 2005, to host Linux kernel development | history |
<!-- --8<-- [end:facts] -->

---

## Distributed, Not Centralized

A centralized system (CVS, Subversion) keeps the history on one server, and a working copy holds only the current files. Git clones the entire repository, so every developer has the full history and can commit, branch, diff and inspect log without contacting a server.

```bash
git log --oneline
```

Output:

```text
059ac4e Set service port
e434b53 Add service manifest
```

That log came from local object storage, with no network call. The remote matters only when changes are shared, which is why fetch, push and pull are the small set of commands that need connectivity.

!!! info "Distributed means every clone is a backup"
    A full clone contains every commit, tree and blob the project has ever had. Losing the central server loses the shared meeting point, not the history, because any complete clone can become the new origin.

---

## Snapshots, Not Diffs

Older systems store a file as a base version plus a chain of diffs. Git instead records a snapshot: each commit points to a tree that names the complete set of files at that moment.

```bash
git cat-file -p HEAD
```

Output:

```text
tree 2eac7e130d7f3f88d2ed8e23ecad5af9b57a8d7d
parent e434b53b3adf64b9fa3608e456cfda6b8cacd7c3
author Amina Yusuf <amina@example.com> 1789621500 +0500
committer Amina Yusuf <amina@example.com> 1789621500 +0500

Set service port
```

The commit holds a `tree` (the snapshot), a `parent` (the previous commit) and metadata. The tree lists each path and the blob that holds its content.

```bash
git ls-tree HEAD
```

Output:

```text
100644 blob 864621d21b878f3cbf4ef7655c97755fdd0c0115	service.yml
```

A file that does not change between commits is not re-stored: both trees point at the same blob SHA. Git computes diffs on demand for display (`git diff`, `git log -p`), but they are a view, not the storage format.

---

## Content Addressing and Integrity

Every object's name is the hash of its content, so the same bytes always produce the same object id, and any change to the content changes the id. This is how Git detects corruption and how it avoids storing duplicate content.

```bash
printf 'port: 8080\n' | git hash-object --stdin
printf 'port: 8080\n' | git hash-object --stdin
```

Output:

```text
29b7b59d29212e634fccaa0a87e44845adb351a4
29b7b59d29212e634fccaa0a87e44845adb351a4
```

The identical hash from two runs shows the id depends only on content. A commit's id covers its tree, parents and message, so rewriting any earlier commit changes every id after it, which is the mechanism behind the rebase golden rule.

!!! note "SHA-1 is being replaced by SHA-256"
    Git's object ids were SHA-1; new repositories can be created with `--object-format=sha256`. The hashing is for addressing and integrity, not security, and the transition is why current output shows 40-character ids on most repositories and 64-character ids on SHA-256 ones.

---

## The Three Areas

Git tracks a change through three areas: the working tree (the files on disk), the index or staging area (what the next commit will contain), and the repository (the committed history). Most day-to-day commands move a change from one area to the next.

```bash
git status -sb
```

Output:

```text
## main
```

The clean status means the working tree and index match `HEAD`. The mechanics of moving between the three areas are the subject of [The Three Trees](the-three-trees.md).

---

## Common Errors

### `fatal: not a git repository (or any of the parent directories): .git`

**Cause:** the command was run outside any Git repository, and no `.git` directory exists in the current or parent folders.

**Fix:** `cd` into the project, or run `git init` to create a repository here.

### `fatal: your current branch 'main' does not have any commits yet`

**Cause:** the repository was initialised but nothing has been committed, so there is no history for `git log` to show.

**Fix:** stage and commit at least once (`git add` then `git commit`), then re-run the command.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does it mean that Git is a distributed version control system?"
    **Say first:** every clone is a full repository with the complete history, so committing, branching, diffing and viewing log all work locally without a server.

    **Proof:** `git log` and `git commit` run offline; only fetch, push and pull touch the network.

    **Follow-up:** How is that different from Subversion or CVS?

??? question "L1: Does Git store diffs or snapshots?"
    **Say first:** snapshots; each commit points to a tree that names the complete set of files, and unchanged files reuse the same blob rather than being re-stored.

    **Proof:** `git cat-file -p HEAD` shows the commit's `tree`; `git ls-tree HEAD` lists the blobs the snapshot references.

    **Follow-up:** If it stores snapshots, why does `git log -p` show diffs?
<!-- --8<-- [end:l1] -->

??? question "L2: Show that a commit references a complete snapshot rather than a diff."
    **Say first:** print the commit object and its tree with `git cat-file` and `git ls-tree`.

    **Proof:**

    ```bash
    git cat-file -p HEAD
    git ls-tree HEAD
    ```

    **Follow-up:** How does Git avoid re-storing a file that did not change between two commits?

??? question "L2: Start a repository and prove that its history is available without any server."
    **Say first:** `git init`, make a commit, then run `git log` with no remote configured.

    **Proof:**

    ```bash
    git init
    git commit -m "First" --allow-empty
    git log --oneline
    ```

    **Follow-up:** What is the only category of commands that needs a network connection?

??? question "L3: A new teammate says the shared Git server is down, so nobody can commit or see history. What do you tell them?"
    **Say first:** commits and history are local, so work continues; only sharing is blocked until the server returns.

    **Proof:** `git commit`, `git log` and `git branch` succeed offline; `git push` is what fails with a connection error.

    **Follow-up:** What is the minimum needed to make another clone the new shared origin?

??? question "L4: Why does changing one old commit change the id of every commit after it?"
    **Say first:** a commit id is the hash of its content, which includes its tree, its parent ids and its message, so a new parent id forces a new id, and that cascades forward.

    **Proof:** `git cat-file -p HEAD` shows the `parent` line inside the hashed content; editing an ancestor changes each descendant's parent and therefore its hash.

    **Don't say:** "Git stores a version number that it bumps."

---

## Related

- [Install and Config](install-and-config.md): setting identity and defaults before the first commit
- [The Three Trees](the-three-trees.md): the working tree, index and HEAD in detail
- [Staging and Committing](../01-core-workflow/staging-and-committing.md): moving a change into history
- [Inspecting History](../01-core-workflow/inspecting-history.md): reading the commits and trees you create

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
