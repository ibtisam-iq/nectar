# Config Reference

The Git configuration keys worth knowing, with what each does, the level it usually belongs at, and its default. Config is read system, then global, then local, with the last winning; set most of these at `--global`. Read any effective value with `git config <key>`, and see where it came from with `git config --show-origin <key>`.

---

## Identity and Basics

| Key | Purpose | Usual level | Default |
|---|---|---|---|
| `user.name` | Name recorded on commits | global | none (must set) |
| `user.email` | Email recorded on commits | global | none (must set) |
| `init.defaultBranch` | Branch name for a new repo | global | `master` |
| `core.editor` | Editor for messages and interactive rebase | global | `$EDITOR` or `vi` |
| `core.pager` | Pager for `log`, `diff` and similar | global | `less` |

---

## Line Endings and Files

| Key | Purpose | Usual level | Default |
|---|---|---|---|
| `core.autocrlf` | Convert line endings on checkout/commit | global | `false` (`input` on macOS/Linux, `true` on Windows are common) |
| `core.hooksPath` | Directory to load hooks from | local | `.git/hooks` |
| `core.excludesFile` | Path to a global ignore file | global | none |

---

## Fetch, Pull and Push

| Key | Purpose | Usual level | Default |
|---|---|---|---|
| `pull.rebase` | `pull` rebases instead of merging | global | `false` |
| `pull.ff` | Allow only fast-forward pulls (`only`) | global | not set |
| `push.default` | What a bare `push` sends | global | `simple` |
| `push.autoSetupRemote` | First push sets upstream automatically | global | `false` |
| `fetch.prune` | Delete remote-tracking refs that vanished | global | `false` |
| `submodule.recurse` | Commands recurse into submodules | global | `false` |

---

## Merge, Rebase and Conflicts

| Key | Purpose | Usual level | Default |
|---|---|---|---|
| `merge.conflictStyle` | `diff3`/`zdiff3` add the base to conflict markers | global | `merge` |
| `rerere.enabled` | Record and replay conflict resolutions | global | `false` |
| `rebase.autosquash` | `rebase -i` orders `fixup!`/`squash!` commits | global | `false` |
| `rebase.autostash` | Stash and restore around a rebase | global | `false` |

---

## Signing

| Key | Purpose | Usual level | Default |
|---|---|---|---|
| `commit.gpgsign` | Sign every commit | global | `false` |
| `tag.gpgSign` | Sign every annotated tag | global | `false` |
| `gpg.format` | `openpgp`, `ssh` or `x509` signatures | global | `openpgp` |
| `user.signingkey` | Key (or SSH public key path) to sign with | global | none |
| `gpg.ssh.allowedSignersFile` | Trusted keys for verifying SSH signatures | global | none |

---

## Credentials and Large Repos

| Key | Purpose | Usual level | Default |
|---|---|---|---|
| `credential.helper` | Store or cache HTTPS tokens | global | none (`osxkeychain`, `libsecret`, `manager`) |
| `maintenance.strategy` | Background upkeep schedule (`incremental`) | global | none |
| `uploadpack.allowFilter` | Server-side: permit partial clones | local (server) | `false` |

---

## Aliases and Conditional Includes

Aliases add short names for commands, and `includeIf` loads a different config by directory (for example a work identity under `~/work/`).

```ini
[alias]
	lg = log --oneline --graph --all
	unstage = restore --staged
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work
```

The `includeIf` block pulls in `~/.gitconfig-work` (a different `user.email`, say) only for repos under `~/work/`, keeping work and personal identities apart. Aliases and includes are set in the global config.

---

## Related

- [Install and Config](../00-foundations/install-and-config.md): config levels and how they layer
- [Cheatsheet](cheatsheet.md): the commands that set these keys
- [Dotfiles Reference](dotfiles-reference.md): the files these keys live in and reference
- [Credentials and Signing](../07-advanced-tooling/credentials-and-signing.md): the signing and credential keys in use
