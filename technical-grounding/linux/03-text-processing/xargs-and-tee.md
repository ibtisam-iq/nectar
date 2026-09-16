# xargs and tee

`xargs` turns lines of input into command arguments, and `tee` copies a stream to files while passing it on. Together they connect `find`, `grep` and other list-producing commands to actions, and keep a record of what a pipeline did.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `xargs` default | Splits input on whitespace and runs the command with as many arguments as fit | `xargs echo` |
| One item per command | `-n 1` | `xargs -n1` |
| Placeholder | `-I{}` runs once per line and replaces `{}` | `xargs -I{} echo {}` |
| Safe names | `-0` with NUL-separated input (`find -print0`, `grep -Z`) | `xargs -0` |
| Parallel | `-P N` runs up to N commands at once | `xargs -P4` |
| Empty input | GNU `xargs` runs the command once anyway unless `-r` | `xargs -r` |
| Show commands | `-t` prints each command before running it | `xargs -t` |
| Stop on failure | A command exiting 255 aborts `xargs`, which then exits 124 | `echo $?` |
| Argument limit | `ARG_MAX` bytes; `xargs` splits long lists automatically | `getconf ARG_MAX` |
| `tee file` | Writes to the file and to stdout | `cat f` |
| `tee -a` | Appends | `tee -a log` |
| Root-owned files | `sudo tee file`, because the shell performs `>` as the caller | `ls -l file` |
<!-- --8<-- [end:facts] -->

---

## xargs Basics

```bash
printf 'a.log\nb.log\nc.log\n' | xargs touch
ls
printf 'a.log\nb.log\nc.log\n' | xargs echo rm
printf 'a.log\nb.log\nc.log\n' | xargs -n 1 echo rm
printf 'web01\nweb02\n' | xargs -I{} echo "ssh {} uptime"
printf 'x\n' | xargs -t -n1 echo processed
```

Output:

```text
a.log
b.log
c.log
rm a.log b.log c.log
rm a.log
rm b.log
rm c.log
ssh web01 uptime
ssh web02 uptime
echo processed x
processed x
```

Putting `echo` in front of the real command is a dry run: it prints what would execute.

---

## Names with Spaces

```bash
touch "my file.log"
find . -name '*.log' | xargs ls -1
find . -name '*.log' -print0 | xargs -0 ls -1
```

Output:

```text
ls: cannot access './my': No such file or directory
ls: cannot access 'file.log': No such file or directory
./a.log
./b.log
./c.log
./a.log
./b.log
./c.log
./my file.log
```

!!! warning "Use -print0 and -0 for file names"
    Default splitting breaks names with spaces, quotes or newlines, and `xargs rm` then deletes the wrong files or fails halfway. `find -exec ... +` is an alternative that needs no `xargs` at all.

---

## Parallel Runs and Empty Input

```bash
time (seq 1 4 | xargs -n1 sleep)
time (seq 1 4 | xargs -n1 -P4 sleep)
true | xargs echo "ran anyway"
true | xargs -r echo "never printed"
```

Output:

```text

real	0m10.006s
user	0m0.006s
sys	0m0.001s

real	0m4.004s
user	0m0.006s
sys	0m0.001s
ran anyway
```

Four sleeps of 1 to 4 seconds take 10 seconds in sequence and 4 seconds with `-P4`. `-P` is a quick way to fan out checks across hosts (`xargs -P10 -I{} ssh {} uptime`), with output lines from different commands interleaved.

!!! danger "Empty input still runs the command"
    `find /tmp -name '*.old' | xargs rm` with no matches runs `rm` with no arguments, which prints `rm: missing operand`; commands with a default target (`xargs ls`, `xargs du`) act on the current directory instead. Add `-r` (`--no-run-if-empty`).

---

## Limits and Failures

```bash
getconf ARG_MAX
seq 1 200000 | xargs echo | wc -l
printf 'a\nb\n' | xargs -I{} sh -c 'echo {}; exit 255'; echo "rc=$?"
```

Output:

```text
2097152
10
a
xargs: sh: exited with status 255; aborting
rc=124
```

200000 numbers do not fit in one command line, so `xargs` ran `echo` 10 times. Exit status 255 from a command makes `xargs` stop; statuses 1 to 125 are collected and reported as 123 at the end.

---

## tee

```bash
echo "deploy started" | tee deploy.log
echo "step 2" | tee -a deploy.log > /dev/null
cat deploy.log
printf 'line\n' | tee out1.txt out2.txt | wc -l
(echo "stdout line"; echo "stderr line" >&2) 2>&1 | tee both.log
echo "key=1" | sudo tee /etc/demo-tee.conf
ls -l /etc/demo-tee.conf
```

Output:

```text
deploy started
deploy started
step 2
1
stdout line
stderr line
key=1
-rw-r--r-- 1 root root 6 Sep 16 14:29 /etc/demo-tee.conf
```

`tee` writes to every file named and still passes the stream on. `2>&1` before the pipe sends errors into the log as well.

With `pipefail`, a failure before `tee` is not hidden:

```bash
set -o pipefail
false | tee /dev/null; echo "rc=$?"
```

Output:

```text
rc=1
```

Common `tee` patterns:

```bash
long-job.sh 2>&1 | tee -a run.log                   # watch and keep a log
echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.d/90-app.conf
sudo tee /etc/app.conf > /dev/null <<'EOF'          # write a file without echoing it
listen 8080
EOF
app.sh | tee >(grep ERROR > errors.log) > full.log  # split a stream
```

---

## Common Errors

### `xargs: sh: exited with status 255; aborting`

**Cause:** a command run by `xargs` exited with 255, which `xargs` treats as fatal.

**Fix:** make the command return 1 for ordinary failures, or wrap it (`sh -c '... || exit 1'`).

### `xargs: argument line too long`

**Cause:** a single input item is longer than `xargs` can place on one command line; a 200 KB line without spaces is enough.

**Fix:** pass the data through stdin or a file instead of as arguments.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Why is xargs needed when a pipe already passes data?"
    **Say first:** a pipe feeds stdin, but many commands (`rm`, `chmod`, `kill`) take arguments instead; `xargs` converts input lines into arguments.

    **Proof:** `find . -name '*.tmp' | xargs rm` versus `find . -name '*.tmp' | rm`, which does nothing.

    **Follow-up:** What breaks with file names that contain spaces?

??? question "L1: What does tee do, and why is sudo tee used for root files?"
    **Say first:** `tee` writes its input to files and to stdout; with `sudo`, the file is opened by a root process instead of by the calling shell.

    **Proof:** `echo x | sudo tee /etc/f` works where `sudo echo x > /etc/f` fails.

    **Follow-up:** How do you append instead of overwrite?
<!-- --8<-- [end:l1] -->

??? question "L2: Delete every .tmp file under /data safely, including names with spaces."
    **Say first:** NUL-separated names and `-r`.

    **Proof:** `find /data -name '*.tmp' -print0 | xargs -0 -r rm --`

    **Follow-up:** Why the `--`?

??? question "L2: Check uptime on 20 servers in parallel from a host list."
    **Say first:** one host per command, several at a time.

    **Proof:** `xargs -P10 -I{} ssh -o BatchMode=yes {} uptime < hosts.txt`

    **Follow-up:** How do you tell which output line came from which host?

??? question "L2: Run a long upgrade and keep a full log while watching it."
    **Say first:** merge both streams and `tee` them.

    **Proof:** `sudo dnf -y upgrade 2>&1 | tee -a /var/tmp/upgrade.log`

    **Follow-up:** How do you keep the upgrade's exit status? (`pipefail` or `${PIPESTATUS[0]}`.)

??? question "L3: A nightly cleanup job fails with rm: missing operand on quiet nights."
    **Say first:** the search found nothing, and `xargs` still ran `rm` once with no arguments.

    **Proof:** `true | xargs rm` reproduces `rm: missing operand`; `xargs -r rm` runs nothing and exits 0.

    **Follow-up:** Which commands are dangerous rather than noisy with empty input? (Commands with a default target, such as `xargs ls` or `xargs du`, which act on the current directory.)

??? question "L3: A deployment log written with tee is missing all error messages."
    **Say first:** stderr bypassed the pipe.

    **Proof:** the command is `deploy.sh | tee deploy.log`; `deploy.sh 2>&1 | tee deploy.log` captures errors.

    **Follow-up:** How does the job's exit status change when `tee` is added?

---

## Related

- [Finding Files](../02-files-and-filesystem/finding-files.md): `-print0` and `-exec +`
- [Streams and Redirection](../01-shell-and-cli/streams-and-redirection.md): pipes and `sudo tee`
- [Cut, Sort, Uniq and Tr](cut-sort-uniq-tr.md): the filters before `xargs`

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
