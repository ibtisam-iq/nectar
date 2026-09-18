# Too Many Open Files

A service logs `Too many open files` and starts refusing work. The interviewer checks whether the candidate identifies the right limit layer, counts the descriptors, and separates a genuine load from a leak, rather than blindly raising a number.

---

## Symptom

> "The application is logging Too many open files and dropping connections. Fix it."

---

## Clarifying Questions

- **One process or the whole system?** `EMFILE` is per-process; `ENFILE` is the system table, which is rare.
- **Is the descriptor count growing without bound?** A steady climb is a leak; a high but stable count is real load.
- **A systemd service or a login shell?** The limit comes from the unit or from PAM, and the fix differs.
- **When did it start?** A traffic rise, or a deploy that stopped closing descriptors.

---

## Diagnostic Path

The service runs on `web` (Rocky Linux 10.2). File descriptors include open files, sockets and pipes, so a connection-heavy service can hold thousands.

### 1. Reproduce the Error

```bash
bash -c 'ulimit -n 12; exec python3 -c "
fs=[]
try:
    while True: fs.append(open(\"/etc/hostname\"))
except OSError as e: print(len(fs),\"opened, then:\",e)"'
```

Output:

```text
9 opened, then: [Errno 24] Too many open files: '/etc/hostname'
```

`[Errno 24]` is `EMFILE`, the per-process descriptor limit. With `-n` set to 12, only nine opened because standard streams and the interpreter used the rest.

### 2. Count the Descriptors and Read the Limit

```bash
FP=$(pgrep -n python3)
ls /proc/$FP/fd | wc -l
grep 'Max open files' /proc/$FP/limits
```

Output:

```text
403
Max open files            1024                 524288               files
```

The process holds 403 descriptors against a soft limit of 1024 and a hard limit of 524288. If the count sits near the soft limit and keeps climbing, the next step is to find what is not being closed.

### 3. Rule Out the System Table

```bash
cat /proc/sys/fs/file-nr
```

Output:

```text
1248	0	9223372036854775807
```

The system-wide table (`file-nr`) shows 1248 handles allocated against an effectively unlimited maximum, so this is the per-process limit, not `fs.file-max`. Raising `fs.file-max` would do nothing here.

### 4. Leak or Load

```bash
watch -n2 "ls /proc/$FP/fd | wc -l"        # climbing = leak
lsof -p $FP | awk '{print $5}' | sort | uniq -c | sort -rn | head
```

A count that only grows points at a descriptor leak in the application; a high but stable count under traffic is genuine load that needs a higher limit. `lsof` grouped by type shows whether sockets, regular files or pipes dominate.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Real load, limit too low | Stable high count near soft `-n` | Raise `LimitNOFILE` (service) or `limits.conf` (login) |
| Descriptor leak | Count climbs without bound | Fix the code to close descriptors |
| Wrong layer raised | `limits.conf` edited but service unchanged | Set `LimitNOFILE=` in the unit |
| System table full | `file-nr` near max (rare) | Raise `fs.file-max` |

---

## Fix

For genuine load on a systemd service, raise the unit's limit, since a service ignores shell `ulimit` and PAM limits.

```bash
sudo systemctl edit myapp        # add a [Service] block with LimitNOFILE=65536
sudo systemctl restart myapp
systemctl show myapp -p LimitNOFILE
cat /proc/$(pgrep -n myapp)/limits | grep 'open files'
```

For a leak, raising the limit only delays the failure; the code must close the descriptors it opens.

---

## Prevention

- Set `LimitNOFILE` deliberately for connection-heavy services, sized to peak load with headroom.
- Monitor `ls /proc/PID/fd | wc -l` against the soft limit and alert before it is reached.
- Review code paths that open files or sockets in a loop to confirm they close on every path, including errors.

---

## Related

- [Limits and File Descriptors](../../17-performance-and-troubleshooting/limits-and-file-descriptors.md): the three limit layers in full
- [File Descriptors](../../02-files-and-filesystem/file-descriptors.md): what a descriptor is
- [Writing a Service](../../08-systemd-and-services/writing-a-service.md): setting `LimitNOFILE=`
- [Cannot Fork](cannot-fork.md): the sibling case for the process limit

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
