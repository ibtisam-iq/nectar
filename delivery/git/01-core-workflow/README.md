# Core Workflow

The everyday loop: stage changes into a commit, read the history you build, keep generated and secret files out, and undo mistakes at the right level. These four topics are the commands a developer runs dozens of times a day.

---

## Revision Card

| Fact | Value |
|---|---|
| Stage | `git add <path>`; `-p` for hunks; `-u` for tracked only |
| Commit | `git commit -m`; `-am` for tracked; `--amend` to fix the last |
| Short status | Column 1 = index, column 2 = working tree |
| Log shape | `git log --oneline --graph --all` |
| Range (log) | `A..B` reachable-from-B; `A...B` symmetric difference |
| Range (diff) | `A..B` tip-to-tip; `A...B` against the merge base |
| Ignore rule | `.gitignore`; `git check-ignore -v` explains a match |
| Undo unstaged | `git restore <file>` |
| Undo commit | `reset --soft/--mixed/--hard`; `revert` for shared |

| Task | Command |
|---|---|
| Stage part of a file | `git add -p` |
| Fix the last commit | `git commit --amend --no-edit` |
| Commits not yet pushed | `git log @{u}..HEAD` |
| Review a branch's changes | `git diff main...topic` |
| Untrack but keep on disk | `git rm --cached <path>` |
| Unstage a file | `git restore --staged <file>` |
| Back out a pushed commit | `git revert <sha>` |
| Remove untracked files | `git clean -fd` (preview with `-n`) |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Staging and Committing](staging-and-committing.md) | `add`, `add -p`, `commit`, `--amend`, status codes | Core | High |
| [Inspecting History](inspecting-history.md) | Log formats, revision selection, ranges, `show`, `blame` | Core | High |
| [Ignoring and Attributes](ignoring-and-attributes.md) | `.gitignore`, `.gitattributes`, line endings | Core | Med |
| [Undoing Changes](undoing-changes.md) | `restore`, `reset` modes, `revert`, `clean` | Core | High |

---

## Scenarios and Labs

- [Core Workflow Lab](../labs/core-workflow-lab.md): init, stage, commit, inspect and undo in a throwaway repository
- [Accidental Commit to Main](../interview/scenarios/accidental-commit-to-main.md): move a wrong-branch commit off `main`
- [Wrong-Branch Commits](../interview/scenarios/wrong-branch-commits.md): relocate commits made on the wrong branch
