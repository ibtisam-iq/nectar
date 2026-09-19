# Streams and Redirection

Every process starts with three open file descriptors: 0 (standard input), 1 (standard output) and 2 (standard error). Redirection and pipes rewire those descriptors before the program runs, which is how logs are captured, errors are separated and commands are chained.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Standard streams | 0 stdin, 1 stdout, 2 stderr | `ls -l /proc/self/fd` |
| `>` / `>>` | Truncate / append stdout to a file | `echo x >> f` |
| `2>` | Redirect stderr | `ls /nope 2> err.txt` |
| `> file 2>&1` | Both streams to the file; order matters | `cat file` |
| `2>&1 > file` | Only stdout to the file; stderr stays on the terminal | `cat file` |
| `&> file` | Bash shorthand for `> file 2>&1` | `cat file` |
| Pipe (vertical bar) | Connects stdout of one command to stdin of the next; stderr is not piped | `ls -l /proc/self/fd` |
| Piping both streams | `2>&1` before the bar, or the bash bar-ampersand form | `set -x` |
| Pipeline status | Status of the last command, unless `pipefail` is set | `echo ${PIPESTATUS[*]}` |
| `/dev/null` | Discards writes, returns end of file on read | `ls -l /dev/null` |
| Writing root-owned files | Pipe into `sudo tee file`; `sudo cmd > file` redirects as the caller | `sudo cat file` |
| Here-document | `<<EOF` expands variables; `<<'EOF'` does not | `cat <<'EOF'` |
| Process substitution | `<(cmd)` presents output as a file path | `diff <(a) <(b)` |
<!-- --8<-- [end:facts] -->

---

## The Three Streams

In an SSH session, all three descriptors point at the terminal. Redirections replace them for one command:

```bash
ls -l /proc/$$/fd
ls -l /proc/self/fd < /etc/hostname 2>/dev/null
```

Output:

```text
total 0
lrwx------ 1 laborant laborant 64 Sep 16 13:44 0 -> /dev/pts/0
lrwx------ 1 laborant laborant 64 Sep 16 13:44 1 -> /dev/pts/0
lrwx------ 1 laborant laborant 64 Sep 16 13:44 2 -> /dev/pts/0
total 0
lr-x------ 1 laborant laborant 64 Sep 16 13:44 0 -> /etc/hostname
lrwx------ 1 laborant laborant 64 Sep 16 13:44 1 -> /dev/pts/0
l-wx------ 1 laborant laborant 64 Sep 16 13:44 2 -> /dev/null
lr-x------ 1 laborant laborant 64 Sep 16 13:44 3 -> /proc/3445/fd
```

Descriptor 3 is the directory `ls` opened to read its own listing.

| Stream | Descriptor | Default | Carries |
|---|---|---|---|
| stdin | 0 | Keyboard | Input data |
| stdout | 1 | Terminal | Normal results, meant for other programs |
| stderr | 2 | Terminal | Errors, warnings and progress, meant for people |

`/dev/stdin`, `/dev/stdout` and `/dev/stderr` are symlinks to `/proc/self/fd/0`, `1` and `2`.

---

## Redirecting Output and Errors

`ls` below lists one file that exists and one that does not, so it writes to both streams.

```bash
ls /etc/hostname /nope > out.txt
echo "--- out.txt:"; cat out.txt
ls /etc/hostname /nope 2> err.txt
echo "--- err.txt:"; cat err.txt
```

Output:

```text
ls: cannot access '/nope': No such file or directory
--- out.txt:
/etc/hostname
/etc/hostname
--- err.txt:
ls: cannot access '/nope': No such file or directory
```

The first error line reached the terminal because only stdout was redirected. In the second command, the file name reached the terminal because only stderr was redirected.

| Syntax | stdout goes to | stderr goes to |
|---|---|---|
| `cmd > f` | `f` (truncated) | Terminal |
| `cmd >> f` | `f` (appended) | Terminal |
| `cmd 2> f` | Terminal | `f` |
| `cmd > f 2>&1` | `f` | `f` |
| `cmd &> f`, `cmd &>> f` | `f` | `f` |
| `cmd > out 2> err` | `out` | `err` |
| `cmd > /dev/null 2>&1` | Discarded | Discarded |
| `cmd < f` | Reads stdin from `f` | |

---

## Order of Redirections

Redirections are applied left to right, and `2>&1` copies wherever descriptor 1 points at that moment.

```bash
ls /etc/hostname /nope > both.txt 2>&1
echo "--- both.txt:"; cat both.txt
ls /etc/hostname /nope 2>&1 > order.txt
echo "--- order.txt:"; cat order.txt
```

Output:

```text
--- both.txt:
ls: cannot access '/nope': No such file or directory
/etc/hostname
ls: cannot access '/nope': No such file or directory
--- order.txt:
/etc/hostname
```

In the second command, `2>&1` pointed stderr at the terminal (where stdout still pointed), then `> order.txt` moved stdout alone.

!!! warning "2>&1 > file does not capture errors"
    Read `2>&1` as "make 2 a copy of 1 as it is now", not "merge 2 into 1 forever". Cron lines such as `job.sh 2>&1 > /var/log/job.log` silently lose every error message.

---

## Appending and noclobber

```bash
echo first > log.txt
echo second >> log.txt
cat log.txt
set -o noclobber
echo third > log.txt
echo "rc=$?"
echo third >| log.txt
set +o noclobber
cat log.txt
```

Output:

```text
first
second
/tmp/rd.sh: line 22: log.txt: cannot overwrite existing file
rc=1
third
```

`noclobber` blocks `>` on existing files; `>|` overrides it deliberately.

---

## Pipes

A pipe connects stdout of one process to stdin of the next. Stderr bypasses the pipe unless it is redirected.

```bash
ls /etc/hostname /nope | wc -l
ls /etc/hostname /nope 2>&1 | wc -l
ls /etc/hostname /nope |& wc -l
```

Output:

```text
ls: cannot access '/nope': No such file or directory
1
2
2
```

The exit status of a pipeline is the status of its last command. `PIPESTATUS` keeps all of them, and `pipefail` makes any failure count:

```bash
false | true; echo "status=$? pipestatus=${PIPESTATUS[*]}"
set -o pipefail
false | true; echo "status=$? with pipefail"
```

Output:

```text
status=0 pipestatus=1 0
status=1 with pipefail
```

When the reader exits early, the writer receives `SIGPIPE`. `yes` would run forever, but it stops once `head` has its lines:

```bash
yes | head -1; echo "yes status: ${PIPESTATUS[0]}"
```

Output:

```text
y
yes status: 141
```

141 is 128 + 13, the number of `SIGPIPE`.

!!! warning "pipefail and SIGPIPE together"
    With `set -o pipefail`, `cmd | head -1` can fail with status 141 even though the output is correct. Scripts that combine `pipefail` with early-exit readers must allow that status or avoid the pattern.

---

## Here-Documents and Here-Strings

```bash
cat <<EOF
user=$USER
literal=\$HOME
EOF
cat <<'EOF'
user=$USER
EOF
wc -w <<< "three words here"
```

Output:

```text
user=laborant
literal=$HOME
user=$USER
3
```

Quoting the delimiter (`'EOF'`) disables expansion, which is the safe choice when writing scripts or configuration files that contain `$`. `<<-EOF` strips leading tabs, not spaces.

---

## Writing Files as Root

The shell opens redirection targets before `sudo` starts, so the open runs as the calling user:

```bash
echo "config line" | sudo tee /etc/demo.conf > /dev/null
cat /etc/demo.conf
sudo echo "denied" > /etc/demo2.conf
echo "rc=$?"
echo "appended" | sudo tee -a /etc/demo.conf
```

Output:

```text
config line
/tmp/rd.sh: line 48: /etc/demo2.conf: Permission denied
rc=1
appended
```

`tee` writes to the file and to stdout; `> /dev/null` hides the copy, and `-a` appends. `sudo sh -c 'echo x > file'` also works, at the cost of an extra quoting layer.

---

## Process Substitution and Extra Descriptors

```bash
diff <(printf 'a\nb\n') <(printf 'a\nc\n')
exec 3> fd3.txt
echo "via fd 3" >&3
exec 3>&-
cat fd3.txt
{ echo out; echo err >&2; } 2>/dev/null
```

Output:

```text
2c2
< b
---
> c
via fd 3
out
```

`<(cmd)` becomes a path such as `/dev/fd/63`, so tools that need file arguments can read command output. `exec 3>` keeps a descriptor open for a whole script, and `exec 3>&-` closes it. Braces apply one redirection to a group of commands.

---

## Common Errors

### `/etc/demo2.conf: Permission denied`

**Cause:** the command was `sudo echo ... > /etc/demo2.conf`; the redirection is performed by the unprivileged shell, not by `sudo`.

**Fix:** `echo ... | sudo tee /etc/demo2.conf`.

### `log.txt: cannot overwrite existing file`

**Cause:** `set -o noclobber` is active (often in `~/.bashrc`).

**Fix:** use `>|` to overwrite on purpose, or `>>` to append.

### `bash: line 1: $logfile: ambiguous redirect`

**Cause:** the redirection target is an unquoted variable that is empty or contains spaces (`> $logfile`).

**Fix:** quote it: `> "$logfile"`, and make sure it is set.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are stdin, stdout and stderr, and why are errors on a separate stream?"
    **Say first:** descriptors 0, 1 and 2; errors go to stderr so they reach the operator even when stdout is piped or saved.

    **Proof:** `ls /etc/hostname /nope | wc -l` prints the error and counts only one line.

    **Follow-up:** How do you send both streams through a pipe?

??? question "L1: What is the difference between > file 2>&1 and 2>&1 > file?"
    **Say first:** redirections apply left to right; the first sends both streams to the file, the second leaves stderr on the terminal.

    **Proof:** the `both.txt` and `order.txt` demonstration above.

    **Follow-up:** What is the bash shorthand for the first form?

??? question "L1: Why does sudo echo text > /etc/file fail with permission denied?"
    **Say first:** the calling shell opens `/etc/file` before `sudo` runs, and that shell is not root.

    **Proof:** `echo text | sudo tee /etc/file`

    **Follow-up:** How do you append instead of overwrite? (`sudo tee -a`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Run a job so that output goes to one log and errors to another, both appended."
    **Say first:** two separate append redirections.

    **Proof:**

    ```bash
    ./job.sh >> /var/log/job.out 2>> /var/log/job.err
    ```

    **Follow-up:** How would you also see the output live? (`./job.sh 2>&1 | tee -a job.log`.)

??? question "L2: Silence a command completely but keep its exit status."
    **Say first:** discard both streams; redirection does not change the status.

    **Proof:** `grep -q pattern file > /dev/null 2>&1; echo $?`

    **Follow-up:** Why is `-q` better than redirecting for `grep`?

??? question "L2: Write a multi-line config file containing $variables that must stay literal."
    **Say first:** a here-document with a quoted delimiter, written through `sudo tee`.

    **Proof:**

    ```bash
    sudo tee /etc/app.conf > /dev/null <<'EOF'
    listen $PORT
    EOF
    ```

    **Follow-up:** What changes without the quotes around `EOF`?

??? question "L3: A cron job's log file is empty even though the job fails."
    **Say first:** check the redirection order and which stream the errors use.

    **Proof:** the crontab line reads `job.sh 2>&1 > job.log`, which keeps stderr on cron's mail channel; `job.sh > job.log 2>&1` captures it.

    **Follow-up:** Where does cron send output that is not redirected? (Mail to `MAILTO`, or the journal.)

??? question "L3: A deployment script reports success, but a step in a pipeline failed."
    **Say first:** the pipeline returned the status of its last command.

    **Proof:** `curl -s "$url" | tar xz` exits 0 when `tar` succeeds on partial input; `echo "${PIPESTATUS[@]}"` shows the curl failure; `set -o pipefail` fixes the script.

    **Follow-up:** What does `pipefail` do to `cmd | head -1`?

??? question "L4: How does the shell implement 2>&1 and a pipe?"
    **Say first:** after `fork`, the child calls `dup2(1, 2)` for `2>&1`; for a pipe, the shell calls `pipe()` and each child `dup2`s one end onto descriptor 1 or 0 before `execve`.

    **Proof:** `strace -f -e trace=pipe2,dup2,execve bash -c 'ls /nope 2>&1 | wc -l'`

    **Don't say:** "The shell reads the output of the first command and passes it to the second."

---

## Related

- [Exit Codes and Chaining](exit-codes-and-chaining.md): statuses, `&&` and `||`
- [File Descriptors](../02-files-and-filesystem/file-descriptors.md): the kernel side of descriptors
- [Quoting and Expansion](quoting-and-expansion.md): why unquoted targets become ambiguous
- [Sudo and Su](../04-users-and-access/sudo-and-su.md): why `sudo` does not cover the redirection

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
