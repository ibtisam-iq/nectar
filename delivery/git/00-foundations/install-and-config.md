# Install and Config

Git reads settings from three files layered by scope, and the first commit needs only an identity set at the global level. Interviewers ask about config to check that a candidate knows the system, global and local order and can set a per-directory identity, because a wrong committer email is a common and annoying mistake.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| System scope | `/etc/gitconfig`, all users; `git config --system` | `git config --show-scope --list` |
| Global scope | `~/.gitconfig`, one user; `git config --global` | `git config --global --list` |
| Local scope | `.git/config`, one repository; `git config --local` | `git config --local --list` |
| Precedence | Local overrides global overrides system | `git config --show-origin <key>` |
| Identity | `user.name` and `user.email`, stamped into every commit | `git config user.email` |
| Default branch | `init.defaultBranch`, `main` on current Git | `git config init.defaultBranch` |
| Editor | `core.editor`, for commit messages and rebases | `git config core.editor` |
| Alias | `git config --global alias.<name> "<command>"` | `git config --get-regexp alias` |
| Per-directory | `includeIf "gitdir:~/work/"` includes another config file | `git config --show-origin user.email` |
| Read one value | `git config --get <key>` | the value |
<!-- --8<-- [end:facts] -->

---

## Installing Git

Git ships as a single package on every platform. Confirm the version after installing, because a few features named in these notes (`git switch`, `git restore`, SHA-256 repositories) depend on a recent build.

=== "macOS / Linux"

    ```bash
    brew install git          # macOS with Homebrew
    sudo apt install git      # Debian and Ubuntu
    sudo dnf install git      # RHEL, Rocky and Fedora
    git --version
    ```

=== "Windows"

    ```bash
    winget install --id Git.Git
    git --version
    ```

Output:

```text
git version 2.50.1 (Apple Git-155)
```

---

## The Three Config Scopes

Settings live in three files, and a lookup returns the value from the most specific scope that has it. System applies to every user, global to one user, and local to a single repository.

```bash
git config --global user.name "Amina Yusuf"
git config --global user.email "amina@example.com"
git config --global init.defaultBranch main
git config --global core.editor "vim"
git config --global pull.rebase true
```

None of those print output; each writes a line into `~/.gitconfig`. Listing the file with the origin of each value confirms where a setting came from.

```bash
git config --list --show-origin --global
```

Output:

```text
file:/home/amina/.gitconfig	user.name=Amina Yusuf
file:/home/amina/.gitconfig	user.email=amina@example.com
file:/home/amina/.gitconfig	init.defaultbranch=main
file:/home/amina/.gitconfig	core.editor=vim
file:/home/amina/.gitconfig	pull.rebase=true
```

Keys are stored lowercased in the section (`init.defaultbranch`), which is why config keys are case-insensitive in the section and name but case-sensitive in the value.

!!! warning "System scope needs root, and a local override hides a global identity"
    `git config --system` writes `/etc/gitconfig` and needs `sudo`, so most user settings go in global. A `user.email` set locally in one repository silently overrides the global one, which is the usual reason commits on a single project carry the wrong address.

---

## Precedence and Reading a Value

A local setting in `.git/config` overrides the same key set globally, so a repository can carry a different committer email than the user default.

```bash
git config --local user.email "amina@work.example.com"
git config user.email
```

Output:

```text
amina@work.example.com
```

`git config --show-scope --get-all <key>` shows every scope that defines a key, which is the fastest way to explain a surprising value.

```bash
git config --show-scope --get-all user.email
```

Output:

```text
global	amina@example.com
local	amina@work.example.com
```

The lookup returns the local value because local is more specific than global. `git config --get <key>` reads the single effective value for scripts.

---

## Per-Directory Identity with includeIf

`includeIf` pulls in another config file only when the repository path matches, which sets a work email for everything under `~/work/` without editing each repository.

```bash
cat >> ~/.gitconfig <<'EOF'
[includeIf "gitdir:~/work/"]
	path = ~/work/.gitconfig-work
EOF
git config --get includeIf.gitdir:~/work/.path
```

Output:

```text
~/work/.gitconfig-work
```

The included file holds the overriding `user.email`. The `gitdir:` pattern must end with a slash to match a directory tree, and the include is evaluated by the path of the repository Git is operating in.

!!! tip "Aliases shorten a long command to a single word"
    `git config --global alias.lg "log --oneline --graph --decorate"` makes `git lg` run the full command. An alias starting with `!` runs a shell command instead of a Git subcommand, which is how aliases call external scripts.

---

## Common Errors

### `Author identity unknown` and `Please tell me who you are`

**Cause:** `user.name` or `user.email` is unset in every scope, so Git cannot stamp a committer onto the commit.

**Fix:** set them globally with `git config --global user.email "you@example.com"` (and `user.name`), or locally for one repository.

### `error: key does not contain a section: name`

**Cause:** a `git config` key was given without a section, such as `git config name` instead of `git config user.name`.

**Fix:** use the full `section.key` form, for example `git config user.name`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are the three config scopes and their order of precedence?"
    **Say first:** system (`/etc/gitconfig`, all users), global (`~/.gitconfig`, one user) and local (`.git/config`, one repository); local overrides global, which overrides system.

    **Proof:** `git config --show-origin user.email` names the file the effective value came from.

    **Follow-up:** How do you give one repository a different committer email from your default?

??? question "L1: Where does Git get the name and email it puts on a commit?"
    **Say first:** from `user.name` and `user.email`, resolved through the scope precedence, with the local repository value winning if set.

    **Proof:** `git config user.email` prints the effective value; `git config --show-scope --get-all user.email` shows every scope that defines it.

    **Follow-up:** What does Git do if neither is set anywhere?
<!-- --8<-- [end:l1] -->

??? question "L2: Set your identity globally but override the email for all repositories under ~/work."
    **Say first:** set the global identity, then add an `includeIf "gitdir:~/work/"` block pointing at a work config file that redefines `user.email`.

    **Proof:**

    ```bash
    git config --global user.email "amina@example.com"
    git config --show-origin user.email   # from ~/work run inside a work repo
    ```

    **Follow-up:** Why must the `gitdir:` pattern end with a slash?

??? question "L2: Create an alias so `git lg` shows a decorated one-line graph."
    **Say first:** `git config --global alias.lg "log --oneline --graph --decorate"`.

    **Proof:** `git config --get-regexp alias` lists the alias; `git lg` runs the expansion.

    **Follow-up:** How would you make an alias that runs a shell command rather than a Git subcommand?

??? question "L3: A colleague's commits show the wrong email on one project only. Where do you look?"
    **Say first:** a local override in that repository's `.git/config` is winning over their global identity.

    **Proof:** `git config --show-scope --get-all user.email` lists both scopes; the `local` line is the culprit.

    **Follow-up:** How would you fix the commits that already carry the wrong email?

??? question "L4: How does Git decide which config file a value comes from?"
    **Say first:** it reads system, then global (with any `includeIf` files spliced in where they match), then local, later files overriding earlier keys, so the last write to a key in precedence order wins.

    **Proof:** `git config --list --show-origin` prints every value with its source file in read order.

    **Don't say:** "Local and global are merged and the alphabetically first wins."

---

## Related

- [What Is Git](what-is-git.md): why every commit carries a committer identity
- [The Three Trees](the-three-trees.md): the areas the first commit moves a change through
- [Staging and Committing](../01-core-workflow/staging-and-committing.md): the identity every commit records, in use
- [Error Messages](../reference/error-messages.md): the identity and config errors, with fixes

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
