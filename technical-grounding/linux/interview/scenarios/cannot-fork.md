# Cannot Fork

The shell reports `fork: retry: Resource temporarily unavailable`, and ordinary commands fail. The interviewer checks whether the candidate realises external commands cannot run, switches to shell builtins to investigate, and finds the process or limit at fault.

---

## Symptom

> "I can't run anything on this box. Every command says fork: retry: Resource temporarily unavailable. Recover it without rebooting."

---

## Clarifying Questions

- **One user or the whole system?** `RLIMIT_NPROC` is per user; `pid_max` is system-wide.
- **Did it start after a deploy or a job?** A runaway fork loop or a thread leak is the usual trigger.
- **Is this a container?** A `pids.max` cgroup limit produces the same error inside one.
- **Do you have a root shell already open?** An existing shell can use builtins even when new processes cannot start.

---

## Diagnostic Path

The trap in this scenario is that the fix itself needs new processes. `ls`, `ps`, `kill` (the binary) and `cat` all `fork` and `exec`, so they fail with the same error; only shell builtins, which run in the current process, still work.

### 1. Confirm the Failure

```bash
sleep 1 &
```

Output:

```text
bash: fork: retry: Resource temporarily unavailable
```

`EAGAIN` on `fork` means the process or thread limit is exhausted. A program hitting it directly reports the errno.

Output:

```text
[Errno 11] Resource temporarily unavailable
```

### 2. Investigate with Builtins Only

External commands fail, so use globbing and redirection, which the shell handles without forking. `type` confirms which tools are builtins.

```bash
type ls kill ulimit
set -- /proc/[0-9]*/; echo "process dirs: $#"
read -r line < /proc/loadavg; echo "loadavg: $line"
```

Output:

```text
ls is /usr/bin/ls
kill is a shell builtin
ulimit is a shell builtin
process dirs: 93
loadavg: 0.00 0.00 0.00 1/106 6490
```

`ls` is an external binary and would fail, but `kill` and `ulimit` are builtins that still work. The glob `/proc/[0-9]*/` counts processes, and `read < file` reads `/proc` without `cat`.

### 3. Find the Offender and the Limit

```bash
ulimit -u                                   # this user's process limit
for p in /proc/[0-9]*; do read -r c < "$p/comm"; echo "$c"; done | sort | uniq -c | sort -rn | head
```

The `ulimit -u` builtin shows the per-user cap, and the loop tallies process names from `/proc/*/comm` using only builtins. A single command with hundreds of instances is the runaway; a normal spread means the limit is set too low for the workload.

### 4. Kill Without Forking

```bash
for p in /proc/[0-9]*; do
  read -r c < "$p/comm"
  [ "$c" = "runaway" ] && kill "${p#/proc/}"     # kill is a builtin
done
```

`kill` is a shell builtin, so it works when `/bin/kill` cannot start. Sending `SIGTERM` to the offenders frees process slots, after which normal commands run again.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Per-user process limit | `ulimit -u` low, many processes for one user | Kill the runaway; raise `-u` if load is real |
| Fork or thread leak | One command with hundreds of instances | Kill it, then fix the code |
| System `pid_max` | Total processes near `pid_max` | Kill offenders; raise `kernel.pid_max` |
| cgroup `pids.max` | Inside a container, its own limit hit | Raise the container's pids limit |

---

## Fix

Free slots first with builtins, then address the cause. Once processes can start again, confirm the limit against the real need.

```bash
# after killing the runaway with the builtin kill:
ulimit -u                                   # check the current cap
# raise per-user limit for a legitimate workload:
echo '* soft nproc 8192' | sudo tee /etc/security/limits.d/nproc.conf
```

For a systemd service, set `LimitNPROC=` in the unit rather than `limits.conf`, since services ignore PAM limits.

---

## Prevention

- Set `LimitNPROC` (or a cgroup `pids.max`) on services that spawn workers, so one cannot exhaust the host.
- Alert when a user's process count or the system total approaches its limit.
- Fix fork and thread leaks in code; a higher limit only delays the next exhaustion.

---

## Related

- [Limits and File Descriptors](../../17-performance-and-troubleshooting/limits-and-file-descriptors.md): `RLIMIT_NPROC`, `pid_max` and the layers
- [Process Fundamentals](../../07-processes/process-fundamentals.md): what `fork` does
- [Too Many Open Files](too-many-open-files.md): the sibling case for descriptors

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The `fork` failure was reproduced under a lowered `ulimit -u`.
