# Limits and File Descriptors

Resource limits cap how many files a process may open and how many processes a user may run, and hitting them produces `Too many open files` or `Resource temporarily unavailable`. The limits come from three layers, and fixing the wrong one leaves the error in place.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Soft vs hard | Soft is the enforced limit; hard is the ceiling a user may raise the soft to | `ulimit -Sn`, `ulimit -Hn` |
| Open files (`-n`) | Per-process file descriptor limit; default soft often 1024 | `ulimit -n` |
| `EMFILE` | `Too many open files`: this process hit its `-n` limit | `/proc/PID/limits` |
| `ENFILE` | System-wide file table full (rare); governed by `fs.file-max` | `sysctl fs.file-max` |
| `file-nr` | Allocated, unused, and max open file handles system-wide | `cat /proc/sys/fs/file-nr` |
| Processes (`-u`) | `RLIMIT_NPROC`: max processes per real user id | `ulimit -u` |
| `EAGAIN` on fork | `Resource temporarily unavailable`: hit `-u` or `pid_max` | `ulimit -u` |
| `pid_max` | System-wide ceiling on process ids | `cat /proc/sys/kernel/pid_max` |
| Shell limits | `ulimit` sets the calling shell and its children | `ulimit -a` |
| PAM limits | `/etc/security/limits.conf` and `limits.d` for login sessions | `man limits.conf` |
| systemd limits | `LimitNOFILE=`, `LimitNPROC=` in the unit; `ulimit` does not reach services | `systemctl show -p LimitNOFILE UNIT` |
| Live limits | A running process shows its effective limits | `cat /proc/PID/limits` |
<!-- --8<-- [end:facts] -->

---

## The Three Layers

A limit reaches a process through one of three paths, and they do not override each other. Interactive shells inherit from PAM (`limits.conf`), services inherit from systemd (`LimitNOFILE=`), and any process can lower its own soft limit with `ulimit`.

| Set for | Source | Applies to |
|---|---|---|
| **Login shells** | `/etc/security/limits.conf`, `limits.d/*` | interactive and cron logins |
| **systemd services** | `LimitNOFILE=`, `LimitNPROC=` in the unit or a drop-in | daemons started by systemd |
| **A shell and children** | `ulimit -n`, `ulimit -u` | the current shell only |

!!! warning "ulimit in a shell does not change a systemd service"
    A service started by systemd takes its limits from the unit, not from any shell. Raising `ulimit -n` in a terminal, or editing `limits.conf`, has no effect on `nginx.service`; set `LimitNOFILE=` in the unit instead.

---

## Reading Current Limits

`ulimit -a` shows the calling shell's limits, and `/proc/PID/limits` shows what a running process actually has, which is the value that matters during an incident.

```bash
ulimit -a | grep -Ei 'open files|processes'
ulimit -Sn; ulimit -Hn
cat /proc/1/limits | grep -E 'Max open files|Max processes'
```

Output:

```text
open files                          (-n) 1024
max user processes                  (-u) 3867
1024
524288
Max open files            1073741816           1073741816           files
Max processes             3867                 3867                 processes
```

The soft limit here is 1024 and the hard limit 524288, so a process may raise itself up to the hard ceiling without root. PID 1 (systemd) runs with a much higher file limit, which is why services can exceed a login shell's 1024.

!!! note "Read the live limit from /proc, not from your own shell"
    `ulimit -a` shows your shell's limits, which need not match a running service. During an incident, read `/proc/PID/limits` for the actual process, since that is what the kernel enforces on it.

---

## Too Many Open Files

When a process opens more descriptors than its soft `-n` allows, the next `open` fails with `EMFILE`. This is per-process, so the system-wide table is usually fine; `file-nr` confirms.

```bash
bash -c 'ulimit -n 12; exec python3 -c "
fs=[]
try:
    while True: fs.append(open(\"/etc/hostname\"))
except OSError as e: print(len(fs),\"opened, then:\",e)"'
cat /proc/sys/fs/file-nr
```

Output:

```text
9 opened, then: [Errno 24] Too many open files: '/etc/hostname'
736	0	9223372036854775807
```

With `-n` set to 12, only nine files opened before the limit, because stdin, stdout, stderr and the interpreter's own descriptors used the rest. The system table (`file-nr`) shows 736 handles against an effectively unlimited maximum, so the fault is the per-process limit, not the system.

---

## Raising the Limit

The fix depends on which layer applies. A leaking application that never closes descriptors needs a code fix, not a higher limit, but a legitimately busy service needs a real raise.

=== "RHEL / Rocky"

    ```bash
    # For a service: a drop-in, then reload and restart
    sudo systemctl edit nginx      # add [Service] LimitNOFILE=65536
    sudo systemctl restart nginx
    systemctl show nginx -p LimitNOFILE
    ```

=== "Ubuntu / Debian"

    ```bash
    # For login sessions: PAM limits
    echo '* soft nofile 65536' | sudo tee /etc/security/limits.d/nofile.conf
    echo '* hard nofile 65536' | sudo tee -a /etc/security/limits.d/nofile.conf
    # log out and back in, then: ulimit -n
    ```

The systemd manager also has `DefaultLimitNOFILE`, which sets the fallback for every unit that does not specify its own.

```bash
systemctl show -p DefaultLimitNOFILE
```

Output:

```text
DefaultLimitNOFILE=524288
```

---

## Process Limits and fork

`RLIMIT_NPROC` (`ulimit -u`) caps processes per real user id, and `pid_max` caps the system total. Hitting either makes `fork` fail with `EAGAIN`, seen as `Resource temporarily unavailable`.

```bash
bash -c 'ulimit -u 50; exec python3 -c "
import os,sys
try:
    while True:
        if os.fork()==0: os._exit(0)
except OSError as e: sys.stderr.write(str(e))"'
```

Output:

```text
[Errno 11] Resource temporarily unavailable
```

The same error at the shell reads `bash: fork: retry: Resource temporarily unavailable`. Because every fix normally needs a new process, recovery must use shell builtins, which run in the current shell, as [Cannot Fork](../interview/scenarios/cannot-fork.md) shows.

---

## Common Errors

### `Too many open files`

**Cause:** the process reached its soft `-n` limit, often through a descriptor leak or a genuinely high connection count.

**Fix:** count open descriptors with `ls /proc/PID/fd | wc -l`; raise `LimitNOFILE` (service) or `limits.conf` (login) if the count is legitimate, or fix the leak.

### `fork: retry: Resource temporarily unavailable`

**Cause:** the user hit `RLIMIT_NPROC`, or the system hit `pid_max`; no new process can start.

**Fix:** find the runaway with `ps -u USER --no-headers | wc -l`; raise `-u` or kill the offenders using shell builtins only.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a soft and a hard limit?"
    **Say first:** the soft limit is enforced now; the hard limit is the ceiling a process may raise its own soft limit to without root.

    **Proof:** `ulimit -Sn` and `ulimit -Hn` show both; a non-root process can set soft up to hard, not beyond.

    **Follow-up:** who can raise the hard limit? (root, or a unit's `LimitNOFILE`.)
<!-- --8<-- [end:l1] -->

??? question "L2: A service logs Too many open files. Walk through the fix."
    **Say first:** confirm it is the per-process limit, count the descriptors, then raise the unit's limit or fix the leak.

    **Proof:**

    ```bash
    cat /proc/$(pgrep -n svc)/limits | grep 'open files'
    ls /proc/$(pgrep -n svc)/fd | wc -l
    sudo systemctl edit svc      # LimitNOFILE=65536
    ```

    **Follow-up:** why did editing `limits.conf` not help this service? (systemd services ignore PAM limits.)

??? question "L2: You raised ulimit -n in your shell but the daemon still fails. Why?"
    **Say first:** the daemon is a systemd service and takes its limit from the unit, not from your shell.

    **Proof:** `systemctl show svc -p LimitNOFILE` shows the real value; set it with `LimitNOFILE=` and restart.

    **Follow-up:** where does the manager-wide default come from? (`DefaultLimitNOFILE`.)

??? question "L3: A box refuses new SSH sessions with resource temporarily unavailable. What is wrong?"
    **Say first:** a process or PID limit is exhausted, so `fork` fails and no new session can start.

    **Proof:** check `ulimit -u` and count the user's processes; `cat /proc/sys/kernel/pid_max` and `ps -eL | wc -l` for the system total.

    **Follow-up:** how do you investigate when you cannot even start a command? (shell builtins only: `echo /proc/*/`, `printf`, `read`.)

??? question "L4: Why does the file descriptor limit exist per process rather than only system-wide?"
    **Say first:** each descriptor consumes a kernel entry in the process table, and a per-process cap contains one runaway process without exhausting the whole system.

    **Proof:** `/proc/PID/limits` is per process; `fs.file-max` and `file-nr` are the system ceiling and current use.

    **Don't say:** that raising `fs.file-max` fixes a `Too many open files` error, which is almost always the per-process `-n`.

??? question "L4: Why is a file descriptor limit enforced per process rather than only system-wide?"
    **Say first:** each descriptor costs a kernel table entry, and a per-process cap contains one runaway process without letting it exhaust the whole system.

    **Proof:** `/proc/PID/limits` is per process; `fs.file-max` and `file-nr` are the system ceiling and current use.

    **Don't say:** that raising `fs.file-max` fixes a per-process `Too many open files`.

---

## Related

- [File Descriptors](../02-files-and-filesystem/file-descriptors.md): what a descriptor is and how it is inherited
- [Writing a Service](../08-systemd-and-services/writing-a-service.md): setting `LimitNOFILE=` and `LimitNPROC=`
- [PAM](../04-users-and-access/pam.md): `pam_limits` and `limits.conf`
- [Too Many Open Files](../interview/scenarios/too-many-open-files.md): the descriptor-exhaustion scenario
- [Cannot Fork](../interview/scenarios/cannot-fork.md): recovering with builtins when `fork` fails

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
