# Navigation and Listing

`cd`, `pwd` and `ls` are the most-typed commands on any server. The details worth knowing are the flags for sorting and sizes, and how symlinked directories change what `pwd` reports.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Absolute path | Starts at `/` | `cd /etc/ssh` |
| Relative path | Starts at the current directory; `.` current, `..` parent | `cd ../log` |
| Home | `cd`, `cd ~`; another user's home is `~user` | `echo ~root` |
| Previous directory | `cd -` (prints it); `$OLDPWD` holds it | `echo $OLDPWD` |
| Logical vs physical path | `pwd` keeps symlink names; `pwd -P` resolves them | `pwd -P` |
| Hidden files | Names starting with `.`; shown by `ls -a` | `ls -a ~` |
| Newest last | `ls -ltr` | `ls -ltr /var/log` |
| Largest first | `ls -lS` | `ls -lhS` |
| Directory itself, not contents | `ls -ld <dir>` | `ls -ld /tmp` |
<!-- --8<-- [end:facts] -->

---

## Moving Around

```bash
cd /etc/ssh
pwd
cd -
cd ~-
cd ..
pwd
cd
pwd
```

Output:

```text
/etc/ssh
/home/laborant
/etc
/home/laborant
```

`cd -` returns to the previous directory and prints it; `~-` expands to `$OLDPWD` without printing. With a symlinked directory, `pwd` keeps the link name, `pwd -P` and `cd -P` resolve it.

---

## Listing

In a directory with three sample files, one of them dated January:

```bash
ls -lh
ls -ltr
```

Output:

```text
total 12K
-rw-rw-r-- 1 laborant laborant 4.9K Sep 16 13:53 big.log
-rw-rw-r-- 1 laborant laborant    0 Jan 15  2026 old.conf
-rw-rw-r-- 1 laborant laborant    6 Sep 16 13:53 small.txt
total 12
-rw-rw-r-- 1 laborant laborant    0 Jan 15  2026 old.conf
-rw-rw-r-- 1 laborant laborant    6 Sep 16 13:53 small.txt
-rw-rw-r-- 1 laborant laborant 5000 Sep 16 13:53 big.log
```

| Flag | Effect |
|---|---|
| `-l` | Long format: type and mode, links, owner, group, size, mtime, name |
| `-a` / `-A` | Include hidden entries / same without `.` and `..` |
| `-h` | Human-readable sizes (with `-l`) |
| `-t`, `-r` | Sort by modification time, reverse the order |
| `-S` | Sort by size |
| `-d` | List the directory, not its contents |
| `--time-style=long-iso` | Full date, including the year for recent files |
| `-u`, `-c` | Show access time or change time instead of mtime |

!!! tip "ls changes its date format for older files"
    `ls` prints the year instead of the time for files older than six months, so `--time-style=long-iso` keeps output consistent for scripts. `tree -L 2 /etc/ssh` shows a directory as a tree (package `tree`).

!!! warning "Do not parse ls in scripts"
    Column widths, date formats and quoting of odd names change between versions and locales. Use `find -printf`, `stat -c` or a glob instead.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between an absolute and a relative path?"
    **Say first:** an absolute path starts at `/` and means the same thing everywhere; a relative path starts from the current directory.

    **Proof:** `cd /var/log` works from anywhere; `cd log` works only from `/var`.

    **Follow-up:** Why should scripts and cron jobs use absolute paths?
<!-- --8<-- [end:l1] -->

??? question "L2: Show the five most recently modified files in /var/log."
    **Say first:** sort by time.

    **Proof:** `ls -lt /var/log | head -6`

    **Follow-up:** How would you do it recursively? (`find /var/log -type f -printf '%T@ %p\n' | sort -n | tail -5`.)

??? question "L2: Show the permissions of a directory, not its contents."
    **Say first:** add `-d`.

    **Proof:** `ls -ld /tmp`

    **Follow-up:** What does the `t` at the end of the mode mean?

??? question "L2: Return to the directory you were in before the last cd."
    **Say first:** `cd -`.

    **Proof:** `cd /etc; cd /tmp; cd -` prints `/etc`.

    **Follow-up:** How do you keep several directories on a stack? (`pushd`, `popd`.)

??? question "L3: pwd shows one path, but a script using the same directory writes elsewhere."
    **Say first:** the directory is reached through a symlink; compare the logical and physical paths.

    **Proof:** `pwd` versus `pwd -P`; `readlink -f .`

    **Follow-up:** Which path does a program's `getcwd()` return? (The physical one.)

??? question "L3: ls hangs when listing a directory."
    **Say first:** check whether the directory is a network mount or holds millions of entries.

    **Proof:** `findmnt -T <dir>` shows `nfs`; `ls -f` (no sorting) or `ls -1U | head` returns faster on huge directories.

    **Follow-up:** Why does `ls -l` make a slow NFS mount worse? (One `stat` per entry.)

---

## Related

- [File Operations](file-operations.md): creating, copying and removing
- [Finding Files](finding-files.md): searching instead of browsing
- [Inodes and Links](inodes-and-links.md): what `ls -i` and the link count mean

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
