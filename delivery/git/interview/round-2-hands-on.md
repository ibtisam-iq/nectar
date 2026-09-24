# Round 2: Hands-On

The second round is at a keyboard: do a Git task under time pressure, or read the output of a command and say what state the repository is in. It scores whether you reach for the right command without hesitating and whether you can interpret real output, not recite theory.

---

## How This Round Works

The interviewer gives a short task ("move these commits off main onto a branch") or shows a captured screen ("here is `git status`, what happened?"). Speak the plan in one line, run or read, then confirm the result with the same command.

The tasks below are grouped by area and answered with a worked solution. The output-reading drills show a real capture: decide what state the repo is in before opening the answer.

---

## Timed Tasks

### Staging and Undoing

??? tip "Commit only part of your changes, leaving the rest for a separate commit"
    ```bash
    git add -p                       # stage selected hunks interactively
    git commit -m "feat: the focused change"
    git status                       # the rest is still modified, unstaged
    ```

    `git add -p` stages hunks one at a time, so one working-tree edit becomes two clean commits. The mechanics are in [Staging and Committing](../01-core-workflow/staging-and-committing.md).

??? tip "Undo the last commit but keep its changes staged"
    ```bash
    git reset --soft HEAD~1          # move the branch back one, keep the index
    git status                       # changes are staged, ready to recommit
    ```

    `--soft` moves the branch pointer only, leaving the index and working tree intact, unlike `--hard`. The three modes are in [Undoing Changes](../01-core-workflow/undoing-changes.md).

### Branching and History

??? tip "You committed to main by mistake, nothing pushed. Move the work to a feature branch"
    ```bash
    git branch feature               # point a new branch at the current tip
    git reset --hard origin/main     # or HEAD~N: rewind main to before the commits
    git switch feature               # your commits live here now
    ```

    The branch captures the commits before `reset` moves `main` back, so nothing is lost. Walked through in [Accidental Commit to Main](scenarios/accidental-commit-to-main.md).

??? tip "Squash the last three commits into one before opening a PR"
    ```bash
    git rebase -i HEAD~3             # mark the lower two as 'squash' (or 'fixup')
    git log --oneline                # one commit remains
    ```

    Interactive rebase combines the range into a single commit with a chosen message. Covered in [Interactive Rebase](../02-branching-and-merging/interactive-rebase.md).

### Remotes and Recovery

??? tip "Update your feature branch with the latest main, keeping history linear"
    ```bash
    git fetch origin
    git rebase origin/main           # replay your commits on top of main
    git push --force-with-lease      # if the branch was already pushed
    ```

    Rebase avoids a merge commit; `--force-with-lease` updates your own pushed branch safely. See [Rebasing](../02-branching-and-merging/rebasing.md) and [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md).

??? tip "Undo a change already pushed to a shared branch"
    ```bash
    git revert <sha>                 # a new commit that inverts the bad one
    git push                         # no force, history is only added to
    ```

    On shared history you add an inverse commit rather than rewriting, so no one is forced into a divergence. Covered in [Undoing Changes](../01-core-workflow/undoing-changes.md).

??? tip "Recover a branch you deleted an hour ago"
    ```bash
    git reflog                       # find the tip SHA the branch pointed at
    git branch recovered <sha>       # recreate it at that commit
    ```

    The reflog still holds the deleted branch's last commit until `gc` prunes it. Walked through in [Reflog and Recovery](../05-history-and-recovery/reflog-and-recovery.md).

??? tip "Find which of 200 commits introduced a regression, automatically"
    ```bash
    git bisect start HEAD <last-good-sha>
    git bisect run ./test.sh         # test.sh exits 0 on good, non-zero on bad
    git bisect reset                 # after it names the first bad commit
    ```

    `bisect run` binary-searches with your test script, in about eight steps for 200 commits. Covered in [Bisect](../05-history-and-recovery/bisect.md).

---

## Output-Reading Drills

Read each capture and decide what state the repository is in before opening the answer.

### Drill 1: git status

Output:

```text
On branch main
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both modified:   page.txt

no changes added to commit (use "git add" and/or "git commit -a")
```

??? tip "What state is this?"
    A merge is paused on a conflict: `page.txt` is `both modified` and listed under `Unmerged paths`. The next move is to edit the file, `git add page.txt` to mark it resolved, then `git commit` to finish the merge, or `git merge --abort` to back out entirely. Covered in [Conflict Resolution](../02-branching-and-merging/conflict-resolution.md).

### Drill 2: the conflicted file

Output:

```text
title: Home
<<<<<<< HEAD
body: welcome home
=======
body: welcome to the shop
>>>>>>> feature
```

??? tip "What do these markers mean?"
    The block between `<<<<<<< HEAD` and `=======` is the current branch's version (ours); the block from `=======` to `>>>>>>> feature` is the incoming branch's version (theirs). Resolving means editing to the intended final content and deleting all three marker lines, then staging the file. Covered in [Conflict Resolution](../02-branching-and-merging/conflict-resolution.md).

### Drill 3: git status -sb

Output:

```text
## main...origin/main [ahead 1, behind 1]
```

??? tip "What state is this, and can you push?"
    The branches have diverged: you have one commit the remote lacks (`ahead 1`) and it has one you lack (`behind 1`), so a plain `git push` is rejected as non-fast-forward. Integrate first with `git pull --rebase` (or a merge), then push. Covered in [Diverged Branches, Push Rejected](scenarios/diverged-branches-push-rejected.md).

### Drill 4: git push

Output:

```text
To origin
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to 'origin'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. If you want to integrate the remote changes,
hint: use 'git pull' before pushing again.
```

??? tip "Why was it rejected, and what should you not do?"
    The remote has commits your branch does not, so the push is not a fast-forward and Git refuses to overwrite them. The wrong move is `git push --force`, which discards the teammate's commit; the right move is `git pull --rebase` to replay your work on top, then push. Covered in [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md).

### Drill 5: git log --oneline --graph --all

Output:

```text
* e457a42 My change
| * edf00bd Teammate change
|/
* 7eb91c7 Base
```

??? tip "What does the fork show?"
    The two lines split after `Base`: `My change` is on the current branch and `Teammate change` on the remote-tracking branch, so history has diverged from a shared ancestor (the graph view of `[ahead 1, behind 1]`). Reconciling means rebasing or merging one onto the other. Covered in [Inspecting History](../01-core-workflow/inspecting-history.md).

### Drill 6: git reflog

Output:

```text
eafb3ac HEAD@{0}: reset: moving to HEAD~2
3433eae HEAD@{1}: commit: Wire up API
1a862f6 HEAD@{2}: commit: Add tests
eafb3ac HEAD@{3}: commit: Add validation
05cba44 HEAD@{4}: commit (initial): Add login form
```

??? tip "What happened, and how do you undo it?"
    A `reset --hard HEAD~2` moved the branch back two commits (`HEAD@{0}`), so `Wire up API` and `Add tests` are no longer on the branch, but the reflog still holds their SHAs at `HEAD@{1}` and `HEAD@{2}`. Recover with `git reset --hard 3433eae` (or `HEAD@{1}`). Covered in [Reflog and Recovery](../05-history-and-recovery/reflog-and-recovery.md).

### Drill 7: git status

Output:

```text
HEAD detached at 1a862f6
nothing to commit, working tree clean
```

??? tip "What state is this, and why does it matter?"
    `HEAD` points straight at a commit instead of a branch, so any commit made here is not on a branch and is lost once you switch away. If you have work to keep, create a branch with `git switch -c <name>` before leaving. Covered in [Detached HEAD](scenarios/detached-head.md).

---

## Related

- [Round 1: Screening](round-1-screening.md): the L1 questions that precede this round
- [Round 3: Troubleshooting](round-3-troubleshooting.md): unscripted symptoms and the scenario index
- [Round 4: Internals](round-4-internals.md): the L4 mechanism questions
- [Inspecting History](../01-core-workflow/inspecting-history.md): reading `log`, `--graph`, `status` and `diff`

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09. Conflict, divergence and reflog states were produced with real merges, pushes and resets.
