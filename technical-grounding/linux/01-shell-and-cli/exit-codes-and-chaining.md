# Exit Codes and Chaining

Every command ends with an exit status from 0 to 255: 0 means success and anything else means failure. Chaining operators, `if`, `set -e`, CI pipelines, systemd and Kubernetes all decide what happens next from that one number.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Last status | `$?`, overwritten by the next command | `echo $?` |
| Success | 0 | `true; echo $?` |
| General failure | 1 | `false; echo $?` |
| Misuse or serious error | 2 (`ls`, `grep` on a missing file) | `ls /nope; echo $?` |
| Found but cannot execute | 126 | `/usr/lib/os-release; echo $?` |
| Command not found | 127 | `nosuchcmd; echo $?` |
| Killed by signal N | 128 + N: 130 `SIGINT`, 137 `SIGKILL`, 141 `SIGPIPE`, 143 `SIGTERM` | `kill -l 9` |
| `timeout` expired | 124 | `timeout 1 sleep 5; echo $?` |
| Values above 255 | Reduced modulo 256 (`exit 300` gives 44) | `bash -c 'exit 300'; echo $?` |
| `a && b` | `b` runs only if `a` succeeded | `mkdir d && cd d` |
| OR list (double bar) | The second command runs only if the first failed | `echo $?` |
| `a ; b` | `b` always runs | `echo $?` |
| `grep` statuses | 0 match, 1 no match, 2 error | `grep -q x f; echo $?` |
<!-- --8<-- [end:facts] -->

---

## Reading Exit Statuses

```bash
ls /etc/hostname > /dev/null; echo "ls ok: $?"
ls /nope 2> /dev/null; echo "ls missing: $?"
grep -q root /etc/passwd; echo "grep match: $?"
grep -q nosuchuser /etc/passwd; echo "grep no match: $?"
grep -q root /nope 2> /dev/null; echo "grep error: $?"
nosuchcmd 2> /dev/null; echo "not found: $?"
/usr/lib/os-release 2> /dev/null; echo "not executable: $?"
```

Output:

```text
ls ok: 0
ls missing: 2
grep match: 0
grep no match: 1
grep error: 2
not found: 127
not executable: 126
```

`grep` separates "no match" (1) from "error" (2), so a script can tell a missing pattern from a missing file.

---

## Signals and Special Values

```bash
sleep 30 & kill $!; wait $!; echo "SIGTERM: $?"
sleep 30 & kill -9 $!; wait $!; echo "SIGKILL: $?"
sleep 30 & kill -INT $!; wait $!; echo "SIGINT: $?"
timeout 1 sleep 5; echo "timeout: $?"
bash -c 'exit 300'; echo "exit 300: $?"
kill -l 9 15 2 13
```

Output:

```text
SIGTERM: 143
/tmp/ec.sh: line 12:  3488 Killed                  sleep 30
SIGKILL: 137
SIGINT: 130
timeout: 124
exit 300: 44
KILL
TERM
INT
PIPE
```

| Status | Meaning | Typical source |
|---|---|---|
| 0 | Success | |
| 1 | General error | Most programs, `false` |
| 2 | Usage error or serious trouble | Bash builtins, `ls`, `grep` |
| 124 | Timed out | `timeout` |
| 125 | Container failed to start | `docker run` |
| 126 | Not executable | Missing `x` bit, `noexec` mount |
| 127 | Not found | Typo, missing package, `PATH` |
| 130 | `SIGINT` (Ctrl+C) | Interrupted by the user |
| 137 | `SIGKILL` | `kill -9`, OOM killer, container memory limit |
| 141 | `SIGPIPE` | Reader closed a pipe early |
| 143 | `SIGTERM` | `kill`, `systemctl stop`, pod termination |

!!! warning "Exit 137 in a container usually means out of memory"
    Kubernetes shows `OOMKilled` with exit code 137 when the container exceeds its memory limit. The same number from a manual `kill -9` looks identical in the exit code, so check `kubectl describe pod` or `dmesg` for the OOM record.

---

## Chaining Commands

```bash
mkdir /tmp/ecdemo && echo "created"
mkdir /tmp/ecdemo && echo "created again"
mkdir /tmp/ecdemo 2>/dev/null || echo "already exists"
false; echo "after false with ;"
true && false || echo "fallback ran"
```

Output:

```text
created
mkdir: cannot create directory ‘/tmp/ecdemo’: File exists
already exists
after false with ;
fallback ran
```

!!! danger "a && b || c is not if-then-else"
    `c` runs when `a` fails and also when `b` fails. The last line above shows it: `true` succeeded, `false` failed, and the fallback ran anyway. Use `if a; then b; else c; fi` when the difference matters.

`if` tests an exit status directly, so `if grep -q ...` needs no `$?`:

```bash
if grep -q laborant /etc/passwd; then echo "user exists"; fi
if ! id ghost &>/dev/null; then echo "ghost missing"; fi
```

Output:

```text
user exists
ghost missing
```

---

## set -e, set -u and pipefail

`set -e` exits the script when a command fails, except where the failure is tested: in `if` and `while` conditions, before `||` or `&&`, and after `!`.

```bash
cat > /tmp/sete.sh <<'EOF'
set -e
echo "start"
false || true
if false; then :; fi
false && echo "never"
echo "still running"
count=$(grep -c nomatch /etc/hostname)
echo "not reached: $count"
EOF
bash /tmp/sete.sh; echo "script exit: $?"
```

Output:

```text
start
still running
script exit: 1
```

The `grep` inside the assignment returned 1 (no match), and `set -e` stopped the script there. A "no match" is often normal, so write `count=$(grep -c nomatch file || true)`.

```bash
cat > /tmp/sete2.sh <<'EOF'
set -euo pipefail
echo "value: $UNDEFINED_VAR"
EOF
bash /tmp/sete2.sh; echo "script exit: $?"
```

Output:

```text
/tmp/sete2.sh: line 2: UNDEFINED_VAR: unbound variable
script exit: 1
```

An `ERR` trap reports where a script failed:

```bash
cat > /tmp/trap.sh <<'EOF'
set -e
trap 'echo "failed at line $LINENO with status $?" >&2' ERR
echo "step 1"
ls /nope
echo "step 2"
EOF
bash /tmp/trap.sh; echo "script exit: $?"
```

Output:

```text
step 1
ls: cannot access '/nope': No such file or directory
failed at line 4 with status 2
script exit: 2
```

| Option | Effect | Watch out for |
|---|---|---|
| `set -e` | Exit on an untested failure | Commands whose non-zero status is normal (`grep`, `diff`) |
| `set -u` | Error on unset variables | `${VAR:-}` for optional variables |
| `set -o pipefail` | A pipeline fails if any part fails | Early-exit readers such as `head` cause status 141 |
| `trap ... ERR` | Runs a handler on failure | Not inherited by functions without `set -E` |

---

## Setting a Status

A script returns the status of its last command unless `exit N` says otherwise; a function uses `return N`.

```bash
check_port() {
    ss -ltn "sport = :$1" | grep -q LISTEN || return 1
}
check_port 22 && echo "ssh listening"
```

---

## Common Errors

### `mkdir: cannot create directory '/tmp/ecdemo': File exists`

**Cause:** the directory already exists, so the command after `&&` does not run.

**Fix:** `mkdir -p` succeeds when the directory exists.

### `Killed`

**Cause:** the process received `SIGKILL` (status 137), often from the OOM killer.

**Fix:** `dmesg -T | grep -i -E 'killed process|out of memory'` or `journalctl -k` to confirm, then raise the limit or reduce memory use.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What do exit codes 0, 1, 126, 127 and 137 mean?"
    **Say first:** success, general failure, found but not executable, not found, and killed by `SIGKILL` (128 + 9).

    **Proof:** `nosuchcmd; echo $?` prints 127; `sleep 30 & kill -9 $!; wait $!; echo $?` prints 137.

    **Follow-up:** Where do you see 137 most often in DevOps work?

??? question "L1: What is the difference between ;, && and ||?"
    **Say first:** `;` always runs the next command, `&&` only after success, `||` only after failure.

    **Proof:** `mkdir /tmp/x && cd /tmp/x`; `mkdir /tmp/x || echo exists`.

    **Follow-up:** Why is `a && b || c` not a safe if-then-else?
<!-- --8<-- [end:l1] -->

??? question "L2: Stop a script at the first failure and report the failing line."
    **Say first:** strict mode plus an `ERR` trap.

    **Proof:**

    ```bash
    set -euo pipefail
    trap 'echo "failed at line $LINENO" >&2' ERR
    ```

    **Follow-up:** Which commands does `set -e` not stop on?

??? question "L2: Run a command with a 10-second limit and act on a timeout."
    **Say first:** `timeout` returns 124 when the limit is hit.

    **Proof:**

    ```bash
    timeout 10 curl -s http://localhost:8080/health; rc=$?
    [ "$rc" -eq 124 ] && echo "health check timed out"
    ```

    **Follow-up:** What does `timeout` send by default, and how do you escalate to `SIGKILL`? (`SIGTERM`; `-k 5`.)

??? question "L2: Read the status of each command in a pipeline."
    **Say first:** `PIPESTATUS` holds them all, until the next command runs.

    **Proof:** `false | true; echo "${PIPESTATUS[@]}"` prints `1 0`.

    **Follow-up:** How does `pipefail` change `$?`?

??? question "L3: A CI step fails with exit code 137, but the command has no error output."
    **Say first:** 137 is `SIGKILL`; look for the OOM killer or a runner timeout before debugging the command.

    **Proof:** `dmesg -T | grep -i oom` on the runner, or the container's `OOMKilled` state; runner logs for cancellation.

    **Follow-up:** How would you confirm memory use during the step? (`/usr/bin/time -v`, cgroup `memory.peak`.)

??? question "L3: A script with set -e exits silently in the middle."
    **Say first:** an untested command returned non-zero; find which one.

    **Proof:** `bash -x script.sh` shows the last command before exit; a `grep` or `diff` inside `$(...)` returning 1 is the usual cause.

    **Follow-up:** How do you keep `set -e` but allow that command to fail?

??? question "L3: kubectl reports a container exited with 127 right after start."
    **Say first:** the entrypoint or a command it runs was not found in the image.

    **Proof:** `kubectl logs <pod>` shows `sh: 1: app: not found` when the command runs through a shell; a missing entrypoint binary itself appears as `StartError` in `kubectl describe pod`.

    **Follow-up:** What does 126 mean in the same situation?

??? question "L4: How does a parent process learn a child's exit status?"
    **Say first:** the child calls `exit()`, the kernel keeps the status in the zombie process entry, and the parent collects it with `wait()`; signal deaths are encoded separately and the shell reports them as 128 + N.

    **Proof:** `strace -f -e trace=exit_group,wait4 bash -c 'sh -c "exit 3"; echo $?'`

    **Don't say:** "The exit code is written to a file."

---

## Related

- [Streams and Redirection](streams-and-redirection.md): pipes and `PIPESTATUS`
- [Command Resolution](command-resolution.md): why 126 and 127 happen
- [Scripting Essentials](scripting-essentials.md): `exit`, `return` and tests

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
