# Text Editors

`vi` is present on almost every Linux server, rescue shell and container base image, so a small set of `vim` keys is a baseline skill. `nano` is friendlier and is the default editor on Ubuntu.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `vi` on RHEL | `vim-minimal`; full `vim` is `vim-enhanced` | `rpm -qf /usr/bin/vi` |
| `vi` on Ubuntu | Alternatives link to `vim.basic` or `vim.tiny` | `readlink -f /usr/bin/vi` |
| Default editor on Ubuntu | `nano`, through the `editor` alternative | `update-alternatives --display editor` |
| Editor used by tools | `$VISUAL`, then `$EDITOR`, then a built-in default | `echo $EDITOR` |
| Edit a root file safely | `sudoedit <file>` (`sudo -e`); runs the editor as the user | `sudoedit /etc/hosts` |
| Learn vim | `vimtutor` (30 minutes) | `vimtutor` |
<!-- --8<-- [end:facts] -->

---

## Vim Survival Keys

`vim` is modal: Normal mode for commands, Insert mode for typing, Command-line mode after `:`. `Esc` always returns to Normal mode.

| Keys | Action |
|---|---|
| `i`, `a`, `o` | Insert before cursor, after cursor, on a new line below |
| `Esc` | Back to Normal mode |
| `:w`, `:q`, `:wq` or `:x`, `:q!` | Save, quit, save and quit, quit without saving |
| `h j k l`, `w`, `b` | Move by character or word |
| `0`, `$`, `gg`, `G`, `:42` | Line start, line end, file start, file end, line 42 |
| `dd`, `yy`, `p`, `P` | Delete (cut) line, copy line, paste after, paste before |
| `x`, `u`, `Ctrl+R` | Delete character, undo, redo |
| `/text`, `n`, `N` | Search forward, next, previous |
| `:%s/old/new/g` | Replace in the whole file |
| `:set number`, `:set list` | Line numbers; show tabs and line ends |
| `v`, `V`, `Ctrl+V` | Select characters, lines, a block |

---

## Non-Interactive Edits

`vim` runs in Ex mode for scripted edits, which is useful where `sed -i` behaves differently between GNU and BSD:

```bash
printf 'listen 80\nserver_name old.example.com\n' > /tmp/site.conf
vim -Es -c '%s/old/new/g' -c 'wq' /tmp/site.conf
cat /tmp/site.conf
```

Output:

```text
listen 80
server_name new.example.com
```

---

## Choosing the Editor

On Ubuntu:

```bash
update-alternatives --display editor | head -3
readlink -f /usr/bin/vi
```

Output:

```text
editor - auto mode
  link best version is /bin/nano
  link currently points to /bin/nano
/usr/bin/vim.basic
```

`sudo update-alternatives --config editor` changes the default for `crontab -e` and `visudo`. On RHEL, `vi` comes from `vim-minimal` and `vim` from `vim-enhanced`.

!!! tip "EDITOR and VISUAL choose the editor for other tools"
    Setting `export EDITOR=vim VISUAL=vim` in `~/.bashrc` makes `crontab -e`, `git commit`, `kubectl edit` and `systemctl edit` use `vim`.

!!! warning "sudo vim gives the editor root privileges"
    From `sudo vim`, `:!sh` opens a root shell, which bypasses a sudoers rule meant to allow editing only. `sudoedit` copies the file, runs the editor as the user, and writes the result back as root.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How do you save and exit vim, and exit without saving?"
    **Say first:** press `Esc`, then `:wq` to save and quit, or `:q!` to quit and discard changes.

    **Proof:** `:x` also saves and quits, writing only if the file changed.

    **Follow-up:** What does `E37: No write since last change` mean?
<!-- --8<-- [end:l1] -->

??? question "L2: Replace every occurrence of a hostname in a file using vim."
    **Say first:** substitute across the whole file from Command-line mode.

    **Proof:** `:%s/old.example.com/new.example.com/g`

    **Follow-up:** How do you confirm each replacement? (Add the `c` flag.)

??? question "L2: Make crontab -e open vim instead of nano."
    **Say first:** set `VISUAL` or `EDITOR`, or change the system default.

    **Proof:** `export VISUAL=vim` in `~/.bashrc`, or `sudo update-alternatives --config editor` on Ubuntu.

    **Follow-up:** Which variable wins when both are set?

??? question "L2: Jump to line 120 of a config file that an error message mentions."
    **Say first:** open it at that line.

    **Proof:** `vim +120 /etc/nginx/nginx.conf`, or `:120` inside `vim`.

    **Follow-up:** How do you show line numbers permanently? (`set number` in `~/.vimrc`.)

??? question "L3: A user allowed to edit one file through sudo gained a root shell."
    **Say first:** the rule allowed `sudo vim <file>`, and `vim` can run shell commands.

    **Proof:** `sudo -l` shows `(root) /usr/bin/vim /etc/app.conf`; inside `vim`, `:!sh` runs as root.

    **Follow-up:** How should the rule be written? (`sudoedit /etc/app.conf`.)

??? question "L3: YAML pasted into vim fails to parse even though it looked correct."
    **Say first:** check indentation changes made by auto-indent, and tabs.

    **Proof:** `:set list` shows `^I` tabs and shifted indentation; `:set paste` before pasting stops auto-indent.

    **Follow-up:** Which tool validates the file before applying it? (`yamllint`, `kubectl apply --dry-run=client`.)

---

## Related

- [Sudo and Su](../04-users-and-access/sudo-and-su.md): `sudoedit` and editor escapes
- [Getting Help](getting-help.md): `man` uses the same search keys as `vim`

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
