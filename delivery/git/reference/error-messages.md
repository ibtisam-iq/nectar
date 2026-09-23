# Error Messages

Real Git error and warning strings, each with the cause and the fix. Search this page for the exact text Git printed. It grows as each module is added; entries are grouped by the area the error belongs to.

---

## Repository and Config

### `fatal: not a git repository (or any of the parent directories): .git`

**Cause:** the command ran outside any repository; no `.git` exists in the current or parent directories.

**Fix:** `cd` into the project, or run `git init` to create a repository here.

### `Author identity unknown` (with `Please tell me who you are`)

**Cause:** `user.name` or `user.email` is unset in every config scope, so Git cannot stamp a committer onto the commit.

**Fix:** set them, for example `git config --global user.email "you@example.com"` and `git config --global user.name "You"`; use `--local` for one repository only.

### `error: key does not contain a section: name`

**Cause:** a `git config` key was given without its section, such as `git config name`.

**Fix:** use the full `section.key` form, for example `git config user.name`.

---

## Staging and Committing

### `nothing to commit, working tree clean`

**Cause:** there are no staged changes; either nothing changed, or edits were never staged.

**Fix:** `git add` the changes (or `git commit -a` for tracked files), then commit.

### A new file is missing from a `git commit -am` commit

**Cause:** `-a` stages modifications and deletions to tracked files only; a new untracked file is left out silently.

**Fix:** `git add <newfile>` explicitly, then commit; `-a` never stages new files.

---

## History and Diffs

### `fatal: ambiguous argument 'HEAD': unknown revision or path not in the working tree`

**Cause:** `HEAD` does not resolve, usually because the repository has no commits yet.

**Fix:** make the first commit; until then there is no `HEAD` to compare against.

### `fatal: ambiguous argument 'HEAD^2': unknown revision or path`

**Cause:** `HEAD^2` was used on a non-merge commit (which has one parent), or the shell consumed the `^`.

**Fix:** use `HEAD^2` only on a merge commit; quote it as `'HEAD^2'` so the shell leaves it alone.

---

## Ignoring and Attributes

### `The following untracked working tree files would be overwritten by checkout`

**Cause:** a locally ignored file is also tracked in an incoming commit, so checkout or merge would clobber the local copy.

**Fix:** move or remove the local file, or untrack it upstream with `git rm --cached`; ignoring a path does not exempt it from a checkout collision.

### `warning: in the working copy of '<file>', LF will be replaced by CRLF the next time Git touches it`

**Cause:** `core.autocrlf=true` or a `.gitattributes` rule is normalising line endings on the next checkout.

**Fix:** it is a warning, not an error; commit a `.gitattributes` with `* text=auto` and run `git add --renormalize .` once to settle endings.

---

## Undoing Changes

### `error: pathspec '<file>' did not match any file(s) known to git`

**Cause:** a `git restore` or `git checkout` named a path that does not exist in the given source, often a typo or a file added later.

**Fix:** confirm the path with `git ls-tree <rev>`; use the exact path Git records.

### `fatal: Cannot do hard reset with paths`

**Cause:** `git reset --hard <commit> -- <path>` was attempted, but `--hard` acts on the whole tree and cannot take a pathspec.

**Fix:** use `git restore --source=<commit> <path>` for a single file, or drop the path to hard-reset the branch.

---

## Branching and Merging

### `error: the branch '<name>' is not fully merged`

**Cause:** `git branch -d` was used on a branch whose commits no other branch reaches, so the delete would lose them.

**Fix:** merge or rebase the work first, or, if it is truly unwanted, delete with `git branch -D <name>`.

### `error: Your local changes to the following files would be overwritten by checkout`

**Cause:** switching branches would overwrite uncommitted working-tree changes that differ between the two branches.

**Fix:** commit or `git stash` the changes first, then switch; or `git restore` them if unwanted.

### `CONFLICT (content): Merge conflict in <file>`

**Cause:** both sides of a merge, rebase, cherry-pick or revert changed the same lines, so Git cannot combine them automatically.

**Fix:** edit the file to the intended result, remove the conflict markers, `git add` it, then continue the operation (`git merge --continue`, `git rebase --continue`, and so on). See [Conflict Resolution](../02-branching-and-merging/conflict-resolution.md).

---

## Related

- [Merge Conflict Resolution](../interview/scenarios/merge-conflict-resolution.md): resolving a conflict end to end
- [Undoing Changes](../01-core-workflow/undoing-changes.md): the safe undo for each situation
- [Conflict Resolution](../02-branching-and-merging/conflict-resolution.md): the anatomy behind the conflict messages
- [Round 3: Troubleshooting](../interview/round-3-troubleshooting.md): the method these errors are worked through with

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
