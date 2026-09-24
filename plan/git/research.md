# Git Plan Research

How the module tree and interview coverage were validated, with sources. This is the completeness proof in place of a certification coverage map.

---

## 1. Coverage vs the Official Reference

The authoritative structure is the [Pro Git book](https://git-scm.com/book/en/v2) by Scott Chacon and Ben Straub, published on git-scm.com. Every in-scope chapter maps to a module in this folder.

| Pro Git chapter | Covered in |
|---|---|
| 1 Getting Started (VCS, history, what is Git, CLI, install, first-time setup, help) | 00-foundations |
| 2 Git Basics (get repo, recording changes, viewing history, undoing, remotes, tagging, aliases) | 01-core-workflow, 03-remotes-and-collaboration |
| 3 Git Branching (branches, basic/branch management, workflows, remote branches, rebasing) | 02-branching-and-merging, 04-team-workflows |
| 5 Distributed Git (workflows, contributing, maintaining) | 04-team-workflows, 03 forks-and-pull-requests |
| 7 Git Tools (revision selection, interactive staging, stashing, signing, searching, rewriting history, reset, advanced merging, rerere, debugging, submodules, credentials) | 01, 02, 03, 05, 07 |
| 8 Customizing Git (config, attributes, hooks) | 00 install-and-config, 01 ignoring-and-attributes, 07 hooks |
| 10 Git Internals (plumbing/porcelain, objects, refs, packfiles, maintenance and recovery) | 06-internals, 05 reflog-and-recovery |
| Appendix C Git Commands | reference/command-index.md |

**Deliberately out of scope**, with the reason:

| Pro Git chapter | Why out of scope |
|---|---|
| 4 Git on the Server (protocols, daemon, smart HTTP, GitWeb, GitLab) | Running Git servers is hosting, not Git-the-tool |
| 6 GitHub | Owned by `delivery/github/` |
| 9 Git and Other Systems (SVN client, migration) | Legacy VCS bridges, low interview value |

The mapping surfaced one gap, now fixed: revision selection (`HEAD~2`, `^`, ranges `A..B` vs `A...B`, `@{upstream}`, Pro Git 7.1) is folded into `01-core-workflow/inspecting-history.md`. Niche plumbing (`git bundle`, `git replace`) is left to a one-line mention at most.

---

## 2. Interview Topics

Cross-checked against current interview banks. Every question maps to a topic or a scenario.

- [KodeKloud, Git Interview Questions 2026](https://kodekloud.com/blog/git-interview-questions/): 30 questions in four tiers (Fundamentals, Intermediate, Advanced, Scenario). Fundamentals (Git vs GitHub, vs centralized VCS, the three areas, add vs commit, status codes, what a commit is, fetch vs pull, `.gitignore`) map to modules 00, 01 and 03. Intermediate (merge vs rebase, fast-forward vs 3-way, resolve a conflict, reset vs revert vs restore, `reset --soft/mixed/hard`, stash, branch vs tag, remote/origin/upstream, undo last commit) map to 01, 02 and 03. Advanced (interactive rebase and squash, cherry-pick, reflog, detached HEAD, reset vs revert for pushed work, how Git stores data, bisect) map to 02, 05 and 06. The six scenario questions (commit on the wrong branch, committed a secret, `reset --hard` recovery, a `pull` that stopped on a conflict, undo a pushed commit, a messy branch before a PR) match the `scenarios/` files nearly one-to-one.
- [NotHarshhaa, DevOps Interview Questions](https://github.com/NotHarshhaa/DevOps-Interview-Questions): a Git section covering internals (blobs, trees, commits), interactive rebase, cherry-pick, bisect and disaster recovery via reflog.
- [InterviewBit, Git Interview Questions](https://www.interviewbit.com/git-interview-questions/) and senior-edition compilations: branching strategies, merge/rebase, undoing changes, conflict resolution, internals, hooks, submodules, security, monorepos, troubleshooting.

Ten scenarios were chosen to cover the most-asked "what would you do" prompts: `accidental-commit-to-main`, `committed-a-secret`, `lost-commits-after-reset`, `messy-history-before-pr`, `merge-conflict-resolution`, `detached-head`, `force-push-clobbered-teammate`, `wrong-branch-commits`, `bloated-repo-large-file`, `diverged-branches-push-rejected`.

---

## 3. Answer Format

The `Say first / Proof / Follow-up` shape is grounded, not invented:

- **Say first** is BLUF, Bottom Line Up Front: state the answer in the first sentence, then the evidence, then any nuance. It is a documented interview technique ([Cameron-Brooks](https://www.cameron-brooks.com/answering-interview-questions-bluf-bottom-line-up-front/), [BLUF on Wikipedia](https://en.wikipedia.org/wiki/BLUF_(communication))).
- **Proof** is the evidence step: a command or captured output that shows the claim.
- **Follow-up** is the interviewer's likely next probe, kept with a short parenthetical pointer answer (consistent with the merged Linux folder), which chains L1 to L4 the way real rounds escalate.

---

## 4. Writing Standard Sources

Unchanged from Linux: the persona post at https://blog.ibtisam-iq.com/my-core-ai-engineering-persona/ (hard rules), then runbook and blog practice, then Diataxis and the Google developer documentation style guide. Recorded in `plan/standards/writing-standard.md`.
