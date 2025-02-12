# Comprehensive Git Commands Reference

This document provides a detailed guide on using Git for version control, including installation, configuration, basic commands, and advanced operations. It is structured for ease of use and covers various scenarios you might encounter when working with Git. Clink [here](https://cs.fyi/guide/git-cheatsheet).

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Basic Commands](#basic-commands)
    - [Initializing and Checking Status](#initializing-and-checking-status)
    - [Staging and Committing](#staging-and-committing)
    - [Undoing Changes](#undoing-changes)
4. [Viewing History](#viewing-history)
5. [Branching and Merging](#branching-and-merging)
    - [Working with Branches](#working-with-branches)
    - [Switching Branches](#switching-branches)
    - [Merging and Rebasing](#merging-and-rebasing)
6. [Working with Remotes](#working-with-remotes)
7. [Tags](#tags)
8. [Stashing](#stashing)

---

## Installation
```bash
# Check if Git is installed
which git

# Verify Git version
git --version
```

---

# Configuration

Git has three levels of configuration files:
- **--system**: Applies to all users on the system; requires root permissions.
- **--global**: Applies to the current user; accessible from any directory.
- **--local**: Specific to a repository.

```bash
# Set global configuration
git config --global user.name "ibtisam"
git config --global user.email "abc@gmail.com"
git config --global core.editor "vim"

# Set aliases for commands
git config --global alias.st "status"

# Unset configuration
git config --global --unset alias.st
git config --global --unset user.name

# List all global configurations
git config --global --list

# Edit global configuration file
git config --global --edit

# Outside the directory

ibtisam@mint-dell:~$ git config --list         
user.name=ibtisam
user.email=abc@gmail.com
core.editor=vim

# Inside the directory

ibtisam@mint-dell:~/git$ git config --list 
user.name=ibtisam
user.email=abc@gmail.com
core.editor=--help
core.repositoryformatversion=0
core.filemode=true
core.bare=false
core.logallrefupdates=true
remote.origin.url=https://github.com/ibtisam-iq/nectar.git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*

# View configuration files
cat ~/.gitconfig                # Global configuration
cat /etc/gitconfig              # System configuration
cat .git/config                 # Local configuration in a repository

# Set pull behavior
git config pull.rebase false    # Default: merge        # fetch & merge 
git config pull.rebase true     # Rebase on pull
git config pull.ff only         # Fast-forward only
```

---

# Basic Commands

## Initializing and Checking Status
```bash
git init                          # Initialize a Git repository
git status                        # Show the status of the working directory
```

## Staging and Committing
```bash
git add <filename>                # Stage a specific file
git add .                         # Stage all changes
git diff --cached                 # Show staged changes before committing
git commit -m "message"           # Commit changes with a message
git commit --dry-run              # Simulate a commit without making changes
```

## Undoing Changes

### Case 1: Undo Changes to Files (Unstaged)
- You just staged a file (not commited yet), and add some text (**not staged yet**), revert some text added.
- If you've made changes to a file but **haven't staged** or committed them, and you want to discard those changes.
- Reverts **unstaged** changes in the specified file to the state of the latest commit.
```bash
# Discard uncommitted changes to a file

git checkout <file>		            # Deprecated
git restore <file>
git restore --worktree <file>       # Explicitly applies to files in the working directory.
```

### Case 2: Undo Staged Changes
```bash
# Unstage a file

git reset <file>
git restore --staged <file>
```

### Case 3: Undo Commits
- Reset the commit, but keep the changes in the stagged area
```bash
# Reset to a previous commit without losing changes

git reset --soft <commit>
```
- Reset the commit, and discard the changes in the stagged area, but keep the changes in the working directory
```bash
# Reset and remove staged changes

git reset --mixed <commit>
```
- Reset the commit, and discard the changes in the stagged area and the working directory
```bash 
# Reset and discard all changes

git reset --hard <commit>
```
- Revert a commit, and create a new commit with the reverted changes
- A new commit is created that undoes the changes made in the specified commit.
```bash
# Create a new commit to undo a specific commit

git revert <commit>
```

### Case 4: Clean Untracked Files
```bash
git clean -n                         # Preview untracked files to delete # Dry run
git clean -f                         # Delete untracked files from the working directory
git clean -fd                        # Delete untracked files and directories
```
- Note: This will delete files that are not tracked by Git, but it will not delete files that are tracked by Git, even if they are not in the current commit.

---

# Viewing History
```bash
git log                             # Show commit history in reverse chronological order

git log --oneline                   # Compact view of commits

git log --pretty=format:"%h - %an, %ar: %s"  # Custom log format

git log --grep="keyword"            # Search commits by message

git log --since="YYYY-MM-DD"        # Filter commits after a date

git log --until="YYYY-MM-DD"        # Filter commits before a date

git log --author="author"           # Filter commits by author

git log --after="YYYY-MM-DD"        # Filter commits after a date

git log --before="YYYY-MM-DD"       # Filter commits before a date

git log --all                       # Show all branches
git log --graph                     # Show commit history with a graph

git log --stat                      # Show commit history with statistics

git log -2                          # Show the last two commits

git log -p -2                       # Show the last two commits with patch
```
# git diff
```bash
git diff                             # Show differences between working directory and staging area

git diff --staged                    # Show differences between staging area and last commit (alias: --cached)

git diff --cached                    # Same as --staged, shows differences between staging area and last commit

git diff <commit1> <commit2>         # Show differences between two commits
git diff <commit1>..<commit2>        # Show differences introduced in <commit2> not in <commit1>
git diff <commit1>...<commit2>       # Show differences in the symmetric difference of two commits

git diff --stat                      # Show statistics about differences (e.g., number of lines added/removed)

git diff --no-color                  # Show differences without color (useful for scripts or plain-text environments)
```

---

# Branching and Merging

## Working with Branches
```bash
git branch                          # List local branches # Check on which branch you are working

git branch -a                       # List all branches

git branch -r                       # List remote branches

git branch -m old new               # Rename a branch, but fails if the new branch name already exists

git branch -m old new --force       # Rename a branch, even if the new branch name already exists

git branch -M old new               # Same as git branch -m old new --force

git branch -c old new               # Create a new branch and checkout to it

git branch -d branch_name           # Delete a branch after merging at local
```
- Make sure you checkout to any other branch before deleting the branch.
- Make sure to delete remote branch as well.

## Switching Branches
```bash
git checkout branch_name            # Switch to a branch
git checkout -f branch_name         # Switch to a branch, ignoring any uncommitted changes

# Create and switch to a new_branch, which will be based on your current branch.
git checkout -b new_branch

# Create and switch to a new_branch based on old_branch, regardless of which branch you are currently on.
git checkout -b new_branch old_branch

# Create and switch to a new_branch, based on the current commit 
git checkout -b new_branch HEAD

git checkout --detach               # Detach HEAD from the current branch
git switch -c new_branch            # Alternative to create and switch
git switch -c new_branch old_branch # Alternative to create and switch
```

## Merging and Rebasing
```bash
git merge branch_name               # Merge a branch into the current branch

git merge --no-commit branch_name   # Merge a branch into the current branch, but do not commit

git merge --no-ff branch_name        # Merge a branch into the current branch, even if it is a fast-forward

git merge --squash branch_name       # Merge a branch into the current branch, but squash the changes

git merge --abort                   # Abort a merge

git merge --continue                # Continue a merge after resolving conflicts

git merge origin/main               # Merge a remote branch into the current branch

git rebase branch_name              # Reapply commits on top of another branch
```

---

# Working with Remotes
```bash
# Add a remote repository
# <remote-name>: A short name you want to use for the remote repository (e.g., origin).
git remote add origin <HTTPS/SSH>

# View remote repositories URLs
git remote -v

# Remove a remote repository from your local repository
git remote remove origin

# Rename a remote repository
git remote rename origin new-origin

# Push the current branch (changes) to the remote repository
# Even there was no "branch_name" in github repo. Created & pushed.
# Use -u when you're pushing a branch for the first time and want to make future push/pull commands more convenient.
git push <remote-name> <branch_name>
git push origin main

# Delete the branch from the remote repository
git push origin --delete <branch_name>

# Pull changes
git pull origin branch_name

# Pull changes and merge them into the current branch
# Ensures that your local changes will be applied on top of the changes pulled from the remote branch.
# Defualt behaviour is to merge changes, rebase is off. If you want to rebase, use -r option.
git pull origin branch_name --rebase

# Clone a remote repository, it picks "main" branch only, by default.
git clone <remote-url>

# Clone a remote repository with a specific branch
git clone -b <branch_name> --single-branch <remote-url>
```

---

# Tags
```bash
# Create a lightweight tag
git tag "tag_name" -m "message"

# Create an annotated tag
git tag -a "tag_name" -m "message"

# Create a tag from the current commit
git tag -a "tag_name" -m "message"

# Create a tag from a specific commit
git tag -a "tag_name" -m "message" <commit_hash>

# Create a tag from a specific branch
git tag -a "tag_name" -m "message" <branch_name>

# List all tags
git tag

# Show a tag
git show <tag_name>

# Delete a local tag
git tag -d tag_name

# Push tags to remote
git push origin --tags

# Delete a remote tag
git push origin --delete tag_name
```

---

# Stashing
```bash
git stash                           # Stash uncommitted changes

git stash list                      # List stashed changes

git stash apply                     # Apply the most recent stash

git stash apply <stash_name>        # Apply a specific stash

git stash drop <stash_name>         # Drop a specific stash

git stash drop stash@{index}        # Drop a specific stash

git stash clear                     # Clear all stashed changes
```

# Muhammad Ibtisam