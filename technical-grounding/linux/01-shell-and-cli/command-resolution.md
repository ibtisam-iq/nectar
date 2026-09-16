# Command Resolution

Before running a word as a command, bash checks aliases, keywords, functions, builtins, its hash table and finally each directory in `PATH`. Knowing that order explains why `which` can disagree with what runs, and why a moved binary can still "not exist".

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Lookup order | Alias, keyword, function, builtin, hash table, `PATH` | `type -a <name>` |
| `type` vs `which` | `type` is the shell's own answer; `which` searches `PATH` only | `type echo; which echo` |
| Portable lookup in scripts | `command -v <name>` | `command -v echo` |
| Bypass an alias | `\name` or `command name` | `\ls` |
| Skip aliases and functions | `command name` (builtins still win); a full path always runs the file | `command ls` |
| Hash table | Remembers the path of each external command already run | `hash -t <name>` |
| Clear the hash | `hash -r`; assigning `PATH` also clears it | `hash` |
| Not found | Exit code 127 | `nosuchcmd; echo $?` |
| Found but not executable | Exit code 126 | `echo $?` |
| Current directory | Not in `PATH`; run local files as `./name` | `echo $PATH` |
<!-- --8<-- [end:facts] -->

---

## What a Name Resolves To

Commands below ran in an interactive bash on Ubuntu, where `ls`, `ll` and `grep` are aliases from `~/.bashrc`.

```bash
type -a ls
type -a echo
type -a if
type cd
alias ll
type ll
type -t ls if cd ll grep
```

Output:

```text
ls is aliased to `ls --color=auto'
ls is /usr/bin/ls
ls is /bin/ls
echo is a shell builtin
echo is /usr/bin/echo
echo is /bin/echo
if is a shell keyword
cd is a shell builtin
alias ll='ls -alF'
ll is aliased to `ls -alF'
alias
keyword
builtin
alias
alias
```

`ls` appears twice because `/bin` is a symlink to `/usr/bin` and both are in `PATH`.

| Kind | Example | Defined in |
|---|---|---|
| Alias | `ll`, `ls --color=auto` | `~/.bashrc`, `/etc/profile.d/` |
| Keyword | `if`, `for`, `[[`, `time` | Shell grammar |
| Function | `greet() { ...; }` | Shell startup files, scripts |
| Builtin | `cd`, `echo`, `export`, `read` | Inside bash |
| External | `/usr/bin/ls` | Files in `PATH` |

---

## Precedence in Practice

An alias is expanded before the shell looks for functions, so it wins; a backslash disables alias expansion for one word.

```bash
greet() { echo "function wins"; }
alias greet='echo alias wins'
greet
\greet
unalias greet
greet
```

Output:

```text
alias wins
function wins
function wins
```

`which` does not know about builtins, so it reports a file that never runs:

```bash
which echo
type echo
command -v echo
```

Output:

```text
/usr/bin/echo
echo is a shell builtin
echo
```

Builtins exist because some commands must change the shell itself (`cd`, `export`, `exit`), and others are faster without a `fork` (`echo`, `printf`, `test`). `builtin <name>` forces the builtin; `enable -n <name>` disables it for the session.

!!! tip "Use command -v in scripts"
    `command -v kubectl >/dev/null || { echo "kubectl missing"; exit 1; }` is POSIX, works for builtins and functions, and needs no extra package. `which` is a separate program and is missing from some minimal images.

---

## The Hash Table

After the first run, bash remembers where an external command lives and stops searching `PATH`. A new binary earlier in `PATH` is ignored until the table is cleared.

```bash
mkdir -p ~/bin-a ~/bin-b
PATH="$HOME/bin-a:$HOME/bin-b:$PATH"
printf '#!/bin/sh\necho from bin-b\n' > ~/bin-b/tool
chmod +x ~/bin-b/tool
tool
hash -t tool
printf '#!/bin/sh\necho from bin-a\n' > ~/bin-a/tool
chmod +x ~/bin-a/tool
tool
hash -r
tool
```

Output:

```text
from bin-b
/home/laborant/bin-b/tool
from bin-b
from bin-a
```

When a hashed binary moves, bash still tries the old path:

```bash
printf '#!/bin/sh\necho from bin-b\n' > ~/bin-b/app
chmod +x ~/bin-b/app
app
mv ~/bin-b/app ~/bin-a/app
app
echo "rc=$?"
hash -d app
app
```

Output:

```text
from bin-b
bash: /home/laborant/bin-b/app: No such file or directory
rc=127
from bin-b
```

The last line comes from the moved file (its text still says `bin-b`), now found in `bin-a`.

!!! warning "A reinstalled tool can seem to vanish"
    Upgrading a tool that moves from `/usr/local/bin` to `/usr/bin` (or the reverse) produces `No such file or directory` in shells that ran it before. `hash -r` or a new shell fixes it; the package is fine.

---

## Common Errors

```bash
toool
echo "rc=$?"
./tool
echo "rc=$?"
cp ~/bin-a/tool ~/tool.sh; chmod -x ~/tool.sh
~/tool.sh
echo "rc=$?"
```

Output:

```text
bash: toool: command not found
rc=127
bash: ./tool: No such file or directory
rc=127
bash: /home/laborant/tool.sh: Permission denied
rc=126
```

### `bash: toool: command not found`

**Cause:** no alias, function, builtin or file in `PATH` has that name.

**Fix:** check spelling, `echo $PATH`, and whether the package is installed (`dnf provides '*/toool'`, `apt-file search toool`).

### `bash: ./tool: No such file or directory`

**Cause:** the file is not in the current directory (`PATH` is not searched for names containing `/`).

**Fix:** `ls -l ./tool`, or run it by name if it is in `PATH`.

### `bash: line 1: ./crlf.sh: cannot execute: required file not found`

**Cause:** the file exists, but its interpreter does not. Bash 5.2 prints this when the shebang points to a missing program, most often `/bin/bash\r` from Windows line endings, or when an ELF binary names a missing loader.

**Fix:** `head -1 ./crlf.sh | cat -A` shows `#!/bin/bash^M$`; remove the carriage returns with `sed -i 's/\r$//' ./crlf.sh`. For binaries, `file ./binary` names the loader.

### `bash: /home/laborant/tool.sh: Permission denied`

**Cause:** the file lacks the execute bit, or its filesystem is mounted `noexec`.

**Fix:** `chmod +x`, or run it through the interpreter: `bash ~/tool.sh`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: In what order does bash look up a command name?"
    **Say first:** alias, keyword, function, builtin, then the hash table and `PATH`.

    **Proof:** `type -a echo` lists the builtin before the files.

    **Follow-up:** Why can `which` give the wrong answer?

??? question "L1: Why is cd a builtin and not a program?"
    **Say first:** a child process cannot change its parent's working directory, so `cd` must run inside the shell.

    **Proof:** `type cd`; `/usr/bin/cd /tmp` (where it exists) leaves the shell's directory unchanged.

    **Follow-up:** Which other commands must be builtins for the same reason?
<!-- --8<-- [end:l1] -->

??? question "L2: A script needs to fail early if docker is not installed. Write the check."
    **Say first:** use `command -v`, which works in every POSIX shell.

    **Proof:**

    ```bash
    command -v docker >/dev/null 2>&1 || { echo "docker not found" >&2; exit 1; }
    ```

    **Follow-up:** Why not `which docker`?

??? question "L2: Run the real ls, ignoring an alias called ls."
    **Say first:** escape the alias or use `command`.

    **Proof:** `\ls` or `command ls`

    **Follow-up:** How do you see what the alias expands to? (`type ls` or `alias ls`.)

??? question "L3: After upgrading a tool, the shell says No such file or directory, but which finds it."
    **Say first:** the shell hashed the old location.

    **Proof:** `hash -t <tool>` shows the old path; `type -a <tool>` shows the new one.

    **Follow-up:** Fix it without logging out. (`hash -r`.)

??? question "L3: A command runs a different version in cron than in an SSH session."
    **Say first:** compare `PATH` and aliases between the two environments.

    **Proof:** add `echo "$PATH"; command -v <tool>` to the cron job; cron's default `PATH` is `/usr/bin:/bin`, and it reads no aliases.

    **Follow-up:** How do you make the job independent of `PATH`?

??? question "L3: A file exists and has the execute bit, but running it reports that a required file is not found."
    **Say first:** the missing file is the interpreter, not the script.

    **Proof:** `strace -e trace=execve ./crlf.sh` shows `execve` failing with `ENOENT`; `file crlf.sh` reports `with CRLF line terminators`; `head -1 crlf.sh | cat -A` shows `#!/bin/bash^M$`.

    **Follow-up:** How do you fix the line endings? (`sed -i 's/\r$//' script` or `dos2unix`.)

??? question "L4: What does the kernel do when execve gets a text file?"
    **Say first:** it reads the first bytes; `#!` makes it run the named interpreter with the script path as an argument, and an ELF header makes it load the binary and its loader.

    **Proof:** `strace -e trace=execve ./script.sh` shows one `execve`; the interpreter appears in `ps` as `/bin/bash ./script.sh`.

    **Don't say:** "The shell reads the shebang."

---

## Related

- [Shell Basics](shell-basics.md): how the shell reads a line
- [Variables and Environment](variables-and-environment.md): `PATH` and startup files
- [Exit Codes and Chaining](exit-codes-and-chaining.md): 126 and 127

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
