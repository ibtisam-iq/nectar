# Quoting and Expansion

Bash rewrites every command line before running it: it expands braces, tildes, variables, command substitutions and arithmetic, splits the result into words, and replaces globs with file names. Quoting controls which of those steps happen, and missing quotes are the most common source of shell script bugs.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Single quotes | Everything literal; no expansion at all | `echo '$HOME'` |
| Double quotes | Expand `$var`, `$(cmd)`, `$((expr))`; prevent word splitting and globbing | `echo "$HOME"` |
| Backslash | Escapes one character | `echo \$HOME` |
| Expansion order | Brace, tilde, parameter/command/arithmetic, word splitting, pathname (glob), quote removal | `set -x` |
| Globs | Expanded by the shell, not by the command | `echo *` |
| Unmatched glob | Left as literal text unless `nullglob` is set | `echo *.none` |
| Word splitting | Unquoted expansions split on `IFS` (space, tab, newline) | `set -x` |
| Always quote | `"$var"`, `"$(cmd)"`, `"$@"` | `bash -x script.sh` |
| End of options | `--` stops option parsing, for names starting with `-` | `rm -- -rf` |
| Command substitution | `$(cmd)` nests cleanly; backticks are the legacy form | `echo "$(date)"` |
<!-- --8<-- [end:facts] -->

---

## Quote Types

```bash
name=world
echo 'single: $name $(date +%Y) \n'
echo "double: $name $(date +%Y) \$HOME"
echo unquoted:   $name    spaced
```

Output:

```text
single: $name $(date +%Y) \n
double: world 2026 $HOME
unquoted: world spaced
```

Unquoted, the extra spaces disappear: word splitting turns the line into separate arguments, and `echo` joins them with one space.

---

## Word Splitting and Filenames with Spaces

```bash
touch "report 2026.txt" notes.md
for f in $(ls); do echo "[$f]"; done
for f in *; do echo "[$f]"; done
file="report 2026.txt"
ls -l $file
ls -l "$file"
```

Output:

```text
[notes.md]
[report]
[2026.txt]
[notes.md]
[report 2026.txt]
ls: cannot access 'report': No such file or directory
ls: cannot access '2026.txt': No such file or directory
-rw-rw-r-- 1 laborant laborant 0 Sep 16 13:42 report 2026.txt
```

`$(ls)` is split on spaces; the glob `*` produces one word per file. `set -x` before the command shows the split arguments (`+ ls -l report 2026.txt`).

!!! warning "Never loop over the output of ls"
    `for f in $(ls)` breaks on spaces and on glob characters in names. Use `for f in *`, or `find ... -print0 | xargs -0` for recursive work.

Arrays keep elements intact only with `"${arr[@]}"`:

```bash
args=("one two" three)
printf '[%s]\n' "${args[@]}"
printf '[%s]\n' ${args[@]}
printf '[%s]\n' "${args[*]}"
```

Output:

```text
[one two]
[three]
[one]
[two]
[three]
[one two three]
```

The same rule applies to script arguments: `"$@"` passes them unchanged, `$*` and unquoted `$@` re-split them.

---

## Globs

```bash
echo *.md *.log
shopt -s nullglob; echo "nullglob: [" *.log "]"; shopt -u nullglob
```

Output:

```text
notes.md *.log
nullglob: [ ]
```

| Pattern | Matches |
|---|---|
| `*` | Any string, excluding a leading `.` |
| `?` | One character |
| `[abc]`, `[0-9]`, `[!a]` | One character from a set, or not in it |
| `**` | Any depth, with `shopt -s globstar` |

A file whose name starts with `-` becomes an option after glob expansion:

```bash
touch ./-l
ls *
rm ./-l
```

Output:

```text
-rw-rw-r-- 1 laborant laborant    0 Sep 16 13:42 notes.md
-rw-rw-r-- 1 laborant laborant    0 Sep 16 13:42 notes.md.bak
-rw-rw-r-- 1 laborant laborant    0 Sep 16 13:42 report 2026.txt

proj:
total 12
# ... (trimmed)
```

`ls *` received `-l` as its first argument and switched to long format. `ls -- *` or `ls ./*` avoids it; `rm -- -rf` and `rm ./-rf` remove a file literally named `-rf`.

---

## Brace, Tilde and Arithmetic Expansion

Brace expansion happens first and does not look at the filesystem.

```bash
echo {a,b,c}.conf
echo web{01..03}
echo {01..10..3}
mkdir -p proj/{src,docs,tests}; ls proj
cp notes.md{,.bak}
echo ~ ~root
echo "~ is not expanded in quotes"
echo "$(( 7 / 2 )) $(( 7 % 2 )) $(( 2 ** 10 ))"
```

Output:

```text
a.conf b.conf c.conf
web01 web02 web03
01 04 07 10
docs
src
tests
/home/laborant /root
~ is not expanded in quotes
3 1 1024
```

Bash arithmetic is integer only; use `bc` or `awk` for decimals.

---

## Parameter Expansion

```bash
path=/var/log/nginx/access.log.1
echo "${path##*/}"
echo "${path%/*}"
echo "${path%.*}"
echo "${path/log/LOG}"
echo "${path//log/LOG}"
echo "${#path}"
unset port; echo "${port:-8080} [$port]"
echo "${port:=9090} [$port]"
echo "${missing:?must be set}"
```

Output:

```text
access.log.1
/var/log/nginx
/var/log/nginx/access.log
/var/LOG/nginx/access.log.1
/var/LOG/nginx/access.LOG.1
27
8080 []
9090 [9090]
/tmp/q.sh: line 39: missing: must be set
```

| Form | Result |
|---|---|
| `${v##*/}` / `${v%/*}` | Basename / dirname without a subprocess |
| `${v%.*}` / `${v##*.}` | Strip / keep the last extension |
| `${v/a/b}` / `${v//a/b}` | Replace first / all |
| `${v:-x}` | `x` if unset or empty; `v` unchanged |
| `${v:=x}` | Same, and assigns `x` to `v` |
| `${v:?msg}` | Exits a script with `msg` if unset or empty |
| `${#v}` | Length |

!!! tip "Fail fast on missing configuration"
    `: "${DB_HOST:?DB_HOST is required}"` at the top of a script stops it before it runs with an empty host.

---

## Common Errors

### `ls: cannot access 'report': No such file or directory`

**Cause:** an unquoted variable holding a name with spaces was split into several arguments.

**Fix:** quote it: `ls -l "$file"`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between single and double quotes?"
    **Say first:** single quotes keep everything literal; double quotes still expand variables, command substitution and arithmetic, but stop word splitting and globbing.

    **Proof:** `echo '$HOME'` versus `echo "$HOME"`.

    **Follow-up:** How do you put a single quote inside a single-quoted string? (`'it'\''s'`.)

??? question "L1: Who expands *.log, the shell or ls?"
    **Say first:** the shell; `ls` receives a list of file names, or the literal `*.log` when nothing matches.

    **Proof:** `echo *.log`; `set -x; ls *.log`.

    **Follow-up:** Why does `find . -name *.log` sometimes fail? (The shell expands the unquoted pattern first.)
<!-- --8<-- [end:l1] -->

??? question "L2: Rename every .txt file in a directory to .bak, including names with spaces."
    **Say first:** loop over a glob and use parameter expansion, with quotes.

    **Proof:**

    ```bash
    for f in *.txt; do mv -- "$f" "${f%.txt}.bak"; done
    ```

    **Follow-up:** What happens if no `.txt` file exists, and how does `nullglob` change that?

??? question "L2: Create directories app/dev, app/staging and app/prod in one command."
    **Say first:** brace expansion.

    **Proof:** `mkdir -p app/{dev,staging,prod}`

    **Follow-up:** Why does `mkdir -p "app/{dev,prod}"` create one oddly named directory?

??? question "L2: Delete a file named -rf."
    **Say first:** end option parsing or give a path.

    **Proof:** `rm -- -rf` or `rm ./-rf`

    **Follow-up:** What did `rm -rf` do when typed without `--`? (Nothing: no operands.)

??? question "L3: A backup script works in testing but copies nothing for some customers."
    **Say first:** look for unquoted variables and names with spaces.

    **Proof:** `bash -x backup.sh` shows `cp /data/Acme Corp /backup` split into two arguments.

    **Follow-up:** Which linter catches this before it ships? (`shellcheck`, warning SC2086.)

??? question "L4: In what order does bash expand a command line, and why does it matter?"
    **Say first:** brace, tilde, then parameter, command and arithmetic expansion left to right, then word splitting, pathname expansion and quote removal.

    **Proof:** `x='*'; echo $x` lists files because the glob in the variable is expanded after substitution; `echo "$x"` prints `*`.

    **Don't say:** "Variables are expanded last."

---

## Related

- [Shell Basics](shell-basics.md): tracing command lines with `set -x`
- [Variables and Environment](variables-and-environment.md): where variables come from
- [Scripting Essentials](scripting-essentials.md): `"$@"` in scripts

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
