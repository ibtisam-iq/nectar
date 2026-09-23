# Team Workflows

The conventions that let a group share one repository: how branches are organised, how commits are written, how changes are reviewed, and how releases are cut and versioned. These are the Workflow-track topics, where Git meets team process.

---

## Revision Card

| Fact | Value |
|---|---|
| Trunk-based | Short-lived branches, merge to `main` daily |
| Gitflow | `main`, `develop`, `release/*`, `hotfix/*` for versioned releases |
| Conventional Commit | `type(scope): subject`; `feat`/`fix`/`docs`/`refactor`/`chore` |
| Breaking change | `type!:` and a `BREAKING CHANGE:` footer |
| Sign-off | `git commit -s` adds `Signed-off-by:` |
| range-diff | Compare two versions of a branch after a force-push |
| Fixup flow | `git commit --fixup=<sha>`, then `rebase -i --autosquash` |
| Semantic version | `MAJOR.MINOR.PATCH`; feat=minor, fix=patch, breaking=major |

| Task | Command |
|---|---|
| Squash a feature onto main | `git merge --squash <branch>; git commit` |
| Sign off a commit | `git commit -s` |
| Fix a message | `git commit --amend` or `rebase -i` (`reword`) |
| Review a branch's net change | `git diff main...feature` |
| See what changed between reviews | `git range-diff main <old> <new>` |
| Changelog since a release | `git log v1.0.0..HEAD --pretty=format:'- %s'` |
| Cut a release | `git tag -a v1.1.0 -m "1.1.0"` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Branching Strategies](branching-strategies.md) | Trunk-based, GitHub flow, gitflow, trade-offs | Workflow | High |
| [Commit Conventions](commit-conventions.md) | Conventional Commits, atomic commits, sign-off | Workflow | High |
| [Code Review with Git](code-review-with-git.md) | Local review, `range-diff`, the fixup flow | Workflow | Med |
| [Release and Versioning](release-and-versioning.md) | Semver, changelogs, release branches, tagging | Workflow | Med |

---

## Scenarios and Labs

- [Messy History Before a PR](../interview/scenarios/messy-history-before-pr.md): clean up work-in-progress commits before review
- [Branching and Rebase Lab](../labs/branching-and-rebase-lab.md): the rebase and squash mechanics these conventions rely on
