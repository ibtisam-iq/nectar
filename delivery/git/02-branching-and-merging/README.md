# Branching and Merging

How Git creates lines of work and brings them back together: branches, merge and rebase, interactive history editing, conflict resolution, and cherry-picking single commits.

---

## Revision Card

| Fact | Value |
|---|---|
| Branch | A file under `refs/heads/` holding one commit SHA |
| `HEAD` | The current branch, or a commit when detached |
| Fast-forward | Pointer moves up when there is no divergence |
| Three-way merge | Two-parent commit built from the two tips and their merge base |
| Rebase | Replays commits onto a new base; new SHAs; linear history |
| Golden rule | Never rebase or rewrite commits others have pulled |
| Conflict markers | `<<<<<<< HEAD` ours, `=======`, `>>>>>>>` theirs |
| Cherry-pick | Copies one commit's diff as a new commit |

| Task | Command |
|---|---|
| Create and switch | `git switch -c <name>` |
| Merge, keep the merge visible | `git merge --no-ff <branch>` |
| Rebase onto the latest base | `git rebase <base>` |
| Squash work before a PR | `git rebase -i <base>` |
| See both sides of a conflict | `git diff` |
| Take one side | `git checkout --ours` or `--theirs <file>` |
| Back out a merge or rebase | `git merge --abort` / `git rebase --abort` |
| Backport one commit | `git cherry-pick -x <sha>` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Branches](branches.md) | Create, switch, `HEAD`, tracking, detached HEAD | Core | High |
| [Merging](merging.md) | Fast-forward vs three-way, `--no-ff`, squash, merge base | Core | High |
| [Rebasing](rebasing.md) | Rebase vs merge, the golden rule, `--onto` | Core | High |
| [Interactive Rebase](interactive-rebase.md) | Squash, fixup, reword, reorder, autosquash | Advanced | High |
| [Conflict Resolution](conflict-resolution.md) | Markers, index stages, `--ours`/`--theirs`, rerere | Core | High |
| [Cherry-Pick](cherry-pick.md) | Single commit, `-x`, ranges, backporting | Core | Med |

---

## Scenarios and Labs

- [Merge Conflict Resolution](../interview/scenarios/merge-conflict-resolution.md): a pull stops on a conflict and must be resolved cleanly
- [Detached HEAD](../interview/scenarios/detached-head.md): commits made off a branch, and how to save them
- [Branching and Rebase Lab](../labs/branching-and-rebase-lab.md): merge, rebase and resolve conflicts by hand
