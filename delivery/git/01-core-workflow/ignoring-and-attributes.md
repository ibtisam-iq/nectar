# Ignoring and Attributes

`.gitignore` keeps generated and secret files out of the repository, and `.gitattributes` tells Git how to treat paths for line endings, diffs and merges. Interviewers ask about the pair because "I added it to gitignore but Git still tracks it" and cross-platform line-ending noise are two problems every team hits.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Ignore a path | A pattern line in `.gitignore` | `git status --ignored` |
| Directory pattern | Trailing slash, `build/`, matches a directory | `git check-ignore -v build/x` |
| Negate | `!pattern` re-includes a previously ignored path | `git check-ignore -v` |
| Which rule matched | `git check-ignore -v <path>` prints file:line:pattern | `git check-ignore -v` |
| Already tracked | `.gitignore` never untracks a committed file | `git status` |
| Untrack, keep on disk | `git rm --cached <path>` | `git status` |
| Global ignore | `core.excludesFile`, for editor and OS files | `git config core.excludesFile` |
| Attributes file | `.gitattributes` sets per-path behaviour | `git check-attr -a <path>` |
| Normalise endings | `* text=auto` stores LF, checks out native | `git check-attr eol <path>` |
| Mark binary | `*.png binary` disables text diff and merge | `git check-attr -a <path>` |
<!-- --8<-- [end:facts] -->

---

## Ignore Rules

`.gitignore` holds one pattern per line. A plain name matches anywhere in the tree, a trailing slash matches a directory, and a leading slash anchors to the `.gitignore`'s own directory.

```bash
git status -s
```

Output:

```text
?? .gitignore
?? app.py
```

With `build/`, `*.log` and `.env` ignored, the untracked list shows only the files that are not ignored. Ignored paths are hidden from `git status` by default, which is the point: noise stays out of the way.

---

## Debugging Ignore Rules

Two commands answer "why is this path (not) ignored". `git status --ignored` lists the ignored paths, and `git check-ignore -v` names the exact rule that matched.

```bash
git status -s --ignored
```

Output:

```text
?? .gitignore
?? app.py
!! .env
!! build/
!! logs/
```

```bash
git check-ignore -v logs/app.log build/out.o .env
```

Output:

```text
.gitignore:3:*.log	logs/app.log
.gitignore:2:build/	build/out.o
.gitignore:4:.env	.env
```

The `file:line:pattern` prefix pinpoints which line did the ignoring, which is how you debug a surprising ignore in a project with several nested `.gitignore` files.

---

## Ignoring an Already-Tracked File

`.gitignore` only affects untracked paths. A file that was committed before it was ignored stays tracked, and edits to it still show up.

```bash
git status -s
```

Output:

```text
 M .gitignore
```

The newly ignored `config.env` does not appear as ignored, because Git is still tracking it. Removing it from the index while leaving it on disk is what actually stops tracking it.

```bash
git rm --cached config.env
git status -s
```

Output:

```text
rm 'config.env'
 M .gitignore
D  config.env
```

The `D ` stages the deletion from history; the file remains in the working directory. After committing, the path is untracked and the `.gitignore` rule takes effect.

!!! warning "A committed secret stays in history after gitignore and rm --cached"
    `git rm --cached` stops future tracking but does not remove the file from past commits. A leaked credential must be rotated and, if the history must be cleaned, removed with `git filter-repo`, which module 05 covers.

---

## Attributes

`.gitattributes` maps path patterns to attributes that change how Git handles those files. `git check-attr -a` prints every attribute in effect for a path.

```bash
git check-attr -a run.sh
```

Output:

```text
run.sh: text: set
run.sh: eol: lf
```

```bash
git check-attr -a logo.png
```

Output:

```text
logo.png: binary: set
logo.png: diff: unset
logo.png: merge: unset
logo.png: text: unset
```

`binary` is a shorthand that unsets `text`, `diff` and `merge`, so Git never tries to normalise line endings, show a text diff, or three-way merge the file. This is what stops a merge from corrupting an image or a compiled artifact.

---

## Line Endings Across Platforms

`* text=auto` in `.gitattributes` tells Git to store text with LF in the repository and check it out with the platform's native ending, which keeps a mixed-OS team from committing line-ending churn. The `core.autocrlf` config does the same job per-user when there is no attributes file.

=== "macOS / Linux"

    ```bash
    git config --global core.autocrlf input
    ```

=== "Windows"

    ```bash
    git config --global core.autocrlf true
    ```

`input` converts CRLF to LF on commit but does not convert back on checkout, which suits Unix systems that use LF natively. `true` also converts LF back to CRLF on checkout for Windows editors. A committed `.gitattributes` with `* text=auto` is preferred over `core.autocrlf` because it travels with the repository and applies to everyone.

!!! note "Attributes are committed; autocrlf is per-machine"
    `.gitattributes` is part of the repository, so line-ending policy is shared and consistent for every clone. `core.autocrlf` lives in each developer's config, so it drifts between machines and is the weaker of the two controls.

---

## Common Errors

### `The following untracked working tree files would be overwritten` for an ignored file

**Cause:** a file is ignored locally but is also tracked in an incoming commit, so a checkout or merge would clobber the local copy.

**Fix:** move or remove the local file, or untrack it upstream with `git rm --cached`; ignoring a path does not exempt it from checkout collisions.

### `warning: in the working copy of 'file', LF will be replaced by CRLF`

**Cause:** `core.autocrlf=true` or an attribute is converting line endings on the next checkout, and Git is reporting the normalisation.

**Fix:** it is a warning, not an error; commit a `.gitattributes` with `* text=auto` and run `git add --renormalize .` once to settle endings across the repository.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: You added a file to .gitignore but Git still tracks it. Why?"
    **Say first:** `.gitignore` only affects untracked paths, and this file was already committed, so the ignore rule does not apply to it.

    **Proof:** `git status` still shows edits to the file; `git rm --cached <path>` untracks it while keeping it on disk.

    **Follow-up:** Does `git rm --cached` remove the file from earlier commits too?

??? question "L1: What is the difference between .gitignore and .gitattributes?"
    **Say first:** `.gitignore` decides which untracked paths Git ignores; `.gitattributes` decides how Git treats paths it does track, such as line endings, diff and merge behaviour.

    **Proof:** `git check-ignore -v` explains an ignore; `git check-attr -a` shows the attributes on a path.

    **Follow-up:** How do you make Git treat a file as binary so it is never line-ending-normalised or merged?
<!-- --8<-- [end:l1] -->

??? question "L2: Find out which rule is ignoring a specific file."
    **Say first:** `git check-ignore -v <path>` prints the file, line and pattern that matched.

    **Proof:**

    ```bash
    git check-ignore -v build/out.o
    ```

    **Follow-up:** How do you re-include one file inside an ignored directory?

??? question "L2: Stop tracking a config file that should have been ignored, without deleting it locally."
    **Say first:** `git rm --cached <file>`, add it to `.gitignore`, then commit.

    **Proof:** `git status` shows `D ` for the staged untrack while the file stays in the working directory.

    **Follow-up:** What must you also do if the file contained a real secret?

??? question "L3: A cross-platform team keeps committing whole-file line-ending changes. How do you stop it?"
    **Say first:** commit a `.gitattributes` with `* text=auto` so Git stores LF and checks out native endings for everyone, then renormalise once.

    **Proof:** `git add --renormalize .` and one commit settles endings; `git check-attr eol <file>` confirms the policy.

    **Follow-up:** Why is `.gitattributes` preferred over each developer setting `core.autocrlf`?

??? question "L4: What does the binary attribute actually turn off, and why does that matter for merges?"
    **Say first:** `binary` unsets `text`, `diff` and `merge`, so Git skips line-ending normalisation, shows no text diff, and refuses a line-based three-way merge for the path.

    **Proof:** `git check-attr -a logo.png` shows `text`, `diff` and `merge` all unset under `binary: set`.

    **Don't say:** "Binary only hides the diff." It also prevents a merge from corrupting the file.

---

## Related

- [Staging and Committing](staging-and-committing.md): what tracking a file means
- [Undoing Changes](undoing-changes.md): untracking and cleaning files with `rm --cached` and `clean`
- [Error Messages](../reference/error-messages.md): the ignore and line-ending warnings, with fixes

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
