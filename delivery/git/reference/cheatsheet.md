# Cheatsheet

The Git commands used most often, grouped by task, with no collapsible blocks so the page prints on one sweep. Each group links to the topic that explains the commands in full. Commands are cross-platform unless a note says otherwise.

---

## Setup and Config

```bash
git config --global user.name "Amina Yusuf"     # identity for commits
git config --global user.email "amina@example.com"
git config --global init.defaultBranch main     # default branch name
git config --global pull.rebase true            # pull rebases instead of merging
git config --list --show-origin                 # every setting and which file set it
git config --global alias.lg "log --oneline --graph --all"   # a shortcut
```

See [Install and Config](../00-foundations/install-and-config.md).

---

## Creating and Cloning

```bash
git init                       # start a repo in the current directory
git clone <url>                # clone a remote
git clone --depth 1 <url>      # shallow: only the latest commit
git clone --filter=blob:none <url>       # partial: blobs on demand
git clone --recurse-submodules <url>     # populate submodules too
```

See [What Is Git](../00-foundations/what-is-git.md) and [Large Repos](../07-advanced-tooling/large-repos.md).

---

## Staging and Committing

```bash
git status                     # what is staged, modified, untracked
git status -sb                 # short form with branch and ahead/behind
git add <path>                 # stage a file
git add -p                     # stage selected hunks interactively
git commit -m "message"        # commit the staged changes
git commit --amend             # replace the last commit (unpushed only)
git restore --staged <path>    # unstage, keep the working-tree change
```

See [Staging and Committing](../01-core-workflow/staging-and-committing.md) and [The Three Trees](../00-foundations/the-three-trees.md).

---

## Inspecting and Comparing

```bash
git log --oneline --graph --all    # compact history with branches
git log -p -- <path>               # history of one file with diffs
git show <sha>                     # a commit's message and diff
git diff                           # working tree vs index
git diff --staged                  # index vs HEAD
git diff A..B                      # commits reachable from B but not A
git blame <path>                   # who last changed each line
```

See [Inspecting History](../01-core-workflow/inspecting-history.md).

---

## Branching and Switching

```bash
git branch                     # list local branches
git switch <branch>            # change branch
git switch -c <new>            # create and switch
git branch -d <branch>         # delete a merged branch (-D to force)
git branch -m <old> <new>      # rename
git switch --detach <sha>      # check out a commit without a branch
```

See [Branches](../02-branching-and-merging/branches.md).

---

## Merging and Rebasing

```bash
git merge <branch>             # three-way merge into the current branch
git merge --no-ff <branch>     # force a merge commit
git merge --abort              # back out of a conflicted merge
git rebase <base>              # replay current branch onto base
git rebase -i <base>           # squash, reorder, reword, drop
git rebase --continue          # after resolving a conflict
git cherry-pick <sha>          # apply one commit here
```

See [Merging](../02-branching-and-merging/merging.md), [Rebasing](../02-branching-and-merging/rebasing.md), [Interactive Rebase](../02-branching-and-merging/interactive-rebase.md) and [Cherry-Pick](../02-branching-and-merging/cherry-pick.md).

---

## Undoing and Recovering

```bash
git restore <path>             # discard a working-tree change
git reset --soft HEAD~1        # undo commit, keep changes staged
git reset --mixed HEAD~1       # undo commit, keep changes unstaged (default)
git reset --hard HEAD~1        # undo commit and discard changes
git revert <sha>               # a new commit that inverts a pushed one
git reflog                     # every move of HEAD, to recover lost commits
git clean -fd                  # delete untracked files and directories
```

See [Undoing Changes](../01-core-workflow/undoing-changes.md) and [Reflog and Recovery](../05-history-and-recovery/reflog-and-recovery.md).

---

## Remotes: Fetch, Push, Pull

```bash
git remote -v                  # list remotes and URLs
git remote add origin <url>    # add a remote
git fetch origin               # download refs and objects, change nothing
git pull                       # fetch plus merge (or rebase, if configured)
git pull --rebase              # fetch then replay your commits on top
git push -u origin <branch>    # push and set upstream
git push --force-with-lease    # overwrite your own branch safely
```

See [Remotes](../03-remotes-and-collaboration/remotes.md) and [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md).

---

## Tags and Stash

```bash
git tag                        # list tags
git tag -a v1.2.0 -m "Release" # annotated tag
git push origin v1.2.0         # push one tag (--tags for all)
git describe --tags            # nearest tag plus distance
git stash                      # shelve working-tree changes
git stash pop                  # reapply and drop the latest stash
git stash list                 # see shelved changes
```

See [Tags and Releases](../03-remotes-and-collaboration/tags-and-releases.md) and [Stashing](../03-remotes-and-collaboration/stashing.md).

---

## History Rewriting and Cleanup

```bash
git rebase -i <base>           # reshape local commits before sharing
git filter-repo --path <file> --invert-paths    # purge a file from all history
git filter-repo --replace-text rules.txt        # scrub a string from history
git gc --prune=now             # repack and drop unreachable objects
git fsck                       # verify object integrity
```

See [Rewriting History](../05-history-and-recovery/rewriting-history.md), [Filter-Repo and Secrets](../05-history-and-recovery/filter-repo-and-secrets.md) and [Packfiles and GC](../06-internals/packfiles-and-gc.md).

---

## Advanced Tooling

```bash
git bisect start <bad> <good>  # binary-search for a regression
git bisect run ./test.sh       # automate the search
git worktree add ../hotfix -b hotfix    # a second checkout on a new branch
git submodule update --init --recursive # populate submodules after clone
git sparse-checkout set <dir>  # materialize only chosen paths
git log --show-signature -1    # verify a commit's signature
```

See [Bisect](../05-history-and-recovery/bisect.md), [Worktrees](../07-advanced-tooling/worktrees.md), [Submodules](../07-advanced-tooling/submodules.md) and [Credentials and Signing](../07-advanced-tooling/credentials-and-signing.md).

---

## Related

- [Command Index](command-index.md): the same commands A to Z with their topic files
- [Config Reference](config-reference.md): the config keys the setup commands write
- [Must-Know Facts](must-know-facts.md): the one-line facts behind these commands
- [Glossary](glossary.md): the terms these commands operate on
