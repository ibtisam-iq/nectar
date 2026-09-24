# Inspecting History

Reading history is how you find when a change happened, who made it, and what a commit contains. Interviewers lean on this because revision selection (`HEAD~`, `^`, `A..B` versus `A...B`) is exact, and the two-dot and three-dot ranges mean opposite things to `git log` and `git diff`.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Compact log | `git log --oneline` (short SHA plus subject) | `git log --oneline` |
| Branch shape | `git log --oneline --graph --all` | `git log --graph` |
| Custom format | `git log --pretty=format:'%h %ad %an %s' --date=short` | `git log` |
| First parent back | `HEAD~1` (or `HEAD~n` for n steps) | `git rev-parse HEAD~1` |
| Nth parent | `HEAD^2` selects the second parent of a merge | `git rev-parse HEAD^2` |
| Log range | `A..B` = reachable from `B`, not from `A` | `git log A..B` |
| Log symmetric | `A...B` = commits on either side but not both | `git log --left-right A...B` |
| Diff two-dot | `git diff A..B` = tip-to-tip (A versus B) | `git diff A..B` |
| Diff three-dot | `git diff A...B` = B against the merge base of A and B | `git diff A...B` |
| Upstream | `@{upstream}` (or `@{u}`) is the tracked remote branch | `git log @{u}..HEAD` |
| One commit | `git show <rev>` shows its message and diff | `git show HEAD` |
| Line authorship | `git blame <file>` names the last commit per line | `git blame <file>` |
<!-- --8<-- [end:facts] -->

---

## Reading the Log

`git log --oneline` is the everyday view: one short SHA and subject per commit. Adding `--graph --all` draws the branch and merge structure across every ref, which is the fastest way to understand a repository's shape.

```bash
git log --oneline --graph --all
```

Output:

```text
*   445c620 Merge feature/search
|\
| * 387de87 Add ranking
| * 63238c6 Add search
* | 3e6d7e9 Add feature b
|/
* c640379 Add feature a
* b8fc6cf Add app
```

The `|\` shows the merge commit's two parents, and the two columns are the two lines of work that merged. A custom format prints exactly the fields wanted, which is what scripts and changelogs use.

```bash
git log --pretty=format:'%h %ad %an %s' --date=short -5
```

Output:

```text
445c620 2026-09-17 Amina Yusuf Merge feature/search
3e6d7e9 2026-09-17 Amina Yusuf Add feature b
387de87 2026-09-17 Amina Yusuf Add ranking
63238c6 2026-09-17 Amina Yusuf Add search
c640379 2026-09-17 Amina Yusuf Add feature a
```

`%h` is the short SHA, `%ad` the author date, `%an` the author name and `%s` the subject; `--date=short` trims the timestamp to a date.

---

## Revision Selection

A commit can be named by SHA, by branch or tag, or relative to another commit. `~` walks first parents, and `^` selects among a commit's parents.

```bash
git rev-parse --short HEAD~1
git rev-parse --short HEAD^2
```

Output:

```text
3e6d7e9
387de87
```

`HEAD~1` is one commit back along the first-parent line, and `HEAD~n` is n steps. `HEAD^2` is the second parent, which exists only on a merge commit, so it selects the merged-in branch's tip. `HEAD^` alone means `HEAD^1`, the first parent.

!!! info "~ walks generations, ^ chooses a parent"
    `HEAD~2` means "two first-parent steps back", the same as `HEAD^^`. `HEAD^2` means "the second parent of HEAD". They read similarly and are the most common revision-selection mix-up in an interview.

---

## Commit Ranges for the Log

For `git log`, `A..B` lists commits reachable from `B` but not from `A`, the standard "what is on B that A does not have".

```bash
git log --oneline main..topic
```

Output:

```text
cda7b9f Topic two
d6ea02d Topic one
```

`A...B` (three dots) lists the symmetric difference: commits on either side but not on both. `--left-right` marks which side each came from.

```bash
git log --oneline --left-right main...topic
```

Output:

```text
> cda7b9f Topic two
< 9ea0d5d Main one
> d6ea02d Topic one
```

`<` marks commits reachable from the left side (`main`), `>` from the right (`topic`). `git log @{u}..HEAD` uses the same two-dot form to list local commits not yet pushed.

---

## The Diff Range Convention Is Reversed

The dot notation means the opposite for `git diff`, which is the classic trap. For `git diff`, two dots compare the two tips directly.

```bash
git diff main..topic
```

Output:

```text
diff --git a/f b/f
index df967b9..f747ae3 100644
--- a/f
+++ b/f
@@ -1 +1,3 @@
 base
+topic1
+topic2
diff --git a/g b/g
deleted file mode 100644
index aa658b1..0000000
--- a/g
+++ /dev/null
@@ -1,2 +0,0 @@
-base
-main1
```

The tip-to-tip diff shows `g` as deleted, because `g` exists on `main` but not on `topic`. Three dots compare `B` against the merge base of `A` and `B`, showing only what `topic` changed since it forked.

```bash
git diff main...topic
```

Output:

```text
diff --git a/f b/f
index df967b9..f747ae3 100644
--- a/f
+++ b/f
@@ -1 +1,3 @@
 base
+topic1
+topic2
```

Three-dot `git diff` is what a pull request shows: the branch's own changes, not the unrelated work that landed on `main` in the meantime.

!!! warning "A..B and A...B are reversed between log and diff"
    For `git log`, `A..B` is a range and `A...B` is the symmetric difference. For `git diff`, `A..B` is tip-to-tip and `A...B` diffs against the merge base. Reviewing a branch uses `git diff main...topic`, never `main..topic`.

---

## Inspecting One Commit and Blame

`git show <rev>` prints a single commit's metadata and its diff, and `--stat` reduces the diff to a per-file summary.

```bash
git show --stat --oneline 63238c6
```

Output:

```text
63238c6 Add search
 search.py | 1 +
 1 file changed, 1 insertion(+)
```

`git blame <file>` attributes each line to the commit that last changed it, which finds when and why a specific line arrived.

```bash
git blame f
```

Output:

```text
^700e3e7 (Amina Yusuf 2026-09-17 10:00:00 +0500 1) base
d6ea02d2 (Amina Yusuf 2026-09-17 10:05:00 +0500 2) topic1
cda7b9f4 (Amina Yusuf 2026-09-17 10:10:00 +0500 3) topic2
```

The `^` prefix on `700e3e7` marks a boundary commit, the oldest commit blame reached. To follow a line back past a rename, `git blame -C -M` tracks content moved between and within files.

---

## Common Errors

### `fatal: ambiguous argument 'HEAD^2': unknown revision or path`

**Cause:** `HEAD^2` was requested on a non-merge commit, which has only one parent, or the caret was eaten by the shell.

**Fix:** use `HEAD^2` only on a merge commit; quote the argument (`'HEAD^2'`) so the shell does not interpret `^`.

### `fatal: no such path 'topic' in HEAD`

**Cause:** a range like `main..topic` was parsed as a path because `topic` is not a valid ref, often a typo or a deleted branch.

**Fix:** confirm the ref exists with `git branch -a`; use `--` to separate revisions from paths when a name is ambiguous.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How do you see the branch and merge structure of a repository quickly?"
    **Say first:** `git log --oneline --graph --all` draws every branch and merge as an ASCII graph with short SHAs and subjects.

    **Proof:** the `|\` and column layout show a merge commit's two parents and the two lines of work.

    **Follow-up:** What does `HEAD~2` select, and how is it different from `HEAD^2`?

??? question "L1: What is the difference between HEAD~2 and HEAD^2?"
    **Say first:** `HEAD~2` walks two first-parent steps back (the same as `HEAD^^`); `HEAD^2` selects the second parent of `HEAD`, which only exists on a merge commit.

    **Proof:** `git rev-parse HEAD^2` fails on a non-merge commit but resolves to the merged branch's tip on a merge.

    **Follow-up:** How do you list only the commits on a branch that another branch does not have?
<!-- --8<-- [end:l1] -->

??? question "L2: List the commits on your branch that are not yet pushed."
    **Say first:** `git log @{u}..HEAD` compares your branch against its upstream using a two-dot range.

    **Proof:**

    ```bash
    git log --oneline @{u}..HEAD
    ```

    **Follow-up:** What does `git log HEAD..@{u}` show instead?

??? question "L2: Review only the changes a feature branch introduced, ignoring what landed on main since it forked."
    **Say first:** `git diff main...topic` (three dots) diffs the branch against the merge base, which is exactly what a pull request shows.

    **Proof:** `git diff main..topic` (two dots) would instead show unrelated `main` files as deleted.

    **Follow-up:** Why is the dot convention reversed between `git log` and `git diff`?

??? question "L3: A line of code looks wrong and you need to know when and why it changed. Where do you start?"
    **Say first:** `git blame` the file to find the commit that last touched the line, then `git show` that commit for the reasoning in its message and diff.

    **Proof:** `git blame <file>` names the commit per line; `git show <sha>` explains it; `git log -S'<string>'` finds when a string first appeared.

    **Follow-up:** How do you make blame follow the line across a rename?

??? question "L4: For git log and git diff, what exactly do A..B and A...B compute?"
    **Say first:** for `git log`, `A..B` is commits reachable from `B` not `A`, and `A...B` is the symmetric difference; for `git diff`, `A..B` is tip-to-tip and `A...B` diffs `B` against the merge base of `A` and `B`.

    **Proof:** `git diff main..topic` showed `g` deleted (tip-to-tip); `git diff main...topic` showed only `topic`'s own additions.

    **Don't say:** "Two dots and three dots mean the same thing in both commands."

---

## Related

- [Staging and Committing](staging-and-committing.md): creating the commits this reads
- [The Three Trees](../00-foundations/the-three-trees.md): what `git diff` and `git diff --cached` compare
- [Branches](../02-branching-and-merging/branches.md): the refs that range syntax names
- [Rebasing](../02-branching-and-merging/rebasing.md): why `git diff main...topic` matches a rebased branch's changes

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
