# The Three Trees

Git manages a change through three trees: the working tree on disk, the index that holds the next commit, and `HEAD` that names the last commit. Almost every command is best understood as moving content between these three, which is why this is the single most useful mental model in an interview.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Working tree | The files on disk you edit | `ls`, `git status` |
| Index (staging area) | The proposed next commit, a full tree of entries | `git ls-files -s` |
| `HEAD` | A pointer to the last commit on the current branch | `git rev-parse HEAD` |
| `git add` | Copies working-tree content into the index | `git diff --cached` |
| `git commit` | Writes the index as a new commit, advances `HEAD` | `git log -1` |
| `git diff` | Working tree vs index (unstaged changes) | `git diff` |
| `git diff --cached` | Index vs `HEAD` (staged changes) | `git diff --cached` |
| `git restore <file>` | Index to working tree (discard unstaged edit) | `git status` |
| `git restore --staged` | `HEAD` to index (unstage) | `git status` |
| `reset --soft` | Moves `HEAD` only | `git status` |
| `reset --mixed` | Moves `HEAD` and index (default) | `git status` |
| `reset --hard` | Moves `HEAD`, index and working tree | `git status` |
<!-- --8<-- [end:facts] -->

---

## The Three Areas

The working tree is the ordinary directory of files. The index is a staging area that holds exactly what the next commit will contain. `HEAD` names the commit the branch currently points at, the baseline the other two are compared against.

A change usually travels working tree, then index, then a commit: edit a file, `git add` it to the index, `git commit` it into history. Each step copies content from one tree to the next, and the compare commands show the gaps between them.

---

## Seeing the Three States

`git status` reports both gaps at once: staged changes (index vs `HEAD`) under "Changes to be committed", and unstaged changes (working tree vs index) under "Changes not staged for commit".

```bash
git status
```

Output:

```text
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   extra.yml

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   service.yml
```

`extra.yml` was added to the index, so it is staged. `service.yml` was edited after it was last staged, so the edit sits only in the working tree. The same file can appear in both lists when part of it is staged and part is not.

---

## Comparing the Areas

Two diff commands read the two gaps. `git diff` compares the working tree against the index, showing what is not yet staged.

```bash
git diff
```

Output:

```text
diff --git a/service.yml b/service.yml
index bcec9e5..f5c9b2c 100644
--- a/service.yml
+++ b/service.yml
@@ -1,2 +1,2 @@
 name: shop
-port: 80
+port: 443
```

`git diff --cached` (also `--staged`) compares the index against `HEAD`, showing what a commit would record right now.

```bash
git diff --cached
```

Output:

```text
diff --git a/extra.yml b/extra.yml
new file mode 100644
index 0000000..98b2266
--- /dev/null
+++ b/extra.yml
@@ -0,0 +1 @@
+debug: true
```

The unstaged edit to `service.yml` does not appear in `--cached`, and the staged `extra.yml` does not appear in the plain diff. This split is the whole point of the index: it lets a commit contain a chosen subset of the working-tree changes.

---

## The Index Is a Real Tree

The index is not a list of filenames; it is a full set of tree entries, each naming a path, a mode and the blob SHA of its staged content. `git ls-files -s` prints it.

```bash
git ls-files -s
```

Output:

```text
100644 98b2266e1b8fad98de353729c3c4e303611d350a 0	extra.yml
100644 bcec9e5a13ee97e536690179263b3aa2610b0c61 0	service.yml
```

The `0` column is the merge stage, which is `0` for a normal entry and `1`, `2`, `3` during a conflict. `service.yml` still shows the old blob (`bcec9e5`), because its new content was never staged. Writing the index out as a tree object confirms it is commit-ready storage.

```bash
git write-tree
```

Output:

```text
36164f0aff1a9b7e22bb33c807abd0a03ec0a936
```

`git commit` does exactly this internally: it calls `write-tree`, wraps the resulting tree in a commit object with the parent and message, and moves `HEAD` to it.

!!! info "HEAD points at a commit, which points at a tree"
    `git cat-file -p HEAD^{tree}` prints the snapshot `HEAD` currently names. Comparing it to `git ls-files -s` is the literal meaning of `git diff --cached`: the index tree against the `HEAD` tree.

---

## How Commands Move Between Trees

Each porcelain command touches a defined set of trees. Reading a command as "which trees does it move" predicts its effect without memorising flags.

| Command | Working tree | Index | HEAD |
|---|---|---|---|
| `git add <file>` | unchanged | updated from working tree | unchanged |
| `git commit` | unchanged | unchanged | advanced to new commit |
| `git restore <file>` | reset from index | unchanged | unchanged |
| `git restore --staged <file>` | unchanged | reset from `HEAD` | unchanged |
| `git reset --soft <c>` | unchanged | unchanged | moved to `<c>` |
| `git reset --mixed <c>` | unchanged | reset from `<c>` | moved to `<c>` |
| `git reset --hard <c>` | reset from `<c>` | reset from `<c>` | moved to `<c>` |

The three `reset` modes differ only in how far the move reaches. `--soft` moves `HEAD` and leaves the change staged.

```bash
git reset --soft HEAD~1
git status -sb
```

Output:

```text
## main
M  f.txt
```

The `M ` in the first column means the change is staged: `HEAD` moved back a commit, but the index and working tree kept the newer content, ready to re-commit. `--mixed` (the default) also resets the index, so the change becomes unstaged.

```bash
git reset --mixed HEAD~1
git status -sb
```

Output:

```text
Unstaged changes after reset:
M	f.txt
## main
 M f.txt
```

Now the `M` sits in the second column: the working tree still has the change, but neither `HEAD` nor the index does. `--hard` would reset all three and discard the change entirely, which is the destructive case covered in [Undoing Changes](../01-core-workflow/undoing-changes.md).

!!! warning "reset --hard writes over the working tree with no undo of the files"
    `--hard` overwrites uncommitted working-tree changes to match the target commit, and those edits are not recoverable from Git because they were never committed. The moved commits themselves survive in the reflog; the unsaved file edits do not.

---

## Common Errors

### `error: Your local changes to the following files would be overwritten by checkout`

**Cause:** switching branches or restoring would overwrite uncommitted working-tree changes that differ between the two trees.

**Fix:** commit or `git stash` the changes first, then switch; or `git restore` them if they are unwanted.

### `fatal: ambiguous argument 'HEAD': unknown revision`

**Cause:** `HEAD` does not resolve because the repository has no commits yet, so there is no last commit for the index to compare against.

**Fix:** make the first commit; until then, everything staged is compared against an empty tree.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are the three trees in Git?"
    **Say first:** the working tree (files on disk), the index or staging area (the proposed next commit), and `HEAD` (a pointer to the last commit on the current branch).

    **Proof:** `git status` reports the gap between working tree and index, and between index and `HEAD`.

    **Follow-up:** Which two trees does `git diff` compare, and which does `git diff --cached` compare?

??? question "L1: What is the difference between git diff and git diff --cached?"
    **Say first:** `git diff` shows working tree against the index (unstaged changes); `git diff --cached` shows the index against `HEAD` (what a commit would record).

    **Proof:** an edit you have not `git add`ed appears in `git diff` but not in `git diff --cached`.

    **Follow-up:** Where does `git add` move content, and where does `git commit` move it?
<!-- --8<-- [end:l1] -->

??? question "L2: You staged a file, then edited it again. How do you commit only the staged version, and how do you check what that is?"
    **Say first:** `git commit` records the index, so the earlier staged version is committed; check it with `git diff --cached` before committing.

    **Proof:**

    ```bash
    git diff --cached
    git commit -m "..."
    ```

    **Follow-up:** How would you also include the newer edit in the same commit?

??? question "L2: Unstage a file without losing your changes."
    **Say first:** `git restore --staged <file>` copies the `HEAD` version back into the index, leaving the working tree edit intact.

    **Proof:** `git status` moves the file from "Changes to be committed" to "Changes not staged for commit".

    **Follow-up:** Which reset mode does the same thing to every staged file at once?

??? question "L3: git status shows a file as both staged and not staged. What happened, and what will a commit capture?"
    **Say first:** the file was staged, then edited again, so the index holds one version and the working tree holds a newer one; a commit records the index version.

    **Proof:** `git diff --cached` shows the staged part, `git diff` shows the still-unstaged part; only the first is committed.

    **Follow-up:** How do you fold the unstaged edit into the same commit before committing?

??? question "L4: What does git commit do to the three trees internally?"
    **Say first:** it writes the index out as a tree object (`write-tree`), creates a commit object pointing at that tree with the current `HEAD` as parent, and moves the branch ref to the new commit.

    **Proof:** `git write-tree` prints the same tree SHA a commit would embed; `git cat-file -p HEAD` then shows that tree and the parent.

    **Don't say:** "Commit copies the working tree directly into history." It commits the index, not the working tree.

---

## Related

- [What Is Git](what-is-git.md): snapshots, objects and content addressing
- [Staging and Committing](../01-core-workflow/staging-and-committing.md): using the index day to day, including `add -p`
- [Undoing Changes](../01-core-workflow/undoing-changes.md): `restore`, `reset` modes and `revert` in full
- [Inspecting History](../01-core-workflow/inspecting-history.md): `git diff` and `git diff --cached` as views of the trees

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
