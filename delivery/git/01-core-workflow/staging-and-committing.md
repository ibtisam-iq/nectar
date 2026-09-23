# Staging and Committing

Staging selects which changes go into the next commit, and committing writes that selection into history as a new snapshot. Interviewers test this because the staging area is what lets a commit be a single logical change rather than a dump of everything edited since the last one.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Stage a file | `git add <path>` copies it into the index | `git status` |
| Stage everything tracked | `git add -u` (updates and deletions, no new files) | `git status` |
| Stage all changes | `git add -A` (or `git add .` for the current dir) | `git status` |
| Stage part of a file | `git add -p` chooses hunks interactively | `git diff --cached` |
| Commit | `git commit -m "<msg>"` records the index | `git log -1` |
| Commit tracked changes | `git commit -am "<msg>"` (adds tracked, not new files) | `git log -1` |
| Amend last commit | `git commit --amend` (edit message or add files) | `git log -1` |
| Short status codes | Column 1 = index, column 2 = working tree | `git status -s` |
| `??` | Untracked; `A` added; `M` modified; `D` deleted | `git status -s` |
| Empty commit | `git commit --allow-empty` records no change | `git log -1` |
<!-- --8<-- [end:facts] -->

---

## The Staging Area

A commit records the index, not the working tree, so `git add` is how a change becomes part of the next commit. Staging a subset lets one edit session become several focused commits.

```bash
git status -s
git add service.yml
git status -s
```

Output:

```text
?? service.yml
A  service.yml
```

The short status has two columns: the first is the index (staged) state, the second the working-tree (unstaged) state. `??` is untracked, and after `git add` the file shows `A ` (added in the index, clean in the working tree).

---

## Committing

`git commit` turns the current index into a new commit and advances the branch. `-m` supplies the message inline; without it, Git opens `core.editor`.

```bash
git commit -m "Add service manifest"
```

Output:

```text
[main (root-commit) e434b53] Add service manifest
 1 file changed, 1 insertion(+)
 create mode 100644 service.yml
```

`(root-commit)` marks the first commit, which has no parent. The summary line names the branch, the new short SHA and the message, and the following lines report the file changes the commit recorded.

!!! note "commit -am stages tracked files but never new ones"
    `git commit -am "..."` runs `git add -u` then commits, so it captures edits and deletions to already-tracked files. A brand-new file stays untracked and is silently left out, which is a frequent cause of a missing file in a commit.

---

## Staging Part of a File

`git add -p` walks the diff hunk by hunk, so unrelated changes in one file can go into separate commits. Each prompt offers `y` to stage the hunk, `n` to skip it, and `s` to split a large hunk further.

```bash
git add -p
```

Output:

```text
diff --git a/big.txt b/big.txt
index 4083766..610b193 100644
--- a/big.txt
+++ b/big.txt
@@ -1,4 +1,4 @@
-line1
+line1 CHANGED
 line2
 line3
 line4
(1/2) Stage this hunk [y,n,q,a,d,j,J,g,/,e,p,?]?
```

Answering `y` to the first hunk and `n` to the second stages one change and leaves the other. The file then shows `MM` in short status: modified in the index and modified again in the working tree.

```bash
git status -s
```

Output:

```text
MM big.txt
```

`git diff --cached` now shows only the staged hunk, and `git diff` shows only the skipped one. This is the mechanism behind clean, reviewable commits from a messy working session.

---

## Staging Everything: -u, -A and .

Three bulk-staging flags differ in what they include. `git add -u` stages modifications and deletions to already-tracked files, and never adds a new file.

```bash
git add -u
git status -s
```

Output:

```text
M  tracked.txt
?? untracked.txt
```

The edit is staged (`M `), but `untracked.txt` stays untracked. `git add -A` stages everything: modifications, deletions and new files, across the whole tree.

```bash
git add -A
git status -s
```

Output:

```text
M  tracked.txt
A  untracked.txt
```

`git add .` is like `-A` but limited to the current directory and below, which matters in a subdirectory. Prefer `-A` when the intent is "stage every change in the repository", and `-u` when new files should be left out on purpose.

Renames and deletions are staged too: `git mv` and `git rm` update the index directly, and a plain filesystem delete is staged by any of `git add -u`, `-A` or `git commit -a`. To review the staged diff inside the commit editor before saving, add `-v` to `git commit`.

---

## Amending the Last Commit

`git commit --amend` replaces the most recent commit with a new one built from the current index, which fixes a forgotten file or a bad message. Because the commit id covers its content, the amended commit gets a new SHA.

```bash
git add README.md
git commit --amend --no-edit
```

Output:

```text
[main 532a1c6] Add app
 Date: Thu Sep 17 10:00:00 2026 +0500
 2 files changed, 2 insertions(+)
 create mode 100644 README.md
 create mode 100644 app.py
```

`--no-edit` keeps the existing message; omit it to open the editor and reword. The commit now contains both files under the original message, but its SHA changed from the pre-amend commit.

!!! danger "Amending a pushed commit rewrites shared history"
    `--amend` creates a new commit and abandons the old one, so amending a commit others have already pulled forces a divergent history and a rejected push. Amend only commits that are still local, the same rule as rebase.

---

## Common Errors

### `nothing to commit, working tree clean`

**Cause:** there are no staged changes; either nothing was edited, or edits were made but never `git add`ed.

**Fix:** stage the changes with `git add` (or use `git commit -a` for tracked files), then commit.

### `On branch main / Untracked files` with a file missing from the commit

**Cause:** `git commit -am` was used, which stages tracked files only, so a new untracked file was left out.

**Fix:** `git add <newfile>` explicitly, then commit; `-a` never stages new files.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does the staging area (index) do, and why does Git have one?"
    **Say first:** it holds exactly what the next commit will contain, so you can build a focused commit from a subset of your working-tree changes rather than committing everything at once.

    **Proof:** `git add` copies content into the index; `git commit` records the index, not the working tree.

    **Follow-up:** How do you stage only part of a single file's changes?

??? question "L1: What is the difference between git commit -m and git commit -am?"
    **Say first:** `-m` commits whatever is already staged; `-am` first stages modifications and deletions to tracked files, but neither form stages new untracked files.

    **Proof:** a new file stays `??` in `git status -s` after `git commit -am`, and is left out of the commit.

    **Follow-up:** How do you include a brand-new file in that commit?
<!-- --8<-- [end:l1] -->

??? question "L2: You edited two unrelated things in one file. Commit them separately."
    **Say first:** use `git add -p` to stage one hunk, commit it, then stage and commit the other.

    **Proof:**

    ```bash
    git add -p        # y on the first hunk, n on the second
    git commit -m "First change"
    git commit -am "Second change"
    ```

    **Follow-up:** What does `s` do at the `add -p` prompt?

??? question "L2: You committed but forgot to include a file. Fix the last commit without a new one."
    **Say first:** stage the file and `git commit --amend --no-edit` to fold it into the previous commit.

    **Proof:** `git show --stat HEAD` then lists both files under the original message.

    **Follow-up:** When is amending the last commit unsafe?

??? question "L3: git status shows a file as MM. What does that mean and what will a commit capture?"
    **Say first:** the file was staged, then edited again; the index holds one version and the working tree a newer one, and a commit records the index version.

    **Proof:** `git diff --cached` shows the staged hunk, `git diff` shows the newer unstaged hunk.

    **Follow-up:** How do you add the newer edit to the same commit before committing?

??? question "L4: Why does amending a commit change its SHA even if you only edited the message?"
    **Say first:** a commit's id is a hash of its full content, which includes the message, tree and parent, so any change to the message produces a different hash and therefore a new commit that replaces the old one.

    **Proof:** `git log --oneline` before and after `--amend` shows a different short SHA for the same subject.

    **Don't say:** "Amend edits the existing commit in place."

---

## Related

- [The Three Trees](../00-foundations/the-three-trees.md): the working tree, index and `HEAD` that `add` and `commit` move between
- [Inspecting History](inspecting-history.md): reading the commits you create
- [Undoing Changes](undoing-changes.md): unstaging, discarding and reverting
- [Inspecting History](inspecting-history.md): reading the commits you create

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
