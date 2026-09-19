# Cherry-Pick

Cherry-pick copies the changes of one commit onto the current branch as a new commit, without merging the whole branch. Interviewers ask about it for backporting: taking a single fix from `develop` into a release branch that must not receive everything else.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Cherry-pick | Applies one commit's diff onto the current branch as a new commit | `git cherry-pick <sha>` |
| New identity | Same change and message, new SHA and committer | `git log -1` |
| Record source | `-x` appends `(cherry picked from commit <sha>)` | `git log -1 --format=%b` |
| Range | `git cherry-pick A..B` copies commits after `A` through `B` | `git log --oneline` |
| Author date | Preserved from the original; committer date is now | `git show --format=fuller` |
| Apply only | `-n` (`--no-commit`) stages the change without committing | `git status` |
| Conflict | Resolve, `git add`, then `git cherry-pick --continue` | `git status` |
| Abort | `git cherry-pick --abort` restores the pre-pick state | `git status` |
| Skip | `git cherry-pick --skip` drops the current commit in a range | `git status` |
| Main use | Backporting a fix to a maintenance or release branch | team workflow |
<!-- --8<-- [end:facts] -->

---

## Copying a Single Commit

`git cherry-pick <sha>` takes the diff introduced by that commit and applies it to the current branch, then commits it with the original message.

```bash
git switch main
git cherry-pick 07ce7fa
```

Output:

```text
[main c5d5886] Fix null pointer in parser
 Date: Thu Sep 17 10:20:00 2026 +0500
 1 file changed, 1 insertion(+)
 create mode 100644 hotfix.py
```

The new commit `c5d5886` carries the same change as the source `07ce7fa`, but a different SHA because its parent and committer differ. Git prints the original author `Date` line to show the authorship was preserved.

!!! note "Cherry-pick copies a commit, it does not move it"
    The original commit stays on its branch. Cherry-picking the same change onto two branches leaves two commits with the same content and different SHAs, which is why a later merge of those branches can report the change as already present.

---

## Recording the Source with -x

`-x` appends a line naming the commit the change came from, which makes a backport traceable back to the original.

```bash
git cherry-pick -x 07ce7fa
git log -1 --format='%s%n%n%b'
```

Output:

```text
Fix null pointer in parser

(cherry picked from commit 07ce7faa0d533f9fae53e9ee90f2183af5ed347f)
```

Use `-x` for commits picked onto public branches, so anyone reading the release history can find the original. It is left off for private throwaway picks because the referenced SHA may not exist in every clone.

!!! tip "Use -n to combine a pick with other work before committing"
    `git cherry-pick -n <sha>` (`--no-commit`) applies the change to the working tree and index without committing, so several picks or edits can be gathered into one commit. Finish with a normal `git commit`.

---

## Cherry-Picking a Range

`git cherry-pick A..B` copies every commit after `A` up to and including `B`. The lower bound is exclusive, matching revision-range syntax elsewhere in Git.

```bash
git cherry-pick develop~2..develop
git log --oneline -3
```

Output:

```text
[backport2 7707a0a] Fix null pointer in parser
 Date: Thu Sep 17 10:20:00 2026 +0500
 1 file changed, 1 insertion(+)
 create mode 100644 hotfix.py
[backport2 c1179c8] Add feature two docs
 Date: Thu Sep 17 10:30:00 2026 +0500
 1 file changed, 1 insertion(+)
 create mode 100644 docs.md
c1179c8 Add feature two docs
7707a0a Fix null pointer in parser
```

Two commits were copied, `develop~1` and `develop`, because `develop~2` is the excluded lower bound. Each becomes its own new commit on the current branch.

---

## Conflicts

A cherry-pick applies a diff, so it conflicts when the target has changed the same lines. Git stops and offers the same continue, skip and abort commands as a rebase.

```bash
git cherry-pick 1c51408
git status -s
```

Output:

```text
Auto-merging v.txt
CONFLICT (content): Merge conflict in v.txt
error: could not apply 1c51408... Bump to 2.0.0
# ... (trimmed)
UU v.txt
```

Resolve the file, `git add` it, and `git cherry-pick --continue`; or back out entirely.

```bash
git cherry-pick --abort
```

`--abort` restores the working tree and index to the commit before the cherry-pick, leaving no partial change.

---

## Common Errors

### `error: your local changes would be overwritten by cherry-pick`

**Cause:** the working tree has uncommitted changes that the pick would overwrite.

**Fix:** commit or stash the changes first, then cherry-pick.

### `The previous cherry-pick is now empty`

**Cause:** the commit's change is already present on the current branch, so applying it produces no difference.

**Fix:** `git cherry-pick --skip` to drop it, or `git commit --allow-empty` to record an empty commit if one is wanted.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does git cherry-pick do?"
    **Say first:** it copies the changes introduced by a specific commit and applies them to the current branch as a new commit, without merging the rest of the source branch.

    **Proof:** `git cherry-pick <sha>` creates a new commit with the same message and change but a new SHA.

    **Follow-up:** Why does the cherry-picked commit have a different SHA from the original?

??? question "L1: When would you cherry-pick instead of merge?"
    **Say first:** when you need one commit from a branch, not all of it, such as backporting a single fix to a release branch that must not take unreleased features.

    **Proof:** `git cherry-pick <fix-sha>` onto the release branch brings only that change.

    **Follow-up:** How do you keep the backport traceable to the original commit?
<!-- --8<-- [end:l1] -->

??? question "L2: Backport a bug fix from develop to a release branch and keep a link to the original."
    **Say first:** cherry-pick the fix with `-x` so the source SHA is recorded.

    **Proof:**

    ```bash
    git switch release/1.4
    git cherry-pick -x <fix-sha>
    git log -1 --format=%b
    ```

    **Follow-up:** What does the `(cherry picked from commit ...)` line let a reviewer do?

??? question "L2: Copy a run of three consecutive commits from one branch to another."
    **Say first:** use a range, `git cherry-pick <start>~1..<end>`, remembering the lower bound is exclusive.

    **Proof:** `git log --oneline` on the target shows the three commits as new commits.

    **Follow-up:** Which commit does `A..B` exclude?

??? question "L3: A cherry-picked fix later shows up as a conflict when the two branches are finally merged."
    **Say first:** the same change now exists as two different commits, so the merge sees overlapping edits to the same lines.

    **Proof:** `git log --oneline --all` shows the fix under two SHAs; the merge conflicts on the shared lines.

    **Follow-up:** How does recording the source with `-x`, or merging instead of cherry-picking, reduce this?

??? question "L4: How does cherry-pick apply a commit, and why is the result not identical to the original?"
    **Say first:** cherry-pick computes the diff between the commit and its parent and applies that diff to the current tip, then makes a new commit; the SHA differs because the parent and committer metadata are new.

    **Proof:** `git show --format=fuller <new>` shows the preserved author but a new committer and commit date.

    **Don't say:** "Cherry-pick moves the original commit onto the new branch."

---

## Related

- [Merging](merging.md): taking an entire branch instead of one commit
- [Rebasing](rebasing.md): replaying a run of commits onto a new base
- [Branches](branches.md): the branches a pick copies between
- [Conflict Resolution](conflict-resolution.md): resolving a cherry-pick that overlaps existing edits

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
