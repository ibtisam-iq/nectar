# Archiving and Compression

An archive bundles many files, with their paths, owners and permissions, into one stream; compression makes that stream smaller. `tar` does the first and hands the second to `gzip`, `bzip2`, `xz` or `zstd`, which is why most Linux downloads and backups end in `.tar.gz`, `.tar.xz` or `.tar.zst`.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Create, list, extract | `tar -c`, `-t`, `-x` | `tar -tf <archive>` |
| `-f` | The next argument is the archive file; without it, `tar` uses stdin or stdout | `tar -tzf a.tgz` |
| `-C <dir>` | Change to `<dir>` before extracting or adding files | `tar -xf a.tgz -C /opt` |
| Compression flags | `-z` gzip, `-j` bzip2, `-J` xz, `--zstd` zstd | `file <archive>` |
| Extracting | GNU `tar` detects the compression; the flag is optional | `tar -xf a.tar.xz` |
| Absolute paths | Leading `/` is stripped on create | `tar -tf` |
| Permissions | Stored always; restored for root by default, `-p` for others | `tar -tvf` |
| Compressors by ratio | `xz` > `zstd` > `bzip2` > `gzip` (typical text) | `ls -l` |
| Compressors by speed | `zstd` and `gzip` fastest, `xz` slowest | `time` |
| Read compressed files | `zcat`, `zless`, `zgrep`; `xzcat`, `bzcat`, `zstdcat` | `zcat f.gz` |
| Useful extras | `--exclude='*.log'`, `--strip-components=1`, one member by path | `tar -tf <archive>` |
| `zip` | Archive and compression in one; common with Windows users | `unzip -l f.zip` |
<!-- --8<-- [end:facts] -->

---

## tar Basics

```bash
tar -czvf site.tar.gz site
tar -tzvf site.tar.gz
mkdir restore
tar -xf site.tar.gz -C restore
ls -l restore/site/conf
```

Output:

```text
site/
site/conf/
site/conf/nginx.conf
site/logs/
site/logs/access.log
drwxrwxr-x laborant/laborant 0 2026-09-16 14:01 site/
drwxrwxr-x laborant/laborant 0 2026-09-16 14:01 site/conf/
-rw-r----- laborant/laborant 10 2026-09-16 14:01 site/conf/nginx.conf
drwxrwxr-x laborant/laborant  0 2026-09-16 14:01 site/logs/
-rw-rw-r-- laborant/laborant 1288895 2026-09-16 14:01 site/logs/access.log
total 4
-rw-r----- 1 laborant laborant 10 Sep 16 14:01 nginx.conf
```

The archive kept mode `640` on `nginx.conf`. Read the flags as action (`c`, `t`, `x`), compression (`z`), `v` for a file list, and `f` followed by the archive name.

```bash
tar -xf site.tar.gz -C restore site/conf/nginx.conf
tar -czf nologs.tgz --exclude='*.log' site
tar -tzf nologs.tgz
tar -cJf site.tar.xz site
tar -xf site.tar.xz -C restore && echo "xz extracted without -J"
```

Output:

```text
site/
site/conf/
site/conf/nginx.conf
site/logs/
xz extracted without -J
```

---

## The -f Option and Old-Style Syntax

Without `-f`, GNU `tar` reads the archive from stdin, and refuses when stdin is a terminal:

```bash
tar -xzv site.tar.gz; echo "rc=$?"
```

Output:

```text
tar: Refusing to read archive contents from terminal (missing -f option?)
tar: Error is not recoverable: exiting now
rc=2
```

Reading from a pipe is the one case where `-f` is not needed:

```bash
mkdir -p /tmp/gh
curl -fsSL https://github.com/cli/cli/releases/download/v2.63.2/gh_2.63.2_linux_amd64.tar.gz | tar -xzf - -C /tmp/gh
ls /tmp/gh/gh_2.63.2_linux_amd64
```

Output:

```text
LICENSE
bin
share
```

`-f -` names stdin explicitly. Options without a dash are the old (BSD-style) form, where each letter that takes an argument consumes the next word in order:

```bash
tar Cxzf restore site.tar.gz && echo "old-style syntax worked"
```

Output:

```text
old-style syntax worked
```

`C` took `restore` and `f` took `site.tar.gz`. The dashed form with `-C` at the end is clearer and is the one to use in scripts.

---

## Absolute Paths

```bash
tar -czf /tmp/etc-ssh.tgz /etc/ssh/ssh_config
tar -tzf /tmp/etc-ssh.tgz
```

Output:

```text
tar: Removing leading `/' from member names
etc/ssh/ssh_config
```

Stored paths are relative, so extracting never overwrites `/etc` unless the command runs in `/` or uses `-C /`. The message goes to stderr and is harmless; `-C / etc/ssh/ssh_config` creates the archive without it.

!!! warning "Inspect archives from untrusted sources before extracting"
    `tar -tvf` shows paths and owners first. Extracting as root restores ownership and modes from the archive. GNU `tar` strips leading `../` from member names, but a crafted archive can still use symlinks to write outside the target directory.

---

## Compressors Compared

The same 1.2 MB text log, compressed with each tool at its default level:

```bash
for c in gzip bzip2 xz zstd; do
  start=$(date +%s.%N)
  $c -q -k -f site/logs/access.log
  end=$(date +%s.%N)
  printf '%-6s %s\n' "$c" "$(awk -v s=$start -v e=$end 'BEGIN{printf "%.2fs", e-s}')"
done
ls -l site/logs/ | awk 'NR>1 {print $5, $9}'
```

Output:

```text
gzip   0.03s
bzip2  0.04s
xz     0.21s
zstd   0.01s
1288895 access.log
255637 access.log.bz2
428483 access.log.gz
47552 access.log.xz
107311 access.log.zst
```

| Tool | Extension | tar flag | Use it for |
|---|---|---|---|
| `gzip` | `.gz`, `.tgz` | `-z` | Compatibility; logs, web assets |
| `bzip2` | `.bz2` | `-j` | Legacy archives |
| `xz` | `.xz` | `-J` | Smallest files for distribution (kernel, packages) |
| `zstd` | `.zst` | `--zstd` | Fast backups and container layers; tunable levels 1 to 19 |

`-k` keeps the original; without it, each compressor replaces the file. Compressors work on single files, which is why `tar` bundles first. `gzip -l` shows the ratio of a `.gz` file.

---

## zip and cpio

```bash
zip -qr site.zip site
unzip -l site.zip | tail -3
find site -name '*.conf' | cpio -o -H newc 2>/dev/null > conf.cpio
cpio -it < conf.cpio
```

Output:

```text
   428483  2026-09-16 14:01   site/logs/access.log.gz
---------                     -------
  2127888                     9 files
1 block
site/conf/nginx.conf
```

`zip` compresses each file separately and keeps a central index, so single files extract quickly. `cpio` reads file names from stdin; the `newc` format is how an initramfs is packed. `7z` (`p7zip`) handles `.7z` and most other formats.

---

## Common Errors

### `tar: Refusing to read archive contents from terminal (missing -f option?)`

**Cause:** `-f` is missing, so `tar` tried to read the archive from the terminal.

**Fix:** `tar -xzf site.tar.gz`.

### `gzip: stdin: not in gzip format`

**Cause:** the file is not gzip-compressed, often an HTML error page saved by `curl` without `-f`, or an archive compressed with another tool.

**Fix:** `file archive.tar.gz`; drop `-z` and let `tar -xf` detect the format.

### `tar: nosuch: Not found in archive`

**Cause:** the member path does not match the stored path (a leading `./` or `/` difference is common).

**Fix:** `tar -tf archive | grep <name>` and use the exact stored path.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between archiving and compression?"
    **Say first:** archiving combines many files and their metadata into one stream (`tar`); compression shrinks a single stream (`gzip`, `xz`, `zstd`).

    **Proof:** `tar -cf a.tar dir` produces a file about as large as the directory; `gzip a.tar` shrinks it.

    **Follow-up:** Why does `zip` not need `tar`?

??? question "L1: What does the -f option of tar mean?"
    **Say first:** the next argument is the archive file; without `-f`, `tar` reads from stdin or writes to stdout.

    **Proof:** `tar -xz archive.tgz` in a terminal fails with "Refusing to read archive contents from terminal".

    **Follow-up:** When is leaving out `-f` useful? (Piping from `curl` or over `ssh`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Back up /etc into a dated, compressed archive and verify it."
    **Say first:** create with a date in the name, then list and test it.

    **Proof:**

    ```bash
    sudo tar -czf /backup/etc-$(date +%F).tar.gz -C / etc
    tar -tzf /backup/etc-$(date +%F).tar.gz | head
    gzip -t /backup/etc-$(date +%F).tar.gz && echo ok
    ```

    **Follow-up:** How do you restore one file from it without extracting everything?

??? question "L2: Extract a release archive into /opt/app without its top-level directory."
    **Say first:** extract into the target and strip one path component.

    **Proof:** `sudo tar -xzf app-1.4.tar.gz -C /opt/app --strip-components=1`

    **Follow-up:** How do you check the layout first? (`tar -tzf app-1.4.tar.gz | head`.)

??? question "L2: Copy a directory to another server without writing an archive to disk."
    **Say first:** stream `tar` through `ssh`.

    **Proof:** `tar -czf - /srv/data | ssh host 'tar -xzf - -C /restore'`

    **Follow-up:** When would `rsync -a` be the better choice?

??? question "L3: A deployment script fails with gzip: stdin: not in gzip format."
    **Say first:** check what was downloaded before debugging `tar`.

    **Proof:** `file release.tar.gz` reports `HTML document`; the download returned an error page because `curl` ran without `-f`.

    **Follow-up:** How do you make the script fail at the download step?

??? question "L3: Files extracted from a backup have the wrong owner and permissions."
    **Say first:** check who extracted and with which options.

    **Proof:** a non-root user gets its own ownership and the umask applied; root with `tar -xpf` (or `--same-owner`) restores both; `tar -tvf` shows what was stored.

    **Follow-up:** Which extra options preserve ACLs and SELinux labels? (`--acls --selinux --xattrs`.)

---

## Related

- [File Operations](file-operations.md): `cp -a` and `rsync` as alternatives
- [Finding Files](finding-files.md): building file lists for `tar` and `cpio`
- [File Types](file-types.md): identifying an archive with `file`
- [Exit Codes and Chaining](../01-shell-and-cli/exit-codes-and-chaining.md): `tar` exits 2 on fatal errors

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
