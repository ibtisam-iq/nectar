# Dotfiles Reference

The four Git dotfiles and their formats: `.gitignore` and `.gitattributes` that live in the repository, `.gitconfig` for settings, and `.gitmodules` that records submodules. Each entry shows the syntax and the rules that trip people up.

---

## .gitignore

Lists path patterns Git should not track. It is committed, so the whole team shares it. Patterns match relative to the file's location; a global ignore file (`core.excludesFile`) covers editor and OS cruft across all repos.

```gitignore
# a comment
*.log               # ignore by extension
build/              # a trailing slash matches directories only
/dist               # a leading slash anchors to the repo root
!keep.log           # ! re-includes a file an earlier pattern excluded
docs/**/tmp         # ** spans directories
```

The order matters: a later `!` negation re-includes a match, but it cannot re-include a file inside an already-ignored directory. Only untracked files are affected; a file already tracked is not ignored until `git rm --cached` removes it from the index.

!!! warning "Adding a file to .gitignore does not untrack it"
    `.gitignore` only stops Git from tracking files it does not already track. A file committed before the rule stays tracked; run `git rm --cached <file>` and commit to stop tracking it, then the ignore rule applies.

---

## .gitattributes

Sets per-path behaviour: line-ending normalization, diff and merge drivers, linguist hints on hosted platforms, and LFS filters. It is committed so behaviour is consistent across machines.

```gitattributes
* text=auto                 # normalize line endings automatically
*.sh text eol=lf            # force LF for shell scripts
*.bat text eol=crlf         # force CRLF for Windows batch files
*.png binary                # never diff or line-ending-convert binaries
*.md linguist-documentation # host hint: mark as docs, not code
*.psd filter=lfs diff=lfs merge=lfs -text   # store via Git LFS
```

`text=auto` lets Git decide which files are text and normalize them to LF in the repository. The `binary` macro is shorthand for `-text -diff`, which stops both line-ending conversion and textual diffs.

---

## .gitconfig

The settings file, in INI format with `[section]` headers. It exists at three levels: system (`/etc/gitconfig`), global (`~/.gitconfig`), and local (`.git/config`), read in that order with the last winning.

```ini
[user]
	name = Amina Yusuf
	email = amina@example.com
[init]
	defaultBranch = main
[pull]
	rebase = true
[alias]
	lg = log --oneline --graph --all
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work
```

The `[includeIf ...]` block loads another config file only for repositories under a directory, which is how one machine keeps separate work and personal identities. The full key list is in [Config Reference](config-reference.md).

---

## .gitmodules

Maps each submodule's path to its remote URL. It is committed, so every clone knows where to fetch the embedded repositories.

```ini
[submodule "vendor/lib"]
	path = vendor/lib
	url = ../lib.git
	branch = main
```

The `branch` line is optional and only affects `git submodule update --remote`. This file is tracked; the resolved URL is also copied into local `.git/config` on init, which is per-clone and not shared.

!!! danger "Never add .gitmodules to .gitignore"
    `.gitmodules` is what maps a submodule path to its URL. If it is ignored or deleted, Git loses the mapping and the submodule breaks for everyone who clones the repo, with `no submodule mapping found`. Keep it tracked and commit changes to it.

---

## Related

- [Ignoring and Attributes](../01-core-workflow/ignoring-and-attributes.md): `.gitignore` and `.gitattributes` in depth
- [Config Reference](config-reference.md): every key that goes in `.gitconfig`
- [Submodules](../07-advanced-tooling/submodules.md): what `.gitmodules` drives
- [Install and Config](../00-foundations/install-and-config.md): the three config levels
