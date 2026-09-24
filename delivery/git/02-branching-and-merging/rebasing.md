# Rebasing

Rebase replays the commits of a branch onto a new base, producing a linear history in place of a merge commit. Interviewers use rebase to test the merge-versus-rebase trade-off and the golden rule, because a wrong rebase on shared history breaks a whole team.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Rebase | Replays the current branch's commits onto a new base as new commits | `git rebase <base>` |
| Result | Linear history; every replayed commit gets a new SHA | `git log --oneline` |
| Merge vs rebase | Merge keeps history and adds a merge commit; rebase rewrites it linearly | `git log --graph` |
| Golden rule | Never rebase commits others have already pulled | team policy |
| `--onto` | `git rebase --onto <newbase> <upstream> <branch>` moves a commit range | `git log --graph` |
| After a conflict | `git rebase --continue` or `git rebase --abort` | `git status` |
| Pull with rebase | `git pull --rebase` replays local commits on top of fetched ones | `git config pull.rebase` |
| Interactive | `git rebase -i <base>` edits, squashes and reorders | `git rebase -i HEAD~3` |
| Dirty tree | `git rebase --autostash` stashes and restores uncommitted work | `git config rebase.autoStash` |
| After rewriting | A pushed branch needs `git push --force-with-lease` | `git push --force-with-lease` |
<!-- --8<-- [end:facts] -->

---

## Rebase vs Merge

Both integrate one branch into another. A merge records that two lines of work joined; a rebase rewrites one line so it looks as if it started from the other's tip.

| | Merge | Rebase |
|---|---|---|
| **History** | Preserved, with a merge commit | Rewritten, linear |
| **Commit SHAs** | Unchanged | New for every replayed commit |
| **Traceability** | Shows when branches joined | Hides that a branch existed |
| **Safe on shared commits** | Yes | No |
| **Result of a conflict** | One resolution in the merge commit | A resolution per replayed commit |

The choice is about history, not correctness: the working tree ends up the same, but merge keeps the true shape while rebase produces a cleaner line.

---

## Rebasing a Feature onto main

When `main` moves ahead while a feature is in progress, rebasing the feature onto the new `main` replays its commits on top, so the branch reads as if it started today.

```bash
git log --oneline --graph --all -4
```

Output:

```text
* f274655 Document setup on main
| * 1f12f42 Add ranking
| * eac9ddc Add search
|/
* 55df230 Add app entrypoint
```

```bash
git switch feature/search
git rebase main
```

Output:

```text
Successfully rebased and updated refs/heads/feature/search.
```

```bash
git log --oneline --graph --all -4
```

Output:

```text
* 6190961 Add ranking
* 415b3d3 Add search
* f274655 Document setup on main
* 55df230 Add app entrypoint
```

The two feature commits kept their messages but received new SHAs (`eac9ddc` became `415b3d3`, `1f12f42` became `6190961`), because a commit's SHA depends on its parent and the parent changed. The old commits still exist in the reflog until garbage collection.

!!! note "Rebase does not move main"
    Rebasing `feature` onto `main` only rewrites `feature`. `main` still points where it did. Fast-forwarding `main` onto the rebased feature is a separate step, which is what gives the final linear history.

---

## The Golden Rule of Rebasing

Rebasing creates new commits and abandons the old ones. If anyone else has based work on the old commits, their history and the rewritten history now disagree.

!!! danger "Never rebase commits that others have pulled"
    Rebasing a shared branch (such as `main` or a release branch) forces every teammate into a divergent history and duplicated commits. Rebase only local, unpushed commits, or a branch that is yours alone. Integrate shared branches with a merge.

A branch that was already pushed and then rebased needs `git push --force-with-lease`, which refuses to overwrite the remote if someone else pushed in the meantime. Plain `--force` skips that check and can clobber a teammate's commits.

---

## Moving a Range with --onto

`git rebase --onto <newbase> <upstream> <branch>` replays only the commits in `<upstream>..<branch>` onto `<newbase>`. It moves a topic branch off the wrong base without dragging along commits that belong to another branch.

```bash
git log --oneline --graph --all -4
```

Output:

```text
* 5533f40 Style UI panel
* 661448d Add UI panel
* 4060301 Add shared base work
* 5d435c7 Add app entrypoint
```

```bash
git rebase --onto main feature/base topic/ui
git log --oneline --graph --all -4
```

Output:

```text
Successfully rebased and updated refs/heads/topic/ui.
* c127351 Style UI panel
* 83002c6 Add UI panel
| * 4060301 Add shared base work
|/
* 5d435c7 Add app entrypoint
```

Only the two `topic/ui` commits moved onto `main`; `Add shared base work` (`4060301`) stayed on `feature/base`. This is the standard way to detach a branch that was accidentally started from another feature.

---

## Continuing and Aborting

A rebase replays commits one at a time, so a conflict stops it mid-way. Git pauses, marks the conflicted files, and waits for one of three commands.

| Command | Effect |
|---|---|
| `git rebase --continue` | After staging the resolved files, replay the next commit |
| `git rebase --skip` | Drop the current commit and continue |
| `git rebase --abort` | Undo the whole rebase and return to the starting commit |

A rebase that hits a conflict pauses on the offending commit and names the next step.

```bash
git switch feature/bump
git rebase main
```

Output:

```text
Auto-merging version.txt
CONFLICT (content): Merge conflict in version.txt
error: could not apply ed74932... Bump version to 1.1.0
# ... (trimmed)
```

```bash
git status
```

Output:

```text
interactive rebase in progress; onto 5eca1b8
Last command done (1 command done):
   pick ed74932 # Bump version to 1.1.0
No commands remaining.
You are currently rebasing branch 'feature/bump' on '5eca1b8'.
# ... (trimmed)
	both modified:   version.txt
```

After editing `version.txt`, `git add version.txt` and `git rebase --continue` replay the rest. `git rebase --autostash` (or `rebase.autoStash=true`) stashes uncommitted changes before the rebase and restores them after, so a dirty working tree does not block the operation. Conflict handling itself is covered in [Conflict Resolution](conflict-resolution.md).

---

## Common Errors

### `error: cannot rebase: You have unstaged changes.`

**Cause:** the working tree has uncommitted changes, which a rebase would overwrite as it moves commits.

**Fix:** commit or stash the changes first, or run `git rebase --autostash <base>`.

### `fatal: It seems that there is already a rebase-merge directory`

**Cause:** a previous rebase was left unfinished, so its state directory still exists.

**Fix:** finish it with `git rebase --continue`, or discard it with `git rebase --abort`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between merge and rebase?"
    **Say first:** merge joins two branches with a merge commit and keeps the real history, while rebase replays one branch's commits onto another base to produce a linear history with new commit SHAs.

    **Proof:** `git log --graph` after a merge shows a two-parent commit; after a rebase it shows one straight line with different SHAs.

    **Follow-up:** When is it unsafe to rebase?

??? question "L1: What is the golden rule of rebasing?"
    **Say first:** never rebase commits that other people have already pulled, because rebase rewrites those commits and forces everyone else into a divergent history.

    **Proof:** the rebased commits get new SHAs, so a teammate's clone still holds the old ones and diverges.

    **Follow-up:** What must you do to a shared remote branch after a rebase, and why is `--force-with-lease` safer than `--force`?
<!-- --8<-- [end:l1] -->

??? question "L2: main moved ahead while your feature was in progress. Put your feature on top of the latest main."
    **Say first:** rebase the feature onto `main`.

    **Proof:**

    ```bash
    git switch feature/search
    git rebase main
    git log --oneline --graph -4
    ```

    **Follow-up:** Why did every feature commit get a new SHA?

??? question "L2: A topic branch was started from the wrong branch. Move only its own commits onto main."
    **Say first:** `git rebase --onto main <wrong-base> topic` replays only the topic's commits.

    **Proof:** after the rebase, `git log --graph` shows the topic commits on `main` and the wrong base left behind.

    **Follow-up:** What range of commits does `--onto` actually replay?

??? question "L3: After a rebase and force-push, a teammate reports duplicated commits and a mess on the shared branch."
    **Say first:** a shared branch was rebased, so the rewritten commits collide with the copies teammates already had.

    **Proof:** `git log --oneline` on both sides shows the same changes under different SHAs; `git reflog` on the remote branch shows the force-push.

    **Follow-up:** How should that branch have been integrated instead, and how do teammates recover now?

??? question "L4: Why does rebasing change commit SHAs while merging does not?"
    **Say first:** a commit SHA is a hash of its content plus its parent and metadata; rebase gives each replayed commit a new parent, so its hash changes, while merge leaves existing commits and their parents untouched.

    **Proof:** `git show --format=%p <commit>` shows the parent SHA differs before and after the rebase.

    **Don't say:** "Rebase edits the existing commits in place."

---

## Related

- [Merging](merging.md): the history-preserving alternative to rebasing
- [Interactive Rebase](interactive-rebase.md): rebase that also edits, squashes and reorders
- [Conflict Resolution](conflict-resolution.md): resolving conflicts raised during a rebase
- [Branches](branches.md): the pointers a rebase rewrites

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
