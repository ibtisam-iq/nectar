# Mock Interviews

Three full 45-minute sessions that mix screening, hands-on, troubleshooting and internals the way a real Git loop does. Run each end to end against the clock, then read the linked topic for anything that was slow.

---

## How to Use These

Set a 45-minute timer and answer out loud, one line first (Say first), then the proof. Each question notes what the interviewer is scoring and links to where the full answer lives, so a weak spot maps straight to a topic. Do not read the links until after the timer.

The three mocks escalate: the first is a junior screen, the second a recovery-and-collaboration loop, the third a senior internals round.

---

## Mock A: Junior DevOps Screen (45 min)

A breadth-first screen that starts light and probes depth on a few answers.

1. **(L1, 3 min)** What is the difference between `git fetch` and `git pull`? See [Remotes](../03-remotes-and-collaboration/remotes.md).
2. **(L1, 4 min)** Explain the three trees (working tree, index, HEAD) and what `add` and `commit` move between them. See [The Three Trees](../00-foundations/the-three-trees.md).
3. **(L2, 5 min)** Undo the last commit but keep its changes staged, and explain how `--soft`, `--mixed` and `--hard` differ. See [Undoing Changes](../01-core-workflow/undoing-changes.md).
4. **(L2, 5 min)** You committed to `main` with nothing pushed; move the work onto a feature branch. See [Accidental Commit to Main](scenarios/accidental-commit-to-main.md).
5. **(L2, 6 min)** When do you merge and when do you rebase, and what is the golden rule? See [Rebasing](../02-branching-and-merging/rebasing.md).
6. **(L3, 8 min)** Your push was rejected as non-fast-forward: diagnose it and integrate without losing the teammate's work. See [Diverged Branches, Push Rejected](scenarios/diverged-branches-push-rejected.md).
7. **(L3, 8 min)** A pull stopped on a conflict: resolve it from scratch and finish the merge. See [Merge Conflict Resolution](scenarios/merge-conflict-resolution.md).
8. **(L4, 6 min)** What does a commit object contain, and why can a commit not be edited in place? See [Object Model](../06-internals/object-model.md).

!!! tip "What a screen actually tests"
    The screen looks for someone who clarifies before acting and knows the basics cold. A confident `git status` then `git log --oneline --graph` beats naming an advanced tool you cannot drive, and "is this branch shared?" before any rewrite scores as highly as the fix.

---

## Mock B: Recovery and Collaboration (45 min)

Symptom-driven, with the interviewer withholding detail until you ask.

1. **(L1, 3 min)** What is the reflog, and what does it let you recover that `git log` does not show? See [Reflog and Recovery](../05-history-and-recovery/reflog-and-recovery.md).
2. **(L2, 5 min)** Read a `git status -sb` that says `[ahead 1, behind 1]`: what happened and can you push? See [Round 2: Hands-On](round-2-hands-on.md).
3. **(L3, 8 min)** "`reset --hard` ate a day of commits": get them back. See [Lost Commits After Reset](scenarios/lost-commits-after-reset.md).
4. **(L3, 8 min)** A teammate force-pushed and your commit vanished from the remote: recover it. See [Force-Push Clobbered a Teammate](scenarios/force-push-clobbered-teammate.md).
5. **(L2, 6 min)** A password was committed, pushed, then deleted in a later commit, but a scanner still flags it: name the two things you must do. See [Committed a Secret](scenarios/committed-a-secret.md).
6. **(L3, 7 min)** Your branch is `wip`/`fix`/`fix-again` commits: make it clean before the PR. See [Messy History Before a PR](scenarios/messy-history-before-pr.md).
7. **(L4, 8 min)** Why does rewriting one commit change the SHA of every commit after it? See [Rewriting History](../05-history-and-recovery/rewriting-history.md).

!!! tip "Withheld detail is part of the test"
    A recovery round often starts vague on purpose. Asking "is it pushed?", "does anyone else have it?", and "is the secret still valid?" scores as highly as the fix, because it decides between a safe rewrite and an inverse commit.

---

## Mock C: Senior Internals (45 min)

Depth-first, trading breadth for mechanism and trade-offs.

1. **(L2, 5 min)** Prove that Git stores snapshots, not diffs, and say why that is not wasteful. See [Object Model](../06-internals/object-model.md).
2. **(L4, 8 min)** Exactly what bytes does Git hash to produce a blob's SHA, and why does that give dedup, integrity and immutability at once? See [Object Model](../06-internals/object-model.md).
3. **(L4, 7 min)** How does `--force-with-lease` know the remote moved without seeing its live state? See [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md).
4. **(L4, 8 min)** What does the ort strategy actually compute during a three-way merge, and what is a virtual merge base? See [How Merge and Rebase Work](../06-internals/how-merge-and-rebase-work.md).
5. **(L4, 7 min)** How does a packfile store many versions of a file without keeping a full copy of each? See [Packfiles and GC](../06-internals/packfiles-and-gc.md).
6. **(L3, 5 min)** You need to share code between two repos: argue for a submodule versus a package or subtree. See [Submodules](../07-advanced-tooling/submodules.md).
7. **(L4, 5 min)** How does `git bisect` choose which commit to test, and why is it logarithmic in the number of commits? See [Bisect](../05-history-and-recovery/bisect.md).

!!! tip "Senior rounds reward the trade-off, not the recital"
    Naming the mechanism is table stakes; the signal is stating the cost. "Rebase gives a clean linear history but rewrites SHAs, so it must not touch shared commits" is the answer they want, not merely "rebase replays commits".

---

## Related

- [Round 1: Screening](round-1-screening.md): the L1 bank
- [Round 2: Hands-On](round-2-hands-on.md): the L2 tasks and output drills
- [Round 3: Troubleshooting](round-3-troubleshooting.md): the L3 scenario index
- [Round 4: Internals](round-4-internals.md): the L4 bank
- [Interview Overview](README.md): how the rounds fit together
