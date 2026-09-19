# Finding Files

`find` walks a directory tree and selects files by name, type, size, time, owner or permissions, then prints them or runs a command on each. It is the standard tool for cleanups, audits and "where did the disk go" questions; `locate` answers name lookups faster from a prebuilt index.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Syntax | `find <paths> <tests> <actions>`; default action `-print` | `find /etc -name '*.conf'` |
| Quote patterns | Otherwise the shell expands them first | `find . -name '*.log'` |
| Size units | `-size +100M`, `-size -10k`; `+` more than, `-` less than | `find / -xdev -size +1G` |
| Time tests | `-mtime +30` older than 30 days; `-mmin -60` newer than an hour | `find /var/log -mtime +30` |
| Permission tests | `-perm 644` exact, `-perm -4000` all bits set, `-perm /022` any bit set | `find / -perm -4000` |
| Owner tests | `-user`, `-group`, `-nouser`, `-nogroup` | `find / -nouser` |
| Run a command | `-exec cmd {} \;` once per file; `-exec cmd {} +` batched | `find . -exec ls {} +` |
| Safe with `xargs` | `-print0` and `xargs -0` handle spaces and newlines | `find . -print0` |
| Delete | `-delete`; put it last | `find /tmp -name '*.tmp' -delete` |
| Stay on one filesystem | `-xdev` | `find / -xdev` |
| Depth | `-maxdepth N`, `-mindepth N` | `find . -maxdepth 1` |
| Name index | `locate` searches the database built by `updatedb` | `locate sshd_config` |
| Command location | `which` searches `PATH`; `whereis` adds man pages | `whereis sshd` |
<!-- --8<-- [end:facts] -->

---

## Test Setup

The examples run against a small tree: a 120 MB log, a 5 MB log dated 40 days ago, two config files (one with a space in its name), and two temporary files, one of them world-writable.

```bash
mkdir -p /tmp/fdemo/{logs,conf,cache} && cd /tmp/fdemo
dd if=/dev/zero of=logs/app.log bs=1M count=120 status=none
dd if=/dev/zero of=logs/old.log bs=1M count=5 status=none
touch -d '40 days ago' logs/old.log
echo "port=8080" > conf/app.conf
echo "port=9090" > "conf/web server.conf"
touch -d '3 days ago' conf/app.conf
touch cache/a.tmp cache/b.tmp
chmod 777 cache/a.tmp
```

---

## By Name, Size and Time

```bash
find /tmp/fdemo -name '*.conf'
find /tmp/fdemo -iname 'APP*'
find /tmp/fdemo -type f -size +100M
find /tmp/fdemo -type f -size +1M -size -10M
find /tmp/fdemo -type f -mtime +30
find /tmp/fdemo -type f -mtime -7 -name '*.conf'
find /tmp/fdemo -type f -mmin -60 -name '*.tmp'
```

Output:

```text
/tmp/fdemo/conf/web server.conf
/tmp/fdemo/conf/app.conf
/tmp/fdemo/conf/app.conf
/tmp/fdemo/logs/app.log
/tmp/fdemo/logs/app.log
/tmp/fdemo/logs/old.log
/tmp/fdemo/logs/old.log
/tmp/fdemo/conf/web server.conf
/tmp/fdemo/conf/app.conf
/tmp/fdemo/cache/b.tmp
/tmp/fdemo/cache/a.tmp
```

Several tests in a row are combined with AND; `-o` means OR and `!` negates.

| Test | Meaning |
|---|---|
| `-mtime +30` | Modified more than 30 full days ago |
| `-mtime -7` | Modified within the last 7 days |
| `-mtime 0` | Modified in the last 24 hours |
| `-mmin -60` | Modified within the last 60 minutes |
| `-newer ref` | Modified more recently than `ref` |
| `-size +100M` | Larger than 100 MiB (`c` bytes, `k`, `M`, `G`) |
| `-empty` | Empty files and directories |

!!! warning "-size rounds up to the unit"
    `-size -1M` matches only empty files, because every non-empty file rounds up to at least 1 MiB. Use `-size -1024k` for "smaller than 1 MiB".

---

## By Permission and Owner

```bash
find /tmp/fdemo -type f -perm -o=w
find /tmp/fdemo -type f -perm 777
sudo find / -xdev -type f -perm -4000 2>/dev/null | head -5
```

Output:

```text
/tmp/fdemo/cache/a.tmp
/tmp/fdemo/cache/a.tmp
/usr/sbin/pam_timestamp_check
/usr/sbin/userhelper
/usr/sbin/unix_chkpwd
/usr/bin/chage
/usr/bin/newgrp
```

`-perm -4000` finds SUID binaries, a standard step in a privilege-escalation audit. `-nouser` finds files whose UID no longer exists, which is what deleting a user without `-r` leaves behind.

---

## Acting on Results

`-exec ... \;` runs the command once per file; `-exec ... +` passes many files to one command, like `xargs`:

```bash
find /tmp/fdemo -type f -name '*.conf' -exec grep -H port {} \;
find /tmp/fdemo -type f -name '*.conf' -exec grep -H port {} +
find /tmp/fdemo -name '*.conf' | xargs grep -H port
find /tmp/fdemo -name '*.conf' -print0 | xargs -0 grep -H port
```

Output:

```text
/tmp/fdemo/conf/web server.conf:port=9090
/tmp/fdemo/conf/app.conf:port=8080
/tmp/fdemo/conf/web server.conf:port=9090
/tmp/fdemo/conf/app.conf:port=8080
grep: /tmp/fdemo/conf/web: No such file or directory
grep: server.conf: No such file or directory
/tmp/fdemo/conf/app.conf:port=8080
/tmp/fdemo/conf/web server.conf:port=9090
/tmp/fdemo/conf/app.conf:port=8080
```

Plain `xargs` split `web server.conf` into two names. `-print0` with `xargs -0` separates names with a NUL byte, which cannot appear in a file name.

```bash
find /tmp/fdemo -name '*.tmp' -delete
find /tmp/fdemo -name '*.tmp' | wc -l
find /tmp/fdemo -type f -printf '%s\t%TY-%Tm-%Td\t%p\n' | sort -rn
find /tmp/fdemo -type f -name '*.log' -mtime +30 -ls
```

Output:

```text
0
125829120	2026-09-16	/tmp/fdemo/logs/app.log
5242880	2026-08-07	/tmp/fdemo/logs/old.log
10	2026-09-16	/tmp/fdemo/conf/web server.conf
10	2026-09-13	/tmp/fdemo/conf/app.conf
   128896   5120 -rw-r--r--   1 laborant laborant  5242880 Aug  7 14:00 /tmp/fdemo/logs/old.log
```

!!! danger "Test before -delete"
    Run the same `find` with `-print` first and read the list. `-delete` placed before a test (`find . -delete -name '*.tmp'`) deletes everything, because actions run in order.

---

## Limiting the Search

```bash
find /tmp/fdemo -maxdepth 1 -type d
find /tmp/fdemo -path '*/logs' -prune -o -type f -print
find / -xdev -name sshd_config 2>/dev/null
find /root -name x
```

Output:

```text
/tmp/fdemo
/tmp/fdemo/conf
/tmp/fdemo/cache
/tmp/fdemo/logs
/tmp/fdemo/conf/web server.conf
/tmp/fdemo/conf/app.conf
/etc/ssh/sshd_config
find: ‘/root’: Permission denied
```

`-prune` skips the `logs` directory; the explicit `-print` is required so the pruned directory itself is not printed. `-xdev` keeps `find /` off `/proc`, `/sys` and network mounts, and `2>/dev/null` hides "Permission denied" noise when not running as root.

---

## locate, which and whereis

```bash
sudo updatedb
locate sshd_config
which sshd
whereis sshd
```

Output:

```text
/etc/ssh/sshd_config
/etc/ssh/sshd_config.d
/usr/sbin/sshd
sshd: /usr/sbin/sshd
```

`locate` (from `plocate` on RHEL 10 and Ubuntu 24.04) reads an index refreshed daily by a timer, so files created since the last `updatedb` are missing and deleted files still appear. It also hides files the caller cannot read.

---

## Common Errors

### `find: ‘/root’: Permission denied`

**Cause:** the user cannot read that directory; `find` reports it and continues.

**Fix:** use `sudo`, or add `2>/dev/null` when the directory is irrelevant.

### ``find: paths must precede expression: `old.log'``

**Cause:** an unquoted pattern such as `-name *.log` was expanded by the shell into several file names. Recent `find` adds `possible unquoted pattern after predicate '-name'?`.

**Fix:** quote the pattern: `-name '*.log'`.

### ``find: missing argument to `-exec'``

**Cause:** the command after `-exec` is not terminated with `\;` or `+`.

**Fix:** end it with `{} \;` or `{} +`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between -exec {} \; and -exec {} +?"
    **Say first:** `\;` runs the command once per file; `+` appends as many files as fit and runs the command a few times, which is much faster.

    **Proof:** `find /etc -name '*.conf' -exec ls {} +`

    **Follow-up:** When must you use `\;`? (When the command accepts only one file, or `{}` is not last.)

??? question "L1: What is the difference between find and locate?"
    **Say first:** `find` walks the filesystem live and can test any attribute; `locate` searches a name index built by `updatedb`, which is fast but can be stale.

    **Proof:** `touch /tmp/new-file; locate new-file` finds nothing until `sudo updatedb`.

    **Follow-up:** Why can `locate` hide files that exist?
<!-- --8<-- [end:l1] -->

??? question "L2: Find files larger than 1 GiB on the root filesystem, largest first."
    **Say first:** size test, stay on one filesystem, print sizes and sort.

    **Proof:**

    ```bash
    sudo find / -xdev -type f -size +1G -printf '%s %p\n' 2>/dev/null | sort -rn | head
    ```

    **Follow-up:** Why `-xdev`?

??? question "L2: Delete log files older than 30 days under /var/log/app."
    **Say first:** preview, then delete.

    **Proof:**

    ```bash
    find /var/log/app -type f -name '*.log' -mtime +30 -print
    find /var/log/app -type f -name '*.log' -mtime +30 -delete
    ```

    **Follow-up:** Which tool normally handles this instead? (`logrotate` with `maxage` or `rotate`.)

??? question "L2: List every SUID and SGID file on the system."
    **Say first:** permission test with the `/` (any bit) form.

    **Proof:** `sudo find / -xdev -type f -perm /6000 -ls 2>/dev/null`

    **Follow-up:** Why is an unexpected SUID binary a security finding?

??? question "L2: Change the group of every file owned by a deleted user's old UID."
    **Say first:** search by numeric UID and act in batches.

    **Proof:** `sudo find / -xdev -uid 1002 -exec chown amor: {} +`

    **Follow-up:** How do you find all files with no valid owner at all? (`-nouser`.)

??? question "L3: A cleanup script using find and xargs fails on some files and deletes the wrong ones."
    **Say first:** check for names with spaces or newlines being split.

    **Proof:** `find ... | xargs rm` splits `web server.conf` into `web` and `server.conf`; `-print0 | xargs -0` or `-delete` fixes it.

    **Follow-up:** What else can go wrong with `xargs rm`? (Names starting with `-`; use `xargs -0 rm --`.)

??? question "L3: The disk filled up in the last hour. Find what grew."
    **Say first:** look for recently modified large files on the affected filesystem.

    **Proof:** `sudo find / -xdev -type f -mmin -60 -size +100M -ls`

    **Follow-up:** What if `find` shows nothing but `df` keeps growing? (A deleted file held open: `lsof +L1`.)

---

## Related

- [Inodes and Links](inodes-and-links.md): timestamps that `-mtime` and `-ctime` test
- [Quoting and Expansion](../01-shell-and-cli/quoting-and-expansion.md): why patterns must be quoted
- [Users](../04-users-and-access/users.md): orphaned files after deleting a user
- [Navigation and Listing](navigation-and-listing.md): browsing instead of searching

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
