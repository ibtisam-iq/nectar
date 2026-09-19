# Interactive Rebase

Interactive rebase replays commits through an editable todo list, so history can be squashed, reworded, reordered or dropped before it is shared. Interviewers ask about it because cleaning up a messy branch before a pull request is a daily task, and because it rewrites history under the same golden rule as a plain rebase.

**Track:** Advanced · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Start | `git rebase -i <base>` opens a todo list of the commits after `<base>` | `git rebase -i HEAD~3` |
| `pick` | Keep the commit unchanged | the todo list |
| `reword` (r) | Keep the commit, edit its message | the todo list |
| `edit` (e) | Stop at the commit to amend its content | the todo list |
| `squash` (s) | Fold into the previous commit and combine messages | the todo list |
| `fixup` (f) | Fold into the previous commit and discard this message | the todo list |
| `drop` (d) | Remove the commit | the todo list |
| Reorder | Move a todo line to change commit order | the todo list |
| Autosquash | `git commit --fixup=<sha>` then `git rebase -i --autosquash` | `git config rebase.autoSquash` |
| Effect | Every commit from `<base>` forward gets a new SHA | `git log --oneline` |
<!-- --8<-- [end:facts] -->

---

## The Todo List

`git rebase -i <base>` writes a todo file listing each commit after `<base>` as a `pick` line, followed by the command legend. Editing the verbs and order controls what the rebase does.

```bash
git rebase -i HEAD~3
```

Output:

```text
pick 8e0c8be # Implement parser
pick a63a7d2 # fix typo
pick 0a5b85d # fix another typo

# Rebase a6307bb..0a5b85d onto a6307bb (3 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
# ... (trimmed)
# d, drop <commit> = remove commit
```

Commits appear oldest first, the reverse of `git log`. Saving the file with the edited verbs runs the plan; leaving every line as `pick` and saving is a no-op.

!!! tip "Deleting a line drops the commit"
    Each line is an instruction Git will run. Removing a line entirely drops that commit from the branch, the same as marking it `drop`. Reordering lines reorders the commits.

---

## Squash and Fixup

`squash` and `fixup` both fold a commit into the one above it. `squash` opens an editor to combine the two messages; `fixup` keeps only the earlier message and discards the folded commit's message, which suits typo and review-fix commits.

```bash
git log --oneline -4
```

Output:

```text
3c76ea7 fix another typo
ddd782f fix typo
8190f08 Implement parser
6a7e3ce Add feature skeleton
```

Marking the two typo commits as `fixup` in the todo folds them into `Implement parser`.

```bash
git rebase -i HEAD~3
git log --oneline -3
```

Output:

```text
Successfully rebased and updated refs/heads/main.
d8cf489 Implement parser
6a7e3ce Add feature skeleton
```

The two noise commits are gone and their changes now live inside `Implement parser`, which received a new SHA.

---

## Reword and Reorder

`reword` keeps a commit's changes but stops to edit its message, which fixes a bad or premature commit message without touching the content. Reordering is done by moving todo lines: Git replays them in the new order, so a commit can be pulled earlier or later in the branch.

Both are safe on unshared commits and both change SHAs from the edited commit forward, because each commit's SHA depends on its parent. A reorder that moves a commit past one that touches the same lines produces a conflict, resolved the same way as any rebase conflict.

!!! danger "Interactive rebase rewrites history, so the golden rule still applies"
    Squashing, rewording and reordering all create new commits and abandon the old ones. Run interactive rebase only on local, unpushed commits or a branch that is yours alone. Doing it on a shared branch forces every teammate into a divergent history.

---

## Autosquash

Autosquash automates the common case: while working, mark a fix as belonging to an earlier commit, then let Git place it correctly. `git commit --fixup=<sha>` writes a commit whose message is `fixup! <target subject>`.

```bash
git commit --fixup=HEAD~1
git log --oneline -3
```

Output:

```text
a73d689 fixup! Add module a
39a8574 Add module b
a0addc6 Add module a
```

`git rebase -i --autosquash` then generates a todo with the fixup moved directly under its target and marked `fixup`.

```bash
git rebase -i --autosquash --root
```

Output:

```text
pick a0addc6 # Add module a
fixup a73d689 # fixup! Add module a
pick 39a8574 # Add module b
```

Accepting that todo folds the fix into `Add module a`, leaving a clean two-commit history. Set `rebase.autoSquash=true` to make `--autosquash` the default for interactive rebases.

---

## Editing a Commit's Content

Marking a commit `edit` stops the rebase at that commit with the tree checked out, so its content can be amended before the rest replay.

```bash
git rebase -i HEAD~2
```

Output:

```text
Stopped at 17465bc...  # Add config
You can amend the commit now, with
# ... (trimmed)
```

After changing the files and staging them, `git commit --amend` rewrites that commit and `git rebase --continue` replays the remaining commits on top.

```bash
git commit --amend --no-edit
git rebase --continue
git log --oneline -3
```

Output:

```text
Successfully rebased and updated refs/heads/main.
ff90fae Finish app
63a7573 Add config
5f1ac1d Add app
```

`Add config` kept its position and message but received a new SHA, and `Finish app` was replayed onto it. This is the standard way to fix a mistake buried a few commits back without disturbing the ones around it.

---

## Common Errors

### `fatal: invalid upstream 'HEAD~3'`

**Cause:** the base reference points before the first commit, because the branch has fewer commits than the offset.

**Fix:** use a valid depth, or `git rebase -i --root` to include the very first commit.

### `error: could not apply <sha>... <subject>` during an interactive rebase

**Cause:** a reordered or edited commit conflicts with an earlier change to the same lines.

**Fix:** resolve the conflict, `git add` the files, and `git rebase --continue`; or `git rebase --abort` to undo the whole operation.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is interactive rebase used for?"
    **Say first:** it replays a range of commits through an editable todo list so you can squash, reword, reorder, edit or drop them before sharing the branch.

    **Proof:** `git rebase -i HEAD~3` opens the todo with a `pick` line per commit and a legend of the other verbs.

    **Follow-up:** What is the difference between squash and fixup?

??? question "L1: What is the difference between squash and fixup in a rebase todo?"
    **Say first:** both fold a commit into the previous one, but squash combines the two commit messages while fixup keeps only the earlier message and discards the folded one's.

    **Proof:** marking a commit `fixup` in the todo removes its message from the result; `squash` opens an editor to merge messages.

    **Follow-up:** Why is interactive rebase unsafe on a shared branch?
<!-- --8<-- [end:l1] -->

??? question "L2: Collapse three work-in-progress commits into one before opening a pull request."
    **Say first:** `git rebase -i HEAD~3`, keep the first as `pick`, and mark the rest `fixup` or `squash`.

    **Proof:**

    ```bash
    git rebase -i HEAD~3
    git log --oneline -2
    ```

    **Follow-up:** How would you automate this when the fixes were committed as you went?

??? question "L2: Fix a bad message on the second-to-last commit without changing its content."
    **Say first:** `git rebase -i HEAD~2` and mark that commit `reword`.

    **Proof:** Git stops to open the message editor for only that commit, then continues.

    **Follow-up:** Why does the commit's SHA change even though only the message changed?

??? question "L3: A pull request has ten noisy commits, but two of them were already pushed and reviewed on a shared branch."
    **Say first:** rebase only the commits that are still local; do not rewrite the two that others already have.

    **Proof:** `git log --oneline @{upstream}..HEAD` shows the local-only commits; the interactive rebase base must not reach past them.

    **Follow-up:** What breaks for teammates if the pushed commits are rewritten anyway?

??? question "L3: An interactive rebase stopped partway with a conflict and you are unsure how to finish it."
    **Say first:** resolve the conflicted files, stage them, and continue the rebase; abort if the plan was wrong.

    **Proof:** `git status` shows the paused rebase and the unmerged files; `git rebase --continue` after `git add`, or `git rebase --abort`.

    **Follow-up:** Where does Git keep the remaining todo while a rebase is paused?

??? question "L4: How does autosquash know where to place a fixup commit?"
    **Say first:** `git commit --fixup=<sha>` writes a commit whose subject is `fixup! <target subject>`, and `--autosquash` matches that subject to the target commit and reorders the todo to fold it in.

    **Proof:** the generated todo shows the `fixup` line moved directly under its target `pick` line.

    **Don't say:** "Autosquash guesses the target from the diff."

---

## Related

- [Rebasing](rebasing.md): the non-interactive rebase and the golden rule
- [Merging](merging.md): the history-preserving alternative
- [Conflict Resolution](conflict-resolution.md): resolving conflicts raised mid-rebase
- [Cherry-Pick](cherry-pick.md): copying a single commit rather than reshaping a range

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
