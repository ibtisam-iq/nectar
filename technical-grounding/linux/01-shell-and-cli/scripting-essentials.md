# Scripting Essentials

A shell script is a file of commands with a shebang line, run as a program. RHCSA and daily operations need the same core: arguments, tests, conditionals, loops, functions and exit statuses; larger scripting topics belong in a dedicated Bash folder.

**Track:** RHCSA · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Shebang | First line, `#!/bin/bash`; chooses the interpreter | `head -1 script.sh` |
| Run a script | `chmod +x script.sh; ./script.sh`, or `bash script.sh` | `ls -l script.sh` |
| Arguments | `$0` name, `$1`..`$9`, `${10}`, `$#` count, `"$@"` all, kept separate | `./args.sh a "b c"` |
| Test commands | `[ ]` (POSIX), `[[ ]]` (bash: patterns, no word splitting) | `help [[` |
| Numeric comparison | `-eq -ne -lt -le -gt -ge`, or `(( a < b ))` | `[ 5 -gt 3 ]` |
| String comparison | `=`, `!=`, `-z` (empty), `-n` (not empty) | `[ -z "$x" ]` |
| File tests | `-e` exists, `-f` file, `-d` directory, `-r -w -x`, `-s` not empty | `[ -d /etc ]` |
| Read a file line by line | `while IFS= read -r line; do ...; done < file` | `help read` |
| Function variables | `local` keeps them inside the function | `help local` |
| Syntax check and lint | `bash -n script.sh`; `shellcheck script.sh` (EPEL, Ubuntu universe) | `echo $?` |
<!-- --8<-- [end:facts] -->

---

## Arguments

```bash
#!/bin/bash
echo "script: $0"
echo "count:  $#"
echo "first:  $1"
echo "all:    $*"
for arg in "$@"; do
    echo "arg:    [$arg]"
done
shift
echo "after shift, first: $1"
```

```bash
./args.sh web "db server" cache
```

Output:

```text
script: ./args.sh
count:  3
first:  web
all:    web db server cache
arg:    [web]
arg:    [db server]
arg:    [cache]
after shift, first: db server
```

`"$@"` keeps `db server` as one argument; `shift` drops `$1` and renumbers the rest.

---

## Tests and Conditionals

`[` is a command, so its arguments need spaces and quotes. Two common mistakes, with `x=5`:

```bash
[ $x > 3 ] && echo "test passed"
ls -l 3
unset y
[ $y = "a" ]; echo "rc=$?"
[ "$y" = "a" ]; echo "rc=$?"
[[ $y == a ]]; echo "rc=$?"
```

Output:

```text
test passed
-rw-r--r-- 1 laborant laborant 0 Sep 16 13:48 3
bash: line 4: [: =: unary operator expected
rc=2
rc=1
rc=1
```

!!! warning "Inside single brackets, > is a redirection"
    Inside `[ ]`, `>` is a redirection: the test ran as `[ 5 ]` (true) and created a file named `3`. An unquoted empty variable disappears and leaves `[ = a ]`. Use `-gt` or `(( x > 3 ))` for numbers, and quote variables or use `[[ ]]`.

A `case` statement matches one value against patterns:

```bash
#!/bin/bash
case "${1:-}" in
    start|stop|restart)
        echo "running: systemctl $1 app" ;;
    status)
        echo "app is active" ;;
    *)
        echo "usage: $0 {start|stop|restart|status}" >&2
        exit 2 ;;
esac
```

```bash
./svc.sh restart
./svc.sh reload; echo "rc=$?"
```

Output:

```text
running: systemctl restart app
usage: ./svc.sh {start|stop|restart|status}
rc=2
```

---

## Loops

```bash
for i in 1 2 3; do echo -n "$i "; done; echo
for ((i=0; i<3; i++)); do echo -n "$i "; done; echo
for f in /etc/host*; do echo "$f"; done
n=0; while [ $n -lt 3 ]; do n=$((n+1)); done; echo "n=$n"
until [ $n -eq 0 ]; do n=$((n-1)); done; echo "n=$n"
```

Output:

```text
1 2 3 
0 1 2 
/etc/host.conf
/etc/hostname
/etc/hosts
n=3
n=0
```

---

## A Complete Script

The script reads user names from a file, skips blanks and comments, reports each user, and exits non-zero if any is missing.

```bash
#!/bin/bash
set -euo pipefail

usage() {
    echo "usage: $0 <file-with-usernames>" >&2
    exit 2
}

user_status() {
    local user=$1
    if id "$user" &>/dev/null; then
        echo "$user: exists (uid $(id -u "$user"))"
    else
        echo "$user: missing"
        return 1
    fi
}

[[ $# -eq 1 ]] || usage
[[ -r $1 ]] || { echo "cannot read $1" >&2; exit 1; }

missing=0
while IFS= read -r name; do
    [[ -z $name || $name == \#* ]] && continue
    user_status "$name" || missing=$((missing + 1))
done < "$1"

echo "missing users: $missing"
(( missing == 0 ))
```

```bash
printf 'root\n# comment\n\nlaborant\nghost\n' > users.txt
./check-users.sh users.txt; echo "rc=$?"
./check-users.sh; echo "rc=$?"
```

Output:

```text
root: exists (uid 0)
laborant: exists (uid 1001)
ghost: missing
missing users: 1
rc=1
usage: ./check-users.sh <file-with-usernames>
rc=2
```

---

## Checking and Debugging

```bash
bash -n check-users.sh && echo "syntax ok"
printf 'if true\necho x\n' > bad.sh
bash -n bad.sh; echo "rc=$?"
bash -x ./svc.sh status
```

Output:

```text
syntax ok
bad.sh: line 3: syntax error: unexpected end of file
rc=2
+ case "${1:-}" in
+ echo 'app is active'
app is active
```

!!! note "bash -n checks syntax, not logic"
    `bash -n` parses without running; it catches a missing `fi`, `esac` or `done` (reported as `unexpected end of file`), not logic errors. `bash -x` traces each command. `shellcheck` finds unquoted variables and most of the mistakes above.

---

## Common Errors

### `[: =: unary operator expected`

**Cause:** an unquoted variable was empty, so `[` received too few arguments.

**Fix:** quote it (`[ "$y" = a ]`) or use `[[ $y == a ]]`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between $@ and $*?"
    **Say first:** quoted, `"$@"` expands to each argument as a separate word, while `"$*"` joins them into one string.

    **Proof:** `./args.sh web "db server"` prints `[db server]` as one argument with `"$@"`.

    **Follow-up:** What happens to `"db server"` if `$@` is not quoted?

??? question "L1: What is the difference between [ ] and [[ ]]?"
    **Say first:** `[` is a command that follows normal word splitting; `[[` is bash syntax that does not split variables and supports pattern and regex matching.

    **Proof:** with `y` unset, `[ $y = a ]` errors while `[[ $y == a ]]` returns 1.

    **Follow-up:** Which one works in `/bin/sh` on Ubuntu?
<!-- --8<-- [end:l1] -->

??? question "L2: Write a loop that prints each line of a file, keeping spaces."
    **Say first:** `while read` with `IFS=` and `-r`.

    **Proof:**

    ```bash
    while IFS= read -r line; do printf '%s\n' "$line"; done < file.txt
    ```

    **Follow-up:** Why is `for line in $(cat file.txt)` wrong?

??? question "L2: Write a script that creates users from a list, skipping those that exist."
    **Say first:** loop over the file, test with `id`, create with `useradd`.

    **Proof:**

    ```bash
    while IFS= read -r u; do
        id "$u" &>/dev/null || sudo useradd -m "$u"
    done < users.txt
    ```

    **Follow-up:** How would you set an initial password non-interactively? (`chpasswd`.)

??? question "L3: A script works for most inputs but fails with unary operator expected for some."
    **Say first:** an unquoted variable is empty for those inputs.

    **Proof:** `bash -x script.sh` shows `[ = value ]`; quoting the variable fixes it.

    **Follow-up:** Which tool reports this before the script runs? (`shellcheck`, SC2086.)

??? question "L3: A counter loop in a set -e script stops after the first iteration."
    **Say first:** an arithmetic command returned status 1.

    **Proof:** `((count++))` with `count=0` evaluates to 0, which is false, so `set -e` exits.

    **Follow-up:** Name two safe ways to increment. (`count=$((count+1))`, `((count+=1)) || true`.)

---

## Related

- [Quoting and Expansion](quoting-and-expansion.md): why variables are quoted
- [Exit Codes and Chaining](exit-codes-and-chaining.md): `set -e` and statuses
- [Users](../04-users-and-access/users.md): the commands the example script checks

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
