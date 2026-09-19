# Source Inventory

Every item in the four legacy Git files, mapped to where its topic lives in the rebuilt Git tool folder. Force-tracked (the rest of `_sources/` is git-ignored) and excluded from the site, so `scripts/audit-tool.py` (check 9) can run on a fresh checkout.

Status values: `mapped` (topic covered by the target file), `fact` (becomes a Must-Know Facts row in the target), `deferred` (belongs to another tool folder), `dropped` (reason given). Wording from these sources is never copied; only topics are used. Real emails, remote URLs and signatures are scrubbed to example identities. Paths are relative to `delivery/git/`.

---

## Git.md (mixed Git and GitHub concepts)

| Source topic | Status | Target |
|---|---|---|
| Git is a distributed VCS, built for speed | mapped | 00-foundations/what-is-git.md |
| Branch purposes in a team (main, dev, QA, PPD, DR) | fact | 04-team-workflows/branching-strategies.md |
| Pull Request: code review and discussion | deferred | delivery/github/ owns pull requests (scope decision G1) |
| Fetch updates refs only; pull is fetch plus merge | mapped | 03-remotes-and-collaboration/remotes.md; 03-remotes-and-collaboration/pushing-and-pulling.md |
| Recovering deleted files (restore, checkout from a commit, restore .) | mapped | 01-core-workflow/undoing-changes.md; 05-history-and-recovery/reflog-and-recovery.md |
| restore replaces older checkout for file restoration | fact | 01-core-workflow/undoing-changes.md |
| "Feel free to expand further" plus emoji | dropped | Chatbot residue, not content |

---

## gitCheatSheet.md (comprehensive command reference)

| Source topic | Status | Target |
|---|---|---|
| Installation check (which git, git --version) | mapped | 00-foundations/install-and-config.md |
| Config levels (system, global, local); identity; editor; aliases; unset; list; edit | mapped | 00-foundations/install-and-config.md |
| pull.rebase and pull.ff config keys | mapped | 00-foundations/install-and-config.md; reference/config-reference.md |
| git init, git status | mapped | 01-core-workflow/staging-and-committing.md |
| Staging and committing (add, add ., diff --cached, commit, commit --dry-run) | mapped | 01-core-workflow/staging-and-committing.md |
| Undoing changes: restore worktree, unstage, reset --soft/--mixed/--hard, revert, checkout a file from a commit | mapped | 01-core-workflow/undoing-changes.md |
| Cleaning untracked files (clean -n/-f/-fd) | mapped | 01-core-workflow/undoing-changes.md |
| Viewing history (log formats, --oneline, --graph, --stat, filters, -p) | mapped | 01-core-workflow/inspecting-history.md |
| git diff (working vs staged vs commits, A..B vs A...B ranges, --stat) | mapped | 01-core-workflow/inspecting-history.md |
| Branch lifecycle (branch, -a, -r, -m/-M, -c, -d) | mapped | 02-branching-and-merging/branches.md |
| Switching (checkout, checkout -b, --detach, switch -c) | mapped | 02-branching-and-merging/branches.md |
| Merging (merge, --no-commit, --no-ff, --squash, --abort, --continue) | mapped | 02-branching-and-merging/merging.md |
| Rebasing (rebase branch) | mapped | 02-branching-and-merging/rebasing.md |
| Working with remotes (add, -v, remove, rename, push, -u, --delete, pull, pull --rebase, clone, clone -b --single-branch) | mapped | 03-remotes-and-collaboration/remotes.md; 03-remotes-and-collaboration/pushing-and-pulling.md |
| Tags (lightweight, annotated, from a commit or branch, list, show, -d, push --tags, --delete) | mapped | 03-remotes-and-collaboration/tags-and-releases.md |
| Stashing (stash, list, apply, drop, clear) | mapped | 03-remotes-and-collaboration/stashing.md |
| The reference as a whole, plus the cs.fyi external cheatsheet link | mapped | reference/cheatsheet.md; reference/command-index.md |
| Table of Contents block | dropped | Reference pages carry no in-page TOC (writing standard) |
| Signature "Muhammad Ibtisam"; real email abc@gmail.com; real remote URL | dropped | Scrubbed; example identities used in the rebuild |

---

## git-submodules.md (already close to standard, rebuilt in place)

| Source topic | Status | Target |
|---|---|---|
| Why submodules (a pointer, not a copy; single source of truth) | mapped | 07-advanced-tooling/submodules.md |
| When to use and when not to use submodules | mapped | 07-advanced-tooling/submodules.md |
| Internals: .gitmodules (tracked), .git/config (local), the folder as a commit SHA (mode 160000) | mapped | 07-advanced-tooling/submodules.md |
| First-time setup (add, clone --recurse-submodules, update --init --recursive) | mapped | 07-advanced-tooling/submodules.md |
| Updating a submodule (manual cd-and-pull vs update --remote --merge) | mapped | 07-advanced-tooling/submodules.md |
| The "Already up to date" trap | mapped | 07-advanced-tooling/submodules.md |
| Submodule status states (new commits, modified content, untracked content) | mapped | 07-advanced-tooling/submodules.md |
| Quick reference table | mapped | 07-advanced-tooling/submodules.md; reference/cheatsheet.md |
| Real repo URLs (ibtisam-iq/java-monolith-app, platform-engineering-systems) | fact | Rewritten to example remotes in the target |

---

## troubleshooting.md

| Source topic | Status | Target |
|---|---|---|
| Empty file (one byte) | dropped | No content; reference/error-messages.md is built fresh from captured Git errors |

---

## .gitattributes (folder-level sample)

| Source topic | Status | Target |
|---|---|---|
| Corporate .gitattributes sample (EOL, linguist, binary, LFS filters) | fact | reference/dotfiles-reference.md documents .gitattributes format; the stray sample file is not published content |
