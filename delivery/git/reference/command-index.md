# Command Index

Every Git command used across this folder, in one alphabetical list, with a one-line reminder of what it does and the topic that covers it. Use it to jump from a half-remembered name to the page that explains the flags. Plumbing commands are marked; the rest are everyday porcelain.

---

## A to C

| Command | Does | Topic |
|---|---|---|
| `git add` | Stage changes; `-p` stages selected hunks | [Staging and Committing](../01-core-workflow/staging-and-committing.md) |
| `git bisect` | Binary-search history for the first bad commit | [Bisect](../05-history-and-recovery/bisect.md) |
| `git blame` | Show who last changed each line | [Inspecting History](../01-core-workflow/inspecting-history.md) |
| `git branch` | List, create, delete or rename branches | [Branches](../02-branching-and-merging/branches.md) |
| `git cat-file` (plumbing) | Print an object's type, size or content | [Object Model](../06-internals/object-model.md) |
| `git cherry-pick` | Apply a specific commit onto the current branch | [Cherry-Pick](../02-branching-and-merging/cherry-pick.md) |
| `git clean` | Delete untracked files and directories | [Undoing Changes](../01-core-workflow/undoing-changes.md) |
| `git clone` | Copy a remote repository locally | [Remotes](../03-remotes-and-collaboration/remotes.md) |
| `git commit` | Record staged changes; `--amend` rewrites the last | [Staging and Committing](../01-core-workflow/staging-and-committing.md) |
| `git config` | Read and write configuration at a level | [Install and Config](../00-foundations/install-and-config.md) |

---

## D to H

| Command | Does | Topic |
|---|---|---|
| `git describe` | Name a commit by the nearest tag plus distance | [Tags and Releases](../03-remotes-and-collaboration/tags-and-releases.md) |
| `git diff` | Show changes between trees, index or commits | [Inspecting History](../01-core-workflow/inspecting-history.md) |
| `git fetch` | Download refs and objects, changing no branch | [Remotes](../03-remotes-and-collaboration/remotes.md) |
| `git filter-repo` (external) | Rewrite history to remove files or strings | [Filter-Repo and Secrets](../05-history-and-recovery/filter-repo-and-secrets.md) |
| `git fsck` | Verify object integrity, find dangling objects | [Packfiles and GC](../06-internals/packfiles-and-gc.md) |
| `git gc` | Repack objects and prune unreachable ones | [Packfiles and GC](../06-internals/packfiles-and-gc.md) |
| `git hash-object` (plumbing) | Compute or write an object's SHA | [Object Model](../06-internals/object-model.md) |

---

## I to M

| Command | Does | Topic |
|---|---|---|
| `git init` | Create a new repository | [What Is Git](../00-foundations/what-is-git.md) |
| `git log` | Show commit history with many formats | [Inspecting History](../01-core-workflow/inspecting-history.md) |
| `git ls-files` (plumbing) | List tracked files and their index modes | [Submodules](../07-advanced-tooling/submodules.md) |
| `git ls-tree` (plumbing) | List a tree object's entries | [Object Model](../06-internals/object-model.md) |
| `git maintenance` | Schedule background upkeep of a repo | [Large Repos](../07-advanced-tooling/large-repos.md) |
| `git merge` | Join two branches into one | [Merging](../02-branching-and-merging/merging.md) |
| `git merge-base` (plumbing) | Find the common ancestor of two commits | [How Merge and Rebase Work](../06-internals/how-merge-and-rebase-work.md) |
| `git mv` | Move or rename a tracked file | [Staging and Committing](../01-core-workflow/staging-and-committing.md) |

---

## N to R

| Command | Does | Topic |
|---|---|---|
| `git pull` | Fetch then merge (or rebase) the upstream | [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md) |
| `git push` | Send commits to a remote; `--force-with-lease` safely | [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md) |
| `git rebase` | Replay commits onto a new base; `-i` to reshape | [Rebasing](../02-branching-and-merging/rebasing.md) |
| `git reflog` | Show every move of `HEAD`, to recover lost commits | [Reflog and Recovery](../05-history-and-recovery/reflog-and-recovery.md) |
| `git remote` | List and manage remotes | [Remotes](../03-remotes-and-collaboration/remotes.md) |
| `git reset` | Move the branch; `--soft`/`--mixed`/`--hard` | [Undoing Changes](../01-core-workflow/undoing-changes.md) |
| `git restore` | Discard working-tree or unstage changes | [Undoing Changes](../01-core-workflow/undoing-changes.md) |
| `git revert` | Add a commit that inverts an earlier one | [Undoing Changes](../01-core-workflow/undoing-changes.md) |
| `git rev-list` (plumbing) | List commit or object SHAs for scripting | [Bloated Repo, Large File](../interview/scenarios/bloated-repo-large-file.md) |
| `git rev-parse` (plumbing) | Resolve a name to a SHA or repo fact | [Refs and HEAD](../06-internals/refs-and-head.md) |
| `git rm` | Remove a tracked file and stage the removal | [Undoing Changes](../01-core-workflow/undoing-changes.md) |

---

## S to Z

| Command | Does | Topic |
|---|---|---|
| `git show` | Show a commit, tag or object with its diff | [Inspecting History](../01-core-workflow/inspecting-history.md) |
| `git sparse-checkout` | Materialize only chosen paths in the working tree | [Large Repos](../07-advanced-tooling/large-repos.md) |
| `git stash` | Shelve working-tree changes for later | [Stashing](../03-remotes-and-collaboration/stashing.md) |
| `git status` | Show staged, modified and untracked state | [Staging and Committing](../01-core-workflow/staging-and-committing.md) |
| `git submodule` | Manage embedded repositories (gitlinks) | [Submodules](../07-advanced-tooling/submodules.md) |
| `git switch` | Change branch; `-c` creates, `--detach` detaches | [Branches](../02-branching-and-merging/branches.md) |
| `git tag` | Create and list tags, lightweight or annotated | [Tags and Releases](../03-remotes-and-collaboration/tags-and-releases.md) |
| `git update-ref` (plumbing) | Create or move a ref directly | [Refs and HEAD](../06-internals/refs-and-head.md) |
| `git worktree` | Attach extra working directories to one repo | [Worktrees](../07-advanced-tooling/worktrees.md) |

---

## Related

- [Cheatsheet](cheatsheet.md): the same commands grouped by task
- [Config Reference](config-reference.md): the keys `git config` sets
- [Glossary](glossary.md): the objects and terms these commands act on
- [Error Messages](error-messages.md): what to do when one of these fails
