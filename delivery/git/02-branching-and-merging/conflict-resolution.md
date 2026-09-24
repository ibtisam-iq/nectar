# Conflict Resolution

A conflict happens when two branches change the same lines and Git cannot decide which to keep. Interviewers test this because "how do you resolve a merge conflict" separates people who understand the three-way model from people who guess at the markers.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Conflict | Both sides changed the same lines, so Git cannot merge them automatically | `git status` |
| Markers | `<<<<<<< HEAD`, `=======`, `>>>>>>> <branch>` wrap the two versions | `grep -n '^<<<<<<<' <file>` |
| Ours | The side above `=======`; `HEAD` during a merge | `git checkout --ours <file>` |
| Theirs | The side below `=======`; the merged-in branch during a merge | `git checkout --theirs <file>` |
| Status code | `UU` means both modified and unmerged | `git status -s` |
| Index stages | `git ls-files -u` lists stage 1 base, 2 ours, 3 theirs | `git ls-files -u` |
| Mark resolved | `git add <file>` after editing removes the conflict | `git status` |
| Finish | `git commit` for a merge, `git rebase --continue` for a rebase | `git log --graph` |
| Abort | `git merge --abort` or `git rebase --abort` | `git status` |
| Reuse | `git config rerere.enabled true` records and replays resolutions | `git rerere status` |
<!-- --8<-- [end:facts] -->

---

## Anatomy of a Conflict

When a merge cannot combine two edits, it stops and writes both versions into the file, wrapped in markers.

```bash
git merge --no-edit feature/tls
```

Output:

```text
Auto-merging config.yml
CONFLICT (content): Merge conflict in config.yml
Automatic merge failed; fix conflicts and then commit the result.
```

```bash
cat config.yml
```

Output:

```text
<<<<<<< HEAD
port: 8080
=======
port: 443
>>>>>>> feature/tls
host: localhost
```

The section above `=======` is the current branch (`HEAD`); the section below is the branch being merged. `host: localhost` is unmarked because both branches left that line alone.

```bash
git status -s
```

Output:

```text
UU config.yml
```

`UU` means both sides modified the file and it is unmerged. Under the surface, Git keeps three versions of the file in the index.

```bash
git ls-files -u
```

Output:

```text
100644 5ab6017ddae91fae7dc714a9b89732b7710cb77d 1	config.yml
100644 4613bb33d5f023a45bf31101269c95b75f6ab318 2	config.yml
100644 64dc71e58e09598699bb66b75c397a7c62d3dd04 3	config.yml
```

Stage 1 is the merge base, stage 2 is ours, stage 3 is theirs. Git resolves the conflict when the working file is staged and these unmerged entries are replaced by a single stage-0 entry.

---

## Resolving a Conflict

Resolution means editing the file to the intended final content, removing all markers, then staging and committing.

```bash
git diff
```

Output:

```text
diff --cc config.yml
index 4613bb3,64dc71e..0000000
--- a/config.yml
+++ b/config.yml
@@@ -1,2 -1,2 +1,6 @@@
++<<<<<<< HEAD
 +port: 8080
++=======
+ port: 443
++>>>>>>> feature/tls
  host: localhost
```

The combined diff (`diff --cc`) shows both sides at once, with two columns of change markers. After editing `config.yml` to the wanted line and deleting the markers, stage and commit.

```bash
git add config.yml
git commit --no-edit
```

Output:

```text
[main 974b4c5] Merge branch 'feature/tls'
```

`git add` on the edited file is what tells Git the conflict is resolved. The merge commit records both parents, so the history still shows where the branches joined.

!!! warning "A committed conflict marker is a real bug"
    Nothing stops `git add` on a file that still contains `<<<<<<<`. Search for leftover markers before committing (`git diff --check` reports them), because a committed marker breaks the file at runtime.

---

## Taking One Whole Side

When one branch's version of a file is entirely correct, `git checkout --ours` or `--theirs` replaces the file with that side instead of hand-editing.

```bash
git checkout --theirs gen.txt
git add gen.txt
```

Output:

```text
Updated 1 path from the index
```

`--ours` keeps the current branch's version; `--theirs` takes the merged-in branch's version.

!!! danger "Ours and theirs are reversed during a rebase"
    In a merge, `--ours` is your branch and `--theirs` is the branch you are merging. In a rebase, Git replays your commits onto the other branch, so `--ours` is the branch you are rebasing onto and `--theirs` is your own commit. Check which operation is running before choosing a side.

---

## Aborting

If a resolution is going wrong, back out completely rather than committing a half-merge.

```bash
git merge --abort
```

`git merge --abort` restores the working tree and index to the pre-merge commit; `git rebase --abort` does the same for a rebase. Neither leaves partial resolutions behind.

---

## Reusing a Resolution with rerere

`rerere` (reuse recorded resolution) remembers how a conflict was resolved and replays it automatically the next time the same conflict appears, which is common during a long rebase or repeated merges.

```bash
git config rerere.enabled true
git merge --no-edit topic
```

The first time, the merge conflicts and Git records the conflict's preimage.

Output:

```text
Auto-merging f.txt
CONFLICT (content): Merge conflict in f.txt
Recorded preimage for 'f.txt'
Automatic merge failed; fix conflicts and then commit the result.
```

After you resolve, stage and commit, Git records the resolution against that preimage.

```bash
git commit --no-edit
```

Output:

```text
Recorded resolution for 'f.txt'.
[main 62da126] Merge branch 'topic'
```

When the same conflict recurs, Git applies the stored resolution.

```bash
git merge --no-edit topic
```

Output:

```text
Auto-merging f.txt
CONFLICT (content): Merge conflict in f.txt
Resolved 'f.txt' using previous resolution.
Automatic merge failed; fix conflicts and then commit the result.
```

The file is already resolved; it still needs staging and committing, but the manual edit is not repeated.

---

## Common Errors

### `error: Committing is not possible because you have unmerged files.`

**Cause:** `git commit` was run while a file still has unmerged stage entries, because it was edited but not staged.

**Fix:** `git add <file>` each resolved file, then commit; `git status` lists what is still unmerged.

### `fatal: 'gen.txt' is not in the working tree` when using `--theirs`

**Cause:** `git checkout --theirs` was run on a path that is not currently conflicted, so there is no stage-3 version to take.

**Fix:** confirm the conflict with `git status`; the path must show as unmerged for `--ours` and `--theirs` to apply.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What causes a merge conflict?"
    **Say first:** a conflict occurs when both branches change the same lines of a file (or one edits a file the other deleted), so Git cannot decide which change to keep.

    **Proof:** `git status` shows the file as `UU` (both modified); the file gains `<<<<<<<`, `=======` and `>>>>>>>` markers.

    **Follow-up:** In the markers, which side is above the `=======`?

??? question "L1: How do you resolve a conflict once Git has stopped?"
    **Say first:** edit each conflicted file to the intended content, remove all markers, `git add` the file, then commit the merge (or `git rebase --continue`).

    **Proof:** `git add` replaces the three unmerged index stages with one resolved entry; `git status` then shows the file as staged.

    **Follow-up:** What does `git add` actually change in the index when it marks a file resolved?
<!-- --8<-- [end:l1] -->

??? question "L2: Keep the incoming branch's entire version of a generated file during a merge."
    **Say first:** `git checkout --theirs <file>` then `git add <file>`.

    **Proof:**

    ```bash
    git checkout --theirs gen.txt
    git add gen.txt
    ```

    **Follow-up:** What would `--ours` and `--theirs` mean if this were a rebase instead of a merge?

??? question "L2: Show both sides of a conflict at once without opening the file in an editor."
    **Say first:** `git diff` during a conflict prints a combined diff (`diff --cc`) with both branches' changes.

    **Proof:** the output marks lines unique to each side with two columns of `+`, around the conflict markers.

    **Follow-up:** How can you list the base, ours and theirs versions from the index?

??? question "L3: A merge stopped on conflicts and you are unsure which side is correct, so you want to start over."
    **Say first:** abort the merge to return to the exact pre-merge state, then re-merge deliberately once the correct resolution is known.

    **Proof:** `git merge --abort` followed by `git status` shows a clean tree at the original commit.

    **Follow-up:** How would you avoid resolving the same conflict by hand every time during a long rebase?

??? question "L3: The same conflict keeps reappearing across a rebase of many commits, and resolving it each time is error-prone."
    **Say first:** enable rerere so Git records the resolution once and replays it on each recurrence.

    **Proof:** `git config rerere.enabled true`; later merges print `Resolved '<file>' using previous resolution`.

    **Follow-up:** Does rerere finish the merge for you, or is there still a step left?

??? question "L4: What are the three index stages during a conflict, and how does staging resolve it?"
    **Say first:** Git holds stage 1 (merge base), stage 2 (ours) and stage 3 (theirs) for the conflicted path; `git add` writes the working file as a single stage-0 entry and drops the three, which is what marks it resolved.

    **Proof:** `git ls-files -u` lists the numbered stages before resolution; after `git add`, the path leaves that list.

    **Don't say:** "Git picks the newer of the two changes automatically."

---

## Related

- [Merging](merging.md): the operation that raises most conflicts
- [Rebasing](rebasing.md): conflicts resolved one commit at a time
- [Branches](branches.md): the two pointers whose edits collide
- [Cherry-Pick](cherry-pick.md): conflicts when copying a single commit

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
