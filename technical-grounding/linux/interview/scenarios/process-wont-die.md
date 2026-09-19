# Process Won't Die

A process is still in `ps` after `kill`, or keeps coming back. Interviewers use this scenario because "use `kill -9`" is the expected wrong answer: the right answer depends on the process state, its owner and what supervises it.

---

## Symptom

> "We need to stop a stuck batch job on a server. We ran kill on it, and later kill -9, and it is still there. Other processes we kill come back with a new PID. What do you do?"

---

## Clarifying Questions

- **What exactly remains?** The same PID, or a new PID with the same name? A new PID means a supervisor restarted it.
- **What does `ps` show in `STAT`?** `Z` and `D` ignore signals for different reasons.
- **Who owns the process, and who ran `kill`?** A silent failure in a script may be `EPERM`.
- **Is anything else wrong?** A high load average or a hung `df` points to storage, not to the process.
- **Is it a service?** Services should be stopped through their manager, not by PID.

---

## Diagnostic Path

Five stuck workers on one host: a script that ignores `SIGTERM`, a parent with zombie children, a systemd service with `Restart=always`, jobs writing to a frozen filesystem, and a process owned by another user. The frozen-filesystem jobs and the other user's process were captured in a second run on the same host, so their PIDs are higher.

### 1. Check the State and Owner

```bash
kill 5514; sleep 1; ps -o pid,ppid,user,stat,etime,cmd -p 5514
ps -o pid,ppid,user,stat,cmd -p 5516 --ppid 5516
sudo ps -eo pid,ppid,user,stat,wchan:20,cmd | awk 'NR==1 || $4 ~ /^D/'
```

Output:

```text
    PID    PPID USER     STAT     ELAPSED CMD
   5514    5501 laborant S          00:04 /bin/bash ./ingest-worker
    PID    PPID USER     STAT CMD
   5516    5501 laborant S    python3 report-runner.py
   5520    5516 laborant Z    [python3] <defunct>
   5521    5516 laborant Z    [python3] <defunct>
   5522    5516 laborant Z    [python3] <defunct>
    PID    PPID USER     STAT WCHAN                CMD
   5770    5760 root     D    percpu_rwsem_wait    chmod 1777 /mnt/frz
   5771    5759 laborant D    percpu_rwsem_wait    export-job -c echo x >> /mnt/frz/export-22893.csv
   5772    5757 laborant D    percpu_rwsem_wait    export-job -c echo x >> /mnt/frz/export-14341.csv
   5773    5758 laborant D    percpu_rwsem_wait    export-job -c echo x >> /mnt/frz/export-6238.csv
```

| `STAT` | Meaning for `kill` |
|---|---|
| `S` or `R` after `kill` | The process ignores or handles `SIGTERM` |
| `Z` | Already dead; only the parent can remove it |
| `D` | Blocked in the kernel; signals wait until the call returns |
| `T` | Stopped; `SIGTERM` waits for `SIGCONT` |

### 2. Check What the Process Does with Signals

```bash
grep -E '^(State|PPid|SigIgn|SigCgt)' /proc/5514/status
python3 -c 'import signal; m=0x4000; print([signal.Signals(i).name for i in range(1,65) if m >> (i-1) & 1])'
```

Output:

```text
State:	S (sleeping)
PPid:	5501
SigIgn:	0000000000004006
SigCgt:	0000000000010000
['SIGTERM']
```

`SigIgn` includes bit 15 (`0x4000`): the script ran `trap '' TERM`. `SIGKILL` cannot be ignored, so here it is the right tool once the owner of the job agrees.

### 3. Check for a Supervisor

A process that returns with a new PID has a parent that restarts it. The cgroup names the unit.

```bash
sudo kill -9 5561; sleep 2; ps -o pid,ppid,stat,etime,cmd -C sleep | grep -E 'PID|infinity'
systemctl status queue-consumer --no-pager | sed -n '1,3p;/Main PID/p'; journalctl -u queue-consumer -o cat -n 2 --no-pager
systemctl show queue-consumer -p NRestarts -p Restart
```

Output:

```text
    PID    PPID STAT     ELAPSED CMD
   5600       1 Ss         00:00 /usr/bin/sleep infinity
● queue-consumer.service - Queue consumer
     Loaded: loaded (/etc/systemd/system/queue-consumer.service; static)
     Active: active (running) since Wed 2026-09-16 19:15:59 UTC; 2s ago
   Main PID: 5600 (sleep)
queue-consumer.service: Scheduled restart job, restart counter is at 1.
Started queue-consumer.service - Queue consumer.
Restart=always
NRestarts=1
```

`cat /proc/<pid>/cgroup` gives the unit name when it is not known. Other supervisors behave the same way: `supervisord`, a container runtime with a restart policy, a Kubernetes Deployment, or a cron job that restarts it.

### 4. Check Who Owns It

```bash
pgrep -af metrics-agent; kill $(pgrep -f metrics-agent)
```

Output:

```text
5958 sudo -u healthcheck bash -c exec -a metrics-agent sleep 3600
5962 metrics-agent 3600
pwd2.sh: line 2: kill: (5962) - Operation not permitted
```

`pgrep -f` matched the `sudo` wrapper (PID 5958), which exited before `kill` ran, and the agent itself (5962), which belongs to `healthcheck`. A script that discards `kill` errors would report success here.

### 5. Find What a D-State Process Waits For

```bash
cat /proc/loadavg
sudo kill -9 5772; sleep 1; ps -o pid,stat,cmd -p 5772
sudo cat /proc/5772/stack | head -4
findmnt -T /mnt/frz -o TARGET,SOURCE,FSTYPE,OPTIONS
```

Output:

```text
3.46 1.40 0.61 1/137 5927
    PID STAT CMD
   5772 D    export-job -c echo x >> /mnt/frz/export-14341.csv
[<0>] percpu_rwsem_wait+0x118/0x140
[<0>] mnt_want_write+0x98/0xc0
[<0>] open_last_lookups+0x2cb/0x3b0
[<0>] path_openat+0x8d/0x290
TARGET   SOURCE     FSTYPE OPTIONS
/mnt/frz /dev/loop0 ext4   rw,relatime
```

Four blocked tasks hold the load average near 4 with idle CPUs. The stack shows each one waiting for write access to `/mnt/frz`, which is frozen; on real servers the same pattern comes from a hung NFS server, a failing disk or a stalled storage path (`dmesg` shows I/O errors or `nfs: server ... not responding`).

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Signal ignored or handled slowly | `STAT` `S`; `SigIgn` or `SigCgt` has bit 15 | Ask the owner, then `kill -KILL`; fix the handler |
| Zombie | `STAT` `Z`, `<defunct>` | Signal or restart the parent; it reaps, or PID 1 does after the parent exits |
| Uninterruptible sleep | `STAT` `D`, `wchan` and `/proc/<pid>/stack` name the wait | Fix the device, mount or lock; unfreeze, restore NFS, `umount -f -l`; reboot as the last resort |
| Stopped | `STAT` `T` | `kill -CONT` after `kill -TERM`, or `kill -KILL` |
| Restarted by a supervisor | New PID, `PPID 1`, cgroup names a unit, `NRestarts` grows | `systemctl stop` (and `disable`) the unit |
| Not permitted | `kill: ... Operation not permitted` | Run as the owner or with `sudo` |

---

## Fix

```bash
kill -9 5514; sleep 0.5; ps -p 5514 || echo gone
sudo kill -9 $(ps -o pid= --ppid 5516); sleep 0.5; ps -o pid,stat,cmd --ppid 5516
kill 5516; sleep 0.5; ps -o pid,stat,cmd --ppid 5516 || echo 'zombies reaped by PID 1'
sudo systemctl stop queue-consumer; systemctl is-active queue-consumer; pgrep -af 'sleep infinity' || echo none
sudo pkill -f metrics-agent; pgrep -af metrics-agent || echo stopped
sudo fsfreeze -u /mnt/frz; sleep 1; ps -o pid,stat,cmd -p 5770,5771,5772,5773; echo rc=$?
ls /mnt/frz
```

Output:

```text
pwd.sh: line 2:  5514 Killed                  ./ingest-worker > /dev/null 2>&1
    PID TTY          TIME CMD
gone
    PID STAT CMD
   5520 Z    [python3] <defunct>
   5521 Z    [python3] <defunct>
   5522 Z    [python3] <defunct>
    PID STAT CMD
zombies reaped by PID 1
inactive
none
stopped
    PID STAT CMD
rc=1
export-22893.csv
export-6238.csv
export.csv
f
lost+found
```

`kill -9` on the zombies changed nothing; ending their parent did. After the thaw, all four blocked processes finished. `export-14341.csv` is missing because its writer (5772) received `SIGKILL` while blocked and died before it could open the file.

---

## Prevention

- Stop services through their manager (`systemctl stop`, `docker stop`, `kubectl delete pod`), never by PID.
- Handle `SIGTERM` in every long-running program and finish within the stop timeout; use `exec` in wrapper scripts so the application receives the signal.
- Reap children: call `waitpid()` or run an init such as `tini` (`docker run --init`) as PID 1 in containers.
- Keep `Restart=on-failure` with a start limit instead of `Restart=always` without one, and alert on `NRestarts`.
- Mount network filesystems with timeouts that suit the workload, and monitor for `D`-state processes and `hung_task` warnings in `dmesg`.
- Check the exit status of `kill` in scripts.

---

## Related

- [Process States](../../07-processes/process-states.md): `D`, `Z` and `T`
- [Signals](../../07-processes/signals.md): masks, `SIGKILL` and stop sequences
- [Process Lifecycle](../../07-processes/process-lifecycle.md): zombies and reaping
- [Unit Files](../../08-systemd-and-services/unit-files.md): `Restart=` and start limits

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
