# Disk Full

An application fails with `No space left on device`. The interviewer checks whether the candidate looks at both blocks and inodes, notices when `df` and `du` disagree, and frees space without deleting files that a process still holds open.

---

## Symptom

> "The shop API returns errors and its log says No space left on device. Someone already deleted the big log file, but the disk is still full. What do you do?"

---

## Clarifying Questions

- **Which filesystem?** The path in the error decides which mount to check; `/var`, `/`, and a data volume behave the same but have different owners.
- **Blocks or inodes?** The error text is identical for both.
- **What was deleted, and by whom?** A deleted file that a process keeps open frees nothing.
- **Is it still growing?** A runaway writer fills the disk again minutes after a cleanup.
- **Is the service still running, and can it be restarted?** That decides whether to truncate through `/proc` or restart.

---

## Diagnostic Path

The service `shop-api` runs as `laborant` on Rocky Linux 10.2, writes its log to `/srv/shop/log/api.log` and creates one session file per request in `/srv/shop/sessions`. `/srv/shop` is a 150 MiB ext4 logical volume with 8208 inodes, sized small so the incident can be reproduced; the log file was removed with `rm` while the service was running.

### 1. Confirm the Error and Check Blocks and Inodes

```bash
systemctl is-active shop-api
journalctl -u shop-api --since -1min --no-pager -o cat | sed 's/sess_[0-9a-f]*/sess_.../' | sort | uniq -c
df -h /srv/shop; df -i /srv/shop
```

Output:

```text
active
    564 log write failed: [Errno 28] No space left on device
    382 session write failed: [Errno 28] No space left on device
    181 session write failed: [Errno 28] No space left on device: '/srv/shop/sessions/sess_...'
Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/vgdata-shop  145M  134M     0 100% /srv/shop
Filesystem              Inodes IUsed IFree IUse% Mounted on
/dev/mapper/vgdata-shop   8208  1783  6425   22% /srv/shop
```

Errno 28 is `ENOSPC`. The blocks are exhausted and the inodes are not, so the next question is what holds 134 MiB.

### 2. Compare df with du

```bash
sudo du -xh --max-depth=1 /srv/shop | sort -h
ls -la /srv/shop/log
```

Output:

```text
1.0K	/srv/shop/log
12K	/srv/shop/lost+found
1.5M	/srv/shop
1.5M	/srv/shop/sessions
total 2
drwxr-xr-x 2 laborant laborant 1024 Sep 17 08:01 .
drwxr-xr-x 5 root     root     1024 Sep 17 07:59 ..
```

`du` finds 1.5 MiB, while `df` reports 134 MiB used, and the log directory is empty: the log has no name left.

### 3. Find Deleted Files That Are Still Open

```bash
sudo lsof -a +L1 /srv/shop
systemctl show -p MainPID shop-api
```

Output:

```text
COMMAND   PID     USER   FD   TYPE DEVICE  SIZE/OFF NLINK NODE NAME
python3 10486 laborant    3w   REG  252,4 138764288     0   14 /srv/shop/log/api.log (deleted)
MainPID=10486
```

The service's main process still holds the deleted 132 MiB log on descriptor 3. Two fixes free it: truncate it through `/proc/10486/fd/3`, or restart the service so it closes the old file and opens a new one.

### 4. Free the Space and Watch the Growth

```bash
sudo systemctl restart shop-api
df -h /srv/shop | tail -1
sleep 10; ls -lh /srv/shop/log/api.log; df -h /srv/shop | tail -1
sleep 10; ls -lh /srv/shop/log/api.log
tail -c 300 /srv/shop/log/api.log | cut -c1-60
grep -c DEBUG /srv/shop/log/api.log
```

Output:

```text
/dev/mapper/vgdata-shop  145M  1.5M  133M   2% /srv/shop
-rw-r--r-- 1 laborant laborant 19M Sep 17 08:01 /srv/shop/log/api.log
/dev/mapper/vgdata-shop  145M   21M  114M  16% /srv/shop
-rw-r--r-- 1 laborant laborant 38M Sep 17 08:01 /srv/shop/log/api.log
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
08:01:53 INFO GET /orders 200
396
```

The restart freed 132 MiB at once, but the new log grows by about 2 MiB per second: the service logs 100 KB debug dumps with every request. At that rate the volume fills again within a minute.

### 5. Stop the Runaway Log

The service reads `LOG_LEVEL` from its environment, so a drop-in sets it to `info`:

```bash
sudo mkdir -p /etc/systemd/system/shop-api.service.d
printf '[Service]\nEnvironment=LOG_LEVEL=info\n' | sudo tee /etc/systemd/system/shop-api.service.d/10-loglevel.conf
sudo systemctl daemon-reload && sudo systemctl restart shop-api
: > /srv/shop/log/api.log
sleep 10; ls -lh /srv/shop/log/api.log; tail -2 /srv/shop/log/api.log
df -h /srv/shop | tail -1
```

Output:

```text
[Service]
Environment=LOG_LEVEL=info
-rw-r--r-- 1 laborant laborant 5.9K Sep 17 08:02 /srv/shop/log/api.log
08:02:03 INFO GET /orders 200
08:02:03 INFO GET /orders 200
/dev/mapper/vgdata-shop  145M  2.2M  132M   2% /srv/shop
```

`: >` emptied the debug-filled log in place, which is safe while the process has it open.

### 6. The Same Error Returns with Free Space

A few minutes later, the service fails again:

```bash
journalctl -u shop-api --since -1min --no-pager -o cat | sed 's/sess_[0-9a-f]*/sess_.../' | sort | uniq -c
df -h /srv/shop; df -i /srv/shop
sudo find /srv/shop -xdev -type f | cut -d/ -f1-4 | sort | uniq -c | sort -n | tail -3
ls -ld /srv/shop/sessions
```

Output:

```text
    644 session write failed: [Errno 28] No space left on device: '/srv/shop/sessions/sess_...'
Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/vgdata-shop  145M  8.4M  126M   7% /srv/shop
Filesystem              Inodes IUsed IFree IUse% Mounted on
/dev/mapper/vgdata-shop   8208  8208     0  100% /srv/shop
      1 /srv/shop/log
   8194 /srv/shop/sessions
drwxr-xr-x 2 laborant laborant 584704 Sep 17 08:06 /srv/shop/sessions
```

The blocks are 7% used and every inode is taken, almost all by session files that are never cleaned up. The directory file itself has grown to 571 KiB, which slows every lookup in it.

### 7. Clean Up and Prevent a Repeat

```bash
sudo find /srv/shop/sessions -type f -mmin +3 -delete
df -i /srv/shop | tail -1
printf 'd /srv/shop/sessions 0755 laborant laborant 30m\n' | sudo tee /etc/tmpfiles.d/shop-sessions.conf
sudo systemd-tmpfiles --clean /etc/tmpfiles.d/shop-sessions.conf
systemctl list-timers systemd-tmpfiles-clean.timer --no-pager | head -2
```

Output:

```text
/dev/mapper/vgdata-shop   8208  2952  5256   36% /srv/shop
d /srv/shop/sessions 0755 laborant laborant 30m
NEXT                        LEFT LAST                           PASSED UNIT                         ACTIVATES
Fri 2026-09-18 07:40:09 UTC  23h Thu 2026-09-17 07:40:09 UTC 27min ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
```

`find -delete` removed the sessions older than three minutes without building a huge argument list. The `tmpfiles.d` rule makes the daily `systemd-tmpfiles-clean.timer` delete sessions older than 30 minutes; nothing was old enough on the first manual run.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Real data growth | `du -xh --max-depth=1` finds the directory; `df` and `du` agree | Delete, archive or move data; grow the volume |
| Deleted file still open | `df` far above `du`; `lsof -a +L1` shows `(deleted)` | Restart or signal the process, or `: > /proc/<pid>/fd/<fd>` |
| Runaway log | One file grows by megabytes between two `ls -lh` runs | Lower the log level; `logrotate` with size limits |
| Inodes exhausted | `df -i` at 100%, `df -h` low | Delete small files with `find -delete`; `tmpfiles.d` or cron cleanup; recreate ext4 with more inodes |
| Files under a mount point | `du` of a bind mount of `/` shows data under the mount directory | Unmount or bind-mount, move the files |
| Reserved blocks | `Avail 0` while `Used` is below `Size`; root processes still write | Free space; `tune2fs -m 1` on data volumes |
| Quota | `Disk quota exceeded`, or a full quota with a free filesystem | `quota -s <user>`; raise or clean |
| Journal or package caches | `journalctl --disk-usage`; `/var/cache/dnf`, `/var/cache/apt` | `journalctl --vacuum-size=`, `dnf clean all`, `apt-get clean` |
| Container data | `/var/lib/docker` or `/var/lib/containerd` grows | `docker system df`, `docker system prune`; image and log limits |

---

## Fix

Free space in a way that is safe for running processes: truncate or rotate open files, restart only the service that holds a deleted file, and delete old data by age. Then remove the cause (log level, missing cleanup), and only after that consider growing the volume.

---

## Prevention

- Alert on both `df` and `df -i` well before 100%, for example at 80% and 90%.
- Rotate logs by size as well as time, and never `rm` an active log.
- Give every temporary or session directory an age-based cleanup (`tmpfiles.d`, a timer or the application's own expiry).
- Keep `/var`, `/var/log` and application data on separate volumes so one runaway writer cannot fill `/`.
- Cap the journal with `SystemMaxUse=` and container logs with the runtime's log options.

---

## Related

- [Disk Usage](../../12-storage/disk-usage.md): `df`, `du`, inodes and deleted open files
- [logrotate](../../09-logging/logrotate.md): `copytruncate` versus reopening
- [Inodes and Links](../../02-files-and-filesystem/inodes-and-links.md): why an unlinked file can stay allocated
- [Viewing Processes](../../07-processes/viewing-processes.md): finding the process behind a PID
- [Resizing and Cloud Disks](../../12-storage/resizing-and-cloud-disks.md): growing the volume when the data is legitimate

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
