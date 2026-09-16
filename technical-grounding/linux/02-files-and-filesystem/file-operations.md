# File Operations

Creating, copying, moving and deleting files looks trivial until ownership, timestamps, sparse files or a second filesystem are involved. The flags on this page decide whether a copy is a faithful backup or a subtly different file.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Create parents | `mkdir -p` (no error if the directory exists) | `mkdir -pv a/b` |
| `touch` | Creates an empty file or updates its timestamps | `stat -c %y f` |
| `cp` | Copies content; new file gets the copier's owner and the current time | `ls -l` |
| `cp -a` | Archive: recursive, keeps mode, owner, timestamps, links, xattrs | `ls -l` |
| `cp -r` | Recursive only; does not keep ownership or times | `ls -l` |
| `mv` on one filesystem | Rename: same inode, instant | `ls -i` |
| `mv` across filesystems | Copy, then delete the source | `ls -i` |
| `rm` | Removes a name (unlinks); no recycle bin | `ls -l` |
| `rmdir` | Removes empty directories only | `rmdir d` |
| Sparse file | Size is larger than the blocks it uses | `du -h --apparent-size` |
| `install` | Copy plus mode and ownership in one step | `install -m 755 src dst` |
| Download that fails on HTTP errors | `curl -fsSL -o file URL` | `echo $?` |
<!-- --8<-- [end:facts] -->

---

## Creating Files and Directories

```bash
mkdir a/b/c
mkdir -p a/b/c
mkdir -pv app/{conf,logs}
```

Output:

```text
mkdir: cannot create directory ‘a/b/c’: No such file or directory
mkdir: created directory 'app'
mkdir: created directory 'app/conf'
mkdir: created directory 'app/logs'
```

`-p` means "parents": it creates missing levels and succeeds silently if the path exists. `touch` sets timestamps, which is useful for testing time-based cleanups:

```bash
touch -d '2026-01-01 09:00' conf.yml
stat -c '%n %y' conf.yml
touch conf.yml
stat -c '%n %y' conf.yml
```

Output:

```text
conf.yml 2026-01-01 09:00:00.000000000 +0000
conf.yml 2026-09-16 13:55:05.349499514 +0000
```

---

## Copying

A plain `cp` creates a new file owned by whoever runs it, with the current time. `-p` and `-a` preserve the original metadata.

```bash
touch -d '2026-01-01 09:00' conf.yml
chmod 600 conf.yml
cp conf.yml copy-plain.yml
cp -p conf.yml copy-p.yml
ls -l --time-style=+%F conf.yml copy-*.yml
sudo cp -a conf.yml /tmp/root-a.yml
sudo cp conf.yml /tmp/root-plain.yml
ls -l --time-style=+%F /tmp/root-a.yml /tmp/root-plain.yml
```

Output:

```text
-rw------- 1 laborant laborant 0 2026-01-01 conf.yml
-rw------- 1 laborant laborant 0 2026-01-01 copy-p.yml
-rw------- 1 laborant laborant 0 2026-09-16 copy-plain.yml
-rw------- 1 laborant laborant 0 2026-01-01 /tmp/root-a.yml
-rw------- 1 root     root     0 2026-09-16 /tmp/root-plain.yml
```

!!! warning "sudo cp changes ownership to root"
    Copying application files with `sudo cp` produces root-owned files that the service user cannot write. Use `cp -a` to keep ownership, or `install -o <user> -g <group>` to set it explicitly.

```bash
cp app backup-app
echo "rc=$?"
cp -r app backup-app
ls backup-app
echo v1 > file.txt; echo v2 > new.txt
cp -n new.txt file.txt; cat file.txt
cp --backup=numbered new.txt file.txt; ls file.txt*
```

Output:

```text
cp: -r not specified; omitting directory 'app'
rc=1
conf
logs
cp: warning: behavior of -n is non-portable and may change in future; use --update=none instead
v1
file.txt
file.txt.~1~
```

| Flag | Effect |
|---|---|
| `-r` / `-R` | Copy directories recursively |
| `-a` | `-dR --preserve=all`: the right choice for backups and migrations |
| `-p` | Keep mode, ownership (as root) and timestamps |
| `-i` / `-n` (`--update=none`) | Ask before overwriting / never overwrite |
| `--backup=numbered` | Keep the old destination as `file.~1~` |
| `--sparse=always` | Keep holes in sparse files |

---

## Moving and Renaming

Within one filesystem, `mv` changes only the directory entry, so the inode number stays the same. Across filesystems it copies the data and deletes the source.

```bash
ls -i new.txt
mv new.txt renamed.txt
ls -i renamed.txt
mv renamed.txt /dev/shm/
ls -i /dev/shm/renamed.txt
```

Output:

```text
130334 new.txt
130334 renamed.txt
2 /dev/shm/renamed.txt
```

`/dev/shm` is a tmpfs, so the last move created a new file there. A cross-filesystem move of a large directory takes as long as a copy and can be interrupted halfway.

---

## Removing

```bash
rmdir app
echo "rc=$?"
rm -r app
rm -rfv backup-app
```

Output:

```text
rmdir: failed to remove 'app': Directory not empty
rc=1
removed directory 'backup-app/conf'
removed directory 'backup-app/logs'
removed directory 'backup-app'
```

!!! danger "rm -rf with an empty variable"
    `rm -rf "$DIR/"*` with `DIR` unset expands to `rm -rf /*`. Use `set -u`, or `${DIR:?}` so the command fails when the variable is empty. GNU `rm` refuses `rm -rf /` itself (`--preserve-root`), not `/*`.

`rm` removes a name. The data is freed when no names and no open file descriptors remain, which is why deleting a large log that a process still writes does not free space.

---

## Sparse Files and dd

```bash
truncate -s 1G sparse.img
ls -lh sparse.img
du -h sparse.img
du -h --apparent-size sparse.img
dd if=/dev/zero of=zero.img bs=1M count=10 status=none
ls -lh zero.img
```

Output:

```text
-rw-rw-r-- 1 laborant laborant 1.0G Sep 16 13:55 sparse.img
0	sparse.img
1.0G	sparse.img
-rw-rw-r-- 1 laborant laborant 10M Sep 16 13:55 zero.img
```

A sparse file reports its full size to `ls` but uses disk blocks only where data was written. VM disk images, database files and `truncate`-created swap files are often sparse; `du` without `--apparent-size` shows the real usage.

`dd` copies raw blocks: `bs` is the block size, `count` the number of blocks, `status=progress` prints progress. It is used for disk images and test files; `dd if=image of=/dev/sdX` overwrites a disk without any confirmation.

---

## Installing Files and Downloading

```bash
install -m 750 -d deploy/bin
install -m 755 /usr/bin/true deploy/bin/app
ls -l deploy/bin
curl -fsSL -o missing.html https://example.com/nope
echo "curl rc=$?"
ls missing.html
```

Output:

```text
total 28
-rwxr-xr-x 1 laborant laborant 26936 Sep 16 13:55 app
curl: (22) The requested URL returned error: 404
curl rc=22
ls: cannot access 'missing.html': No such file or directory
```

With `-f`, `curl` exits non-zero on HTTP errors and writes no file; without it, the 404 page would be saved as `missing.html` and the script would continue. `-L` follows redirects, `-sS` hides progress but keeps errors, and `wget -O file URL` is the equivalent download.

---

## Common Errors

### `mkdir: cannot create directory 'a/b/c': No such file or directory`

**Cause:** a parent directory is missing.

**Fix:** `mkdir -p a/b/c`. The related `rmdir: failed to remove 'app': Directory not empty` means the directory still has entries; check them, then `rm -r`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between cp -r and cp -a?"
    **Say first:** `-r` copies directories recursively; `-a` also preserves ownership, permissions, timestamps, symlinks and extended attributes.

    **Proof:** `sudo cp -a` keeps the original owner and date; `sudo cp` produces root-owned files with the current date.

    **Follow-up:** Which one should a backup script use, and what would you use for a remote copy?

??? question "L1: Why is mv instant for a 50 GB file on the same filesystem but slow across filesystems?"
    **Say first:** on one filesystem `mv` renames the directory entry; across filesystems it must copy every block and then delete the original.

    **Proof:** `ls -i` shows the same inode after a local rename and a new inode after moving to `/dev/shm`.

    **Follow-up:** What happens if a cross-filesystem move is interrupted?
<!-- --8<-- [end:l1] -->

??? question "L2: Create a 1 GiB test file instantly, and another that really uses 1 GiB."
    **Say first:** `truncate` makes a sparse file; `dd` or `fallocate` allocates blocks.

    **Proof:** `truncate -s 1G sparse.img`; `fallocate -l 1G full.img`; compare with `du -h`.

    **Follow-up:** Why does `ls -l` not show the difference?

??? question "L2: Deploy a binary with mode 755, owned by root, in one command."
    **Say first:** `install` sets mode and ownership while copying.

    **Proof:** `sudo install -o root -g root -m 755 ./app /usr/local/bin/app`

    **Follow-up:** How does that differ from `cp` followed by `chmod`? (No window with wrong permissions.)

??? question "L2: Download a release file in a script so that HTTP errors stop the script."
    **Say first:** `curl -f` returns non-zero and writes nothing on an HTTP error.

    **Proof:** `curl -fsSL -o tool.tgz "$url" || exit 1`

    **Follow-up:** How would you verify the download? (`sha256sum -c`.)

??? question "L3: A deleted 20 GB log file did not free any disk space."
    **Say first:** a running process still holds the file open.

    **Proof:** `sudo lsof +L1` lists the deleted file and the process; `df -h` changes after the process restarts or the file is truncated through `/proc/<pid>/fd/<n>`.

    **Follow-up:** How should logs be rotated to avoid this? (`copytruncate`, or a signal that makes the app reopen its log.)

??? question "L3: After copying an application directory with sudo, the service fails with permission denied."
    **Say first:** the copy changed ownership to root.

    **Proof:** `ls -l` shows `root root` on files the service user must write; `cp -a` or `chown -R app: <dir>` fixes it.

    **Follow-up:** Which copy flag would have prevented it?

---

## Related

- [Inodes and Links](inodes-and-links.md): what `mv` and `rm` change
- [Finding Files](finding-files.md): bulk operations with `find`
- [Archiving and Compression](archiving-and-compression.md): copying trees as archives

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
