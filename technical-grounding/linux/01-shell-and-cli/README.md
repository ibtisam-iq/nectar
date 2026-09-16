# Shell and CLI

How bash reads, expands and runs a command line, where its environment comes from, and how commands report success and failure.

---

## Revision Card

| Fact | Value |
|---|---|
| `/bin/sh` | `bash` on RHEL, `dash` on Ubuntu |
| Command lookup | Alias, keyword, function, builtin, hash table, `PATH` |
| Exported variable | Copied to children at `exec`; children cannot change the parent |
| Login shell | Reads `/etc/profile` and `~/.bash_profile` or `~/.profile` |
| Non-interactive shell | Reads no startup files (scripts, cron, systemd) |
| `sudo` environment | Reset; `PATH` comes from `secure_path` |
| Quotes | Single: literal; double: expand, but no splitting or globbing |
| Globs | Expanded by the shell; unmatched globs stay literal |
| Streams | 0 stdin, 1 stdout, 2 stderr; pipes carry stdout only |
| Redirection order | `> f 2>&1` captures both; `2>&1 > f` does not |
| Pipeline status | Last command, unless `set -o pipefail` |
| Exit codes | 0 ok, 1 error, 2 misuse, 126 not executable, 127 not found, 128+N signal |
| Common signals as codes | 130 INT, 137 KILL, 141 PIPE, 143 TERM |
| Locale for scripts | `LC_ALL=C` for stable sorting and parsing |

| Task | Command |
|---|---|
| What does a name run | `type -a <name>` |
| Portable existence check | `command -v <name>` |
| Forget cached command paths | `hash -r` |
| Trace a command or script | `set -x`, `bash -x script.sh` |
| Syntax check a script | `bash -n script.sh` |
| Show a process's environment | `tr '\0' '\n' < /proc/<pid>/environ` |
| Write a root-owned file | `echo text` into `sudo tee <file>` |
| Search man pages | `man -k <keyword>`, `apropos` |
| Builtin help | `help <builtin>` |
| Edit a root file safely | `sudoedit <file>` |
| Strict mode | `set -euo pipefail` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Shell Basics](shell-basics.md) | Terminal, shell and console; login and interactive shells; history and line editing | Core | Med |
| [Getting Help](getting-help.md) | Man sections, `apropos`, `help`, package docs, missing man pages | Core | Low |
| [Command Resolution](command-resolution.md) | Aliases, builtins, functions, `PATH`, the hash table, 126 and 127 | Core | Med |
| [Variables and Environment](variables-and-environment.md) | Export, `PATH`, startup files, `sudo`, cron and systemd environments | Core | High |
| [Locale and Encoding](locale-and-encoding.md) | `LANG`, `LC_ALL`, collation, UTF-8, `iconv` | Core | Low |
| [Quoting and Expansion](quoting-and-expansion.md) | Quotes, word splitting, globs, brace and parameter expansion | Core | Med |
| [Streams and Redirection](streams-and-redirection.md) | Descriptors, redirection order, pipes, `pipefail`, here-documents, `sudo tee` | Core | High |
| [Exit Codes and Chaining](exit-codes-and-chaining.md) | Status values, signals, AND and OR lists, `set -e`, `ERR` traps | Core | High |
| [Text Editors](text-editors.md) | `vim` keys, scripted edits, default editor, `sudoedit` | Core | Low |
| [Scripting Essentials](scripting-essentials.md) | Arguments, tests, `case`, loops, functions, debugging | RHCSA | Med |

---

## Scenarios and Labs

- [Binary Won't Execute](../interview/scenarios/binary-wont-execute.md): 126, 127 and interpreter errors in practice
- [Error Messages](../reference/error-messages.md): shell errors from this module and their causes
- [Round 1: Screening](../interview/round-1-screening.md): the L1 questions from this module
