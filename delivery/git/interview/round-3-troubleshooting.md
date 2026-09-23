# Round 3: Troubleshooting

The troubleshooting round starts with a symptom and no instructions. Interviewers score the path more than the final answer: whether the candidate asks the right questions, forms hypotheses, and checks the cheapest and most likely causes first. This page grows as each module is added.

---

## Method

1. **Restate the symptom** in one sentence and confirm it: what fails, on which branch, since when.
2. **Ask clarifying questions** that split the problem: local or pushed, one branch or many, since a rebase or a merge.
3. **Form two or three hypotheses** and say which is most likely and why.
4. **Check in order of cost:** read-only commands first (`git status`, `git log --graph`, `git reflog`, `git diff`), changes last.
5. **Fix the proven cause only,** then verify with the same command that found it.
6. **Name the prevention:** the control that stops a repeat.

!!! warning "Reaching for --force before reading the state loses points"
    A blind `git push --force` or `git reset --hard` as a first move suggests guessing. Say what you would look at first (`git status`, `git reflog`, `git log --graph --all`) and what each result would mean.

---

## Scenario Index

| Scenario | Symptom as asked | Modules |
|---|---|---|
| [Accidental Commit to Main](scenarios/accidental-commit-to-main.md) | "I committed to main before making a branch, nothing is pushed. Move the work off main." | 01 Core Workflow, 02 Branching and Merging |
| [Wrong-Branch Commits](scenarios/wrong-branch-commits.md) | "Commits landed on main but belong on an existing feature branch. Relocate them." | 01 Core Workflow, 02 Branching and Merging |
| [Merge Conflict Resolution](scenarios/merge-conflict-resolution.md) | "A pull stopped with a conflict and the repo is stuck. Get it merged cleanly." | 02 Branching and Merging |
| [Detached HEAD](scenarios/detached-head.md) | "Git says detached HEAD and I made commits here. Keep them." | 02 Branching and Merging |
| [Diverged Branches, Push Rejected](scenarios/diverged-branches-push-rejected.md) | "My push was rejected, the remote has work I do not. Push mine without losing theirs." | 03 Remotes and Collaboration |
| [Messy History Before a PR](scenarios/messy-history-before-pr.md) | "My branch is wip/fix/fix-again commits. Make it clean before the PR." | 02 Branching and Merging, 04 Team Workflows |
