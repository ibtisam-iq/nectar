# File Transfer

`scp`, `sftp` and `rsync` copy files over SSH, so they use the same keys, `~/.ssh/config` aliases and jump hosts as an interactive login. `rsync` is the tool for repeated or large copies because it sends only differences and can resume, while `scp` suits a quick one-off file.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `scp` syntax | `scp SRC [user@]host:DEST`, `scp host:SRC DEST`; `-r` recursive, `-p` keep times and modes, `-P` port | `scp -v file host:/tmp/` |
| `scp` protocol | OpenSSH 9.0 and later use SFTP underneath; `-O` selects the old SCP protocol | `scp -v` shows `Sending subsystem: sftp` |
| `rsync` basics | `-a` archive (recursive, links, modes, times, owner for root), `-v` verbose, `-z` compress, `-P` = `--partial --progress` | `rsync -av src/ host:dst/` |
| Trailing slash | `rsync src host:dst` creates `dst/src`; `rsync src/ host:dst` copies the contents | `find dst` |
| Deletion | `--delete` removes files missing from the source; always preview with `-n` | `rsync -avn --delete src/ dst/` |
| Change codes | `-i` prints one line per change, such as `*deleting` or `>f.st......` | `rsync -ai src/ dst/` |
| Both ends | `rsync` must be installed on the remote host too | `ssh host rsync --version` |
| `sftp` | Interactive or batch (`-b file`, `-b -`) file sessions; no remote shell needed | `sftp -b - host` |
| Streams | `tar czf - dir` piped into `ssh host 'tar xzf - -C /dst'` copies a tree over one connection | `ssh host 'ls /dst'` |
| Through a bastion | All three honor `ProxyJump`; `rsync -e 'ssh -J gw'` for one-offs | `rsync -e 'ssh -J gw' ...` |
<!-- --8<-- [end:facts] -->

---

## scp for Single Files

The examples run as `ops` on `client`, with the `web` alias from the [client configuration file](ssh-client.md#the-client-configuration-file).

```bash
scp /etc/hosts web:/tmp/hosts.txt
scp web:/etc/os-release .
head -2 os-release
scp /etc/hosts web:/etc/hosts.copy; echo "exit=$?"
scp -v /etc/hosts web:/tmp/hosts.txt 2>&1 | grep -E 'Sending subsystem|Sending command'
scp -O -v /etc/hosts web:/tmp/hosts.txt 2>&1 | grep -E 'Sending subsystem|Sending command'
```

Output:

```text
NAME="Rocky Linux"
VERSION="10.2 (Red Quartz)"
scp: dest open "/etc/hosts.copy": Permission denied
scp: failed to upload file /etc/hosts to /etc/hosts.copy
exit=1
debug1: Sending subsystem: sftp
debug1: Sending command: scp -v -t /tmp/hosts.txt
```

Successful copies print nothing when the output is not a terminal. The remote user `deploy` cannot write to `/etc`; `scp` has no `sudo`, so such files go to `/tmp` first and are moved with `ssh -t web sudo install ...`. The debug lines show the SFTP subsystem by default and the old `scp -t` remote command with `-O`.

!!! note "Why scp moved to SFTP"
    The old protocol let the remote side's shell expand file names, which caused quoting bugs and a history of security issues. With SFTP underneath, `scp` behaves the same from the user's point of view, and `-O` remains for servers without an SFTP subsystem.

---

## rsync and the Trailing Slash

A trailing slash on the source means "the contents of this directory". Without it, `rsync` recreates the directory itself under the destination.

```bash
mkdir -p site/css
echo '<h1>shop</h1>' > site/index.html
echo 'body{}' > site/css/app.css
rsync -a site web:/tmp/
rsync -a site/ web:/tmp/site-copy/
ssh web 'find /tmp/site /tmp/site-copy | sort'
```

Output:

```text
/tmp/site
/tmp/site-copy
/tmp/site-copy/css
/tmp/site-copy/css/app.css
/tmp/site-copy/index.html
/tmp/site/css
/tmp/site/css/app.css
/tmp/site/index.html
```

The slash on the destination does not change the result. Deploy scripts that forget the source slash end up with `/var/www/html/site/index.html` instead of `/var/www/html/index.html`.

---

## Sending Changes and Deleting Safely

A second run sends only what changed. Files deleted from the source stay on the destination until `--delete` is given, and `-n` shows what it would remove.

```bash
echo '<h1>shop v2</h1>' > site/index.html
rm site/css/app.css
echo 'new' > site/about.html
rsync -av site/ web:/tmp/site-copy/
rsync -avn --delete site/ web:/tmp/site-copy/
rsync -a --delete -i site/ web:/tmp/site-copy/
ssh web 'find /tmp/site-copy | sort'
```

Output:

```text
sending incremental file list
./
about.html
index.html
css/

sent 237 bytes  received 71 bytes  616.00 bytes/sec
total size is 21  speedup is 0.07
sending incremental file list
deleting css/app.css

sent 124 bytes  received 35 bytes  318.00 bytes/sec
total size is 21  speedup is 0.13 (DRY RUN)
*deleting   css/app.css
/tmp/site-copy
/tmp/site-copy/about.html
/tmp/site-copy/css
/tmp/site-copy/index.html
```

The dry run named exactly one deletion, and `-i` confirmed it during the real run.

!!! danger "--delete with the wrong path empties the destination"
    `rsync -a --delete empty/ host:/srv/data/` deletes everything under `/srv/data`. Run the same command with `-n` first, read the `deleting` lines, and only then remove `-n`.

---

## Large Files and Resuming

`--partial` keeps a partly transferred file, so a broken copy continues instead of starting over. `--info=progress2` prints one progress line for the whole transfer.

```bash
dd if=/dev/urandom of=big.img bs=1M count=64 status=none
rsync -a --partial --info=progress2 big.img web:/tmp/ 2>&1 | tr '\r' '\n' | tail -2
rsync -a --stats big.img web:/tmp/ | grep -E 'Number of regular files transferred|Total bytes sent'
```

Output:

```text
     67,108,864 100%   31.97MB/s    0:00:02 (xfr#1, to-chk=0/1)
     67,108,864 100%   29.82MB/s    0:00:02 (xfr#1, to-chk=0/1)
Number of regular files transferred: 0
Total bytes sent: 58
```

The second run compared size and modification time, found the file current and sent 58 bytes. `-c` compares checksums instead, which reads every file on both sides.

---

## sftp Sessions

`sftp` works where only file access is allowed; batch mode (`-b`) reads commands from a file or standard input and stops at the first failing command. The `partner` account on `gw` is locked into `/srv/sftp/partner` by the `Match` block in [sshd Server](sshd-server.md#an-sftp-only-chroot), so it writes only into `upload` and can neither leave the jail nor open a shell.

```bash
printf 'pwd\nput /tmp/order-1001.csv\nls -l\ncd /\nls\ncd /etc\n' | sftp -b - partner@172.16.0.3; echo "exit=$?"    # on client
ssh partner@172.16.0.3 id; echo "exit=$?"
```

Output:

```text
sftp> pwd
Remote working directory: /upload
sftp> put /tmp/order-1001.csv
sftp> ls -l
-rw-r--r--    ? 1004     1006           11 Sep 17 15:55 order-1001.csv
sftp> cd /
sftp> ls
upload  
sftp> cd /etc
stat remote: No such file or directory
exit=1
This service allows sftp connections only.
exit=1
```

---

## tar Over SSH

A `tar` stream through one SSH connection copies a tree without `rsync` on either side, and works in both directions.

```bash
tar czf - site | ssh web 'mkdir -p /tmp/tarcopy && tar xzf - -C /tmp/tarcopy'
ssh web 'find /tmp/tarcopy | sort'
ssh web 'tar czf - -C /etc nginx 2>/dev/null' | tar tzf - | head -4
```

Output:

```text
/tmp/tarcopy
/tmp/tarcopy/site
/tmp/tarcopy/site/about.html
/tmp/tarcopy/site/css
/tmp/tarcopy/site/index.html
nginx/
nginx/fastcgi.conf.default
nginx/fastcgi.conf
nginx/scgi_params
```

The remote `2>/dev/null` keeps warnings out of the local terminal; the data travels on standard output only.

!!! tip "Pick the tool by the job"
    Use `scp` for one file and `rsync -a --partial` for directories synced again later, large files or flaky links. Use `tar` over `ssh` when the far side has no `rsync` or the tree has many small files, and `sftp` when only file access is allowed.

---

## Common Errors

### `scp: dest open "/etc/hosts.copy": Permission denied`

**Cause:** the remote user cannot write to the destination directory.

**Fix:** copy to a writable path and move it with `ssh -t host sudo install -m 644 /tmp/file /etc/file`.

### `bash: line 1: rsync: command not found`

**Cause:** `rsync` is missing on the remote host. The remote shell prints this line, and the local `rsync` follows with `rsync: connection unexpectedly closed (0 bytes received so far) [sender]` and exits with code 12 (`error in rsync protocol data stream`), as `rsync -a site/ gw:/tmp/site/` did while `gw` had no `rsync`.

**Fix:** install it on the remote host (`dnf install rsync`, `apt install rsync`), or use `tar` over `ssh`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: When do you use rsync instead of scp?"
    **Say first:** for repeated copies, large files and directory trees, because `rsync` sends only differences, can resume and can delete extra files.

    **Proof:** a second `rsync -a --stats` of an unchanged file reports `Number of regular files transferred: 0`.

    **Follow-up:** What does the trailing slash on the source change?
<!-- --8<-- [end:l1] -->

??? question "L2: Mirror a local directory to a server, removing files that no longer exist locally, without surprises."
    **Say first:** preview with `-n` and `--delete`, read the deletions, then run it for real.

    **Proof:**

    ```bash
    rsync -avn --delete site/ web:/tmp/site-copy/
    rsync -a --delete -i site/ web:/tmp/site-copy/
    ```

    **Follow-up:** What happens if the source path is empty or mistyped?

??? question "L2: Copy a directory to a server that has no rsync installed."
    **Say first:** stream a `tar` archive through `ssh`.

    **Proof:** `tar czf - site | ssh web 'mkdir -p /tmp/tarcopy && tar xzf - -C /tmp/tarcopy'`

    **Follow-up:** How do you keep ownership when extracting as root?

??? question "L2: Copy a file to a server that is reachable only through a bastion."
    **Say first:** use `ProxyJump`, which `scp`, `sftp` and `rsync` all follow.

    **Proof:** `scp -J deploy@172.16.0.3 file deploy@172.16.1.3:/tmp/`, or `rsync -e 'ssh -J gw' file web:/tmp/`.

    **Follow-up:** Why is copying the file to the bastion first a worse idea?

??? question "L3: A nightly rsync backup now takes hours instead of minutes. What do you check?"
    **Say first:** whether it still sends only changes, and what changed in the data, the command or the network.

    **Proof:** `rsync --stats` (files transferred and bytes sent); `-i` output for files that change every night (timestamps reset by a build, for example); `-c` added by someone; network throughput with `iperf3`.

    **Follow-up:** When does `--partial` or `--inplace` help, and when does it hurt?

??? question "L3: A deploy with rsync left the site broken: files are in /var/www/html/site/ instead of /var/www/html/. What happened?"
    **Say first:** the source path had no trailing slash, so `rsync` created the directory itself under the destination.

    **Proof:** `rsync -a site web:/tmp/` creates `/tmp/site/index.html`; `rsync -a site/ ...` copies the contents.

    **Follow-up:** How would a dry run have shown the mistake?

---

## Related

- [SSH Client](ssh-client.md): the aliases and keys these tools use
- [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md): `tar` options
- [Backup and Restore](../12-storage/backup-and-restore.md): `rsync --link-dest` snapshots

Captured on Ubuntu 24.04.4 (OpenSSH 9.6p1, rsync 3.2.7) against Rocky Linux 10.2 (OpenSSH 9.9p1) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
