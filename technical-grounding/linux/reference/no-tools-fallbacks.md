# No-Tools Fallbacks

When a box is broken you may not be able to run the usual tools: the disk is full, `fork` fails with `Resource temporarily unavailable`, or a minimal container has no `ps`, `ss` or `ip`. Shell built-ins and `/proc` still work, because they need no new process and no extra binary.

---

## Why Built-ins Survive When Binaries Do Not

Running `ls`, `ps` or `ss` requires the shell to `fork` and `exec` a separate program, which fails when the process table is full or memory is exhausted. A shell built-in such as `echo`, `cd`, `read` or `printf` runs inside the current shell with no new process. Reading `/proc` and `/sys` is a file read, so it needs no package and works in the emptiest container.

!!! warning "In a fork bomb, start with a shell that is already running"
    Once `fork` fails, you cannot launch a new shell or any external command, so open a session before the limit is hit or use one already open. From there, built-ins and redirection are the only reliable tools until you free process slots. See [Cannot Fork](../interview/scenarios/cannot-fork.md).

---

## Command to Fallback

| Instead of | Use | Reads |
|---|---|---|
| `ls` | `echo *` | Shell glob expansion, no `ls` binary |
| `cat file` | `while read -r l; do echo "$l"; done < file` | Built-in `read` |
| `ps aux` | `for p in /proc/[0-9]*; do echo "$p $(cat $p/comm)"; done` | `/proc/PID/comm`, `/proc/PID/status` |
| `ss -tulpn` | `cat /proc/net/tcp /proc/net/udp` | Kernel socket tables (hex address and port) |
| `ip addr` | `cat /proc/net/fib_trie`, `ls /sys/class/net` | Kernel network state |
| `nc host port` | `exec 3<>/dev/tcp/host/port` | Bash `/dev/tcp` pseudo-device |
| `free` | `cat /proc/meminfo` | Kernel memory counters |
| `uptime`, load | `cat /proc/loadavg` | Kernel load figures |
| `df` (roughly) | `cat /proc/mounts`, `stat -f /` | Mount table and `statfs` |
| `which cmd` | `type cmd` | Shell built-in |
| `find` (recursive) | `for f in **/*; do ...; done` with `shopt -s globstar` | Shell globbing |

---

## Reading Process State from /proc

Each running process has a directory `/proc/PID`. The `status` file holds the name, state, parent PID and memory; `cmdline` holds the full command with NUL separators; `fd/` lists open file descriptors.

```bash
# Name, state and parent of a process without ps
cat /proc/1592/status | grep -E '^(Name|State|PPid|VmRSS):'

# Full command line (NUL-separated, so translate to spaces)
tr '\0' ' ' < /proc/1592/cmdline; echo

# What files and sockets a process has open, without lsof
ls -l /proc/1592/fd
```

A zombie shows `State: Z (zombie)` in `status`, and a process stuck on I/O shows `State: D (disk sleep)`. See [Process States](../07-processes/process-states.md) and [File Descriptors](../02-files-and-filesystem/file-descriptors.md).

---

## Testing a Port Without nc or curl

Bash opens TCP connections through the `/dev/tcp/HOST/PORT` pseudo-device, so a connection test needs no `nc`, `telnet` or `curl`.

```bash
# Succeeds silently if the port is open, errors if refused or filtered
timeout 2 bash -c 'exec 3<>/dev/tcp/10.0.0.5/443' && echo open || echo closed

# Send a minimal HTTP request and read the reply
exec 3<>/dev/tcp/example.com/80
printf 'GET / HTTP/1.0\r\nHost: example.com\r\n\r\n' >&3
cat <&3
```

The `/proc/net/tcp` table lists local and remote addresses in hex, with the connection state in the `st` column (`0A` is `LISTEN`, `01` is `ESTABLISHED`). See [Ports and Sockets](../13-networking/ports-and-sockets.md) and [Sockets and TCP States](../13-networking/sockets-and-tcp-states.md).

---

## Freeing Space When the Disk Is Full

When `/` is full, even writing a file to see the error can fail, so truncate a known-large file in place rather than deleting and recreating it. A deleted-but-open log still holds its blocks until the writer closes it, so truncating through `/proc` frees the space at once.

```bash
# Truncate a runaway log without a new process
: > /var/log/huge.log

# Free a deleted-but-open file by its descriptor
: > /proc/$(pgrep -n writer)/fd/3
```

`: >` is the built-in null command with a redirection, which opens the file for writing and truncates it, using no external binary. See [Disk Usage](../12-storage/disk-usage.md) and [Disk Full](../interview/scenarios/disk-full.md).

---

## Related

- [Cannot Fork](../interview/scenarios/cannot-fork.md): the scenario these fallbacks were written for
- [proc and sys](../11-kernel-and-hardware/proc-and-sys.md): what else lives under `/proc`
- [Command Index](command-index.md): the full-featured tools these stand in for
