# Viewing and Comparing

Most operational text is logs and configuration files, read with `head`, `tail`, `less` and compared with `diff`. Knowing which tool shows hidden characters, follows a rotated log or verifies a checksum saves time in every incident.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Page through a file | `less` (`/` search, `G` end, `F` follow, `q` quit) | `less /var/log/messages` |
| First or last lines | `head -n N`, `tail -n N` | `tail -n 50 file` |
| Follow a log | `tail -f` follows the open file; `tail -F` follows the name across rotation | `tail -F /var/log/app.log` |
| Count | `wc -l` lines, `-w` words, `-c` bytes | `wc -l < file` |
| Hidden characters | `cat -A` shows `^M` (CR), `^I` (tab), `$` (line end) | `cat -A file` |
| Byte view | `od -c`, `xxd`, `hexdump -C` | `od -c file` |
| Compare files | `diff` (exit 0 same, 1 different, 2 error); `diff -u` for patches | `diff -u a b` |
| Binary compare | `cmp` reports the first differing byte | `cmp a b` |
| Compressed logs | `zcat`, `zless`, `zgrep` read `.gz` without extracting | `zgrep ERROR app.log.1.gz` |
| Checksums | `sha256sum`; `-c` verifies a list | `sha256sum -c SHA256SUMS` |
| Base64 | Encoding, not encryption | `base64 -d` |
| Line ranges | `sed -n '5,7p' file` | `sed -n '5,7p'` |
<!-- --8<-- [end:facts] -->

---

## Reading Files

The examples use a 17-line web access log with documentation IP addresses (`192.0.2.0/24` and similar).

```bash
head -n 3 access.log
tail -n 2 access.log
wc access.log
wc -l < access.log
sed -n '5,7p' access.log | cut -c1-60
```

Output:

```text
192.0.2.10 - - [16/Sep/2026:14:10:00 +0000] "GET /api/orders HTTP/1.1" 200 3354 "-" "curl/8.5.0" 1.237
192.0.2.10 - - [16/Sep/2026:14:10:07 +0000] "POST /login HTTP/1.1" 401 118 "-" "Mozilla/5.0" 0.041
192.0.2.10 - - [16/Sep/2026:14:10:14 +0000] "GET /login HTTP/1.1" 200 824 "-" "curl/8.5.0" 0.825
198.51.100.7 - - [16/Sep/2026:14:15:45 +0000] "GET /api/orders/42 HTTP/1.1" 500 441 "-" "curl/8.5.0" 1.828
203.0.113.99 - - [16/Sep/2026:14:15:52 +0000] "POST /login HTTP/1.1" 401 118 "-" "Mozilla/5.0" 0.037
  17  221 1730 access.log
17
192.0.2.10 - - [16/Sep/2026:14:11:28 +0000] "GET / HTTP/1.1"
192.0.2.10 - - [16/Sep/2026:14:11:35 +0000] "GET /static/app
198.51.100.23 - - [16/Sep/2026:14:12:42 +0000] "GET /static/
```

`wc -l < file` prints the number without the file name, which is handier in scripts.

| `less` key | Action |
|---|---|
| `/text`, `?text` | Search forward, backward |
| `n`, `N` | Next, previous match |
| `g`, `G` | Start, end of file |
| `F` | Follow new lines (like `tail -f`); `Ctrl+C` stops following |
| `-S` (option) | Do not wrap long lines |
| `-R` (option) | Keep colors from `grep --color=always` |

---

## Hidden Characters

A trailing space and a Windows line ending look like nothing in `cat` but break parsers:

```bash
printf 'key=value \r\n\tindented\n' > dos.txt
cat -A dos.txt
od -c dos.txt | head -2
```

Output:

```text
key=value ^M$
^Iindented$
0000000   k   e   y   =   v   a   l   u   e      \r  \n  \t   i   n   d
0000020   e   n   t   e   d  \n
```

`^M` is the carriage return (`\r`) before the line end. `cat -n` numbers lines; `nl` numbers only non-empty ones.

---

## Following Logs Through Rotation

`tail -f` keeps reading the file it opened. When `logrotate` renames the file, `tail -f` stays on the old one; `tail -F` reopens the name.

```bash
touch /tmp/app.log
(for i in 1 2 3; do sleep 1; echo "line $i" >> /tmp/app.log; done; mv /tmp/app.log /tmp/app.log.1; echo "after rotate" >> /tmp/app.log) &
timeout 7 tail -F /tmp/app.log
```

Output:

```text
line 1
line 2
line 3
tail: '/tmp/app.log' has become inaccessible: No such file or directory
tail: '/tmp/app.log' has appeared;  following new file
after rotate
```

!!! tip "Use tail -F or journalctl -f for long watches"
    During a deployment, `tail -f` on a log that rotates at midnight silently stops showing new lines. `tail -F` follows the new file; for services that log to the journal, `journalctl -fu <unit>` avoids the question.

---

## Comparing Files

```bash
diff app-v1.conf app-v2.conf
echo "rc=$?"
diff -u app-v1.conf app-v2.conf
```

Output:

```text
2c2
< listen_port = 8080
---
> listen_port = 8443
4c4
< db_pool = 10
---
> db_pool = 20
7c7,8
< feature_x = off
---
> feature_x = on
> tls = enabled
rc=1
--- app-v1.conf	2026-09-16 14:21:05.719410976 +0000
+++ app-v2.conf	2026-09-16 14:21:10.005581444 +0000
@@ -1,7 +1,8 @@
 # app configuration
-listen_port = 8080
+listen_port = 8443
 db_host = db01.internal
-db_pool = 10
+db_pool = 20
 log_level = info
 #debug = true
-feature_x = off
+feature_x = on
+tls = enabled
```

In the default format, `2c2` means "line 2 changed into line 2"; `a` is added and `d` deleted. The unified format (`-u`) is what `git diff` and `patch` use.

```bash
cmp app-v1.conf app-v2.conf
echo "rc=$?"
diff -q app-v1.conf app-v1.conf; echo "rc=$?"
diff -y -W 60 app-v1.conf app-v2.conf
```

Output:

```text
app-v1.conf app-v2.conf differ: byte 36, line 2
rc=1
rc=0
# app configuration		# app configuration
listen_port = 8080	     |	listen_port = 8443
db_host = db01.internal		db_host = db01.internal
db_pool = 10		     |	db_pool = 20
log_level = info		log_level = info
#debug = true			#debug = true
feature_x = off		     |	feature_x = on
			     >	tls = enabled
```

| Tool | Use |
|---|---|
| `diff -u a b` | Review or patch text changes |
| `diff -r dir1 dir2` | Compare directory trees |
| `diff -y` / `sdiff` | Side by side |
| `cmp` | Binary files; first difference only |
| `diff <(ssh h1 cat f) <(ssh h2 cat f)` | Compare a file across two hosts |
| `vimdiff a b` | Interactive merge |

---

## Compressed Logs, Checksums and Base64

```bash
gzip -k access.log
zcat access.log.gz | head -1
zgrep -c ' 500 ' access.log.gz
sha256sum app-v1.conf app-v2.conf > SHA256SUMS
sha256sum -c SHA256SUMS
echo "tampered" >> app-v2.conf
sha256sum -c SHA256SUMS; echo "rc=$?"
echo -n 'admin:s3cret' | base64
echo 'YWRtaW46czNjcmV0' | base64 -d; echo
```

Output:

```text
192.0.2.10 - - [16/Sep/2026:14:10:00 +0000] "GET /api/orders HTTP/1.1" 200 3354 "-" "curl/8.5.0" 1.237
4
app-v1.conf: OK
app-v2.conf: OK
app-v1.conf: OK
app-v2.conf: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
rc=1
YWRtaW46czNjcmV0
admin:s3cret
```

!!! warning "Base64 is not encryption"
    Kubernetes Secrets, HTTP basic authentication headers and many config files store base64 text, which anyone can decode. `echo -n` matters: without it the newline is encoded too, and the credential no longer matches.

---

## Common Errors

### `sha256sum: WARNING: 1 computed checksum did NOT match`

**Cause:** a file changed after the checksum list was made, or a download is corrupt.

**Fix:** download again; if it still fails, do not use the file.

### `gzip: plain.gz: not in gzip format`

**Cause:** `zcat` was given a file that is not gzip data, whatever its name, or one compressed with another tool. `zgrep` reads plain files as well, so it does not fail the same way.

**Fix:** `file <path>`; use `xzcat`, `bzcat` or `zstdcat` to match.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between tail -f and tail -F?"
    **Say first:** `-f` follows the file it opened; `-F` follows the name, so it reopens the log after rotation.

    **Proof:** after `mv app.log app.log.1`, `tail -F` prints "has appeared; following new file".

    **Follow-up:** Which rotation method keeps `tail -f` working? (`copytruncate`.)
<!-- --8<-- [end:l1] -->

??? question "L2: A config file parses on one server and fails on another. Show the invisible difference."
    **Say first:** compare with hidden characters visible.

    **Proof:** `diff <(cat -A a.conf) <(cat -A b.conf)` shows `^M$` or trailing spaces on one side.

    **Follow-up:** How do you strip the carriage returns?

??? question "L2: Verify a downloaded release against its published checksum."
    **Say first:** compute the hash and compare, or use `-c` with the checksum file.

    **Proof:** `sha256sum -c tool_SHA256SUMS --ignore-missing`

    **Follow-up:** What does a checksum not protect against? (A compromised download site; signatures do.)

??? question "L2: Count 500 errors in today's and yesterday's rotated, compressed logs."
    **Say first:** use the `z` variants so no extraction is needed.

    **Proof:** `zgrep -c ' 500 ' access.log.1.gz; grep -c ' 500 ' access.log`

    **Follow-up:** How would you combine both into one count?

??? question "L2: Produce a patch of your changes to a config file."
    **Say first:** unified diff against the original.

    **Proof:** `diff -u nginx.conf.orig nginx.conf > nginx.patch`; apply elsewhere with `patch -p0 < nginx.patch`.

    **Follow-up:** What exit status does `diff` return when files differ, and why does that matter under `set -e`?

??? question "L3: During a deployment, tail -f on the application log stopped showing new lines."
    **Say first:** check whether the log was rotated or recreated.

    **Proof:** `ls -li app.log*` shows a new inode for `app.log`; `lsof -p $(pgrep -n tail)` shows `tail` still holding the old file.

    **Follow-up:** How do you avoid it next time?

---

## Related

- [grep and Regex](grep-and-regex.md): searching instead of reading
- [Streams and Redirection](../01-shell-and-cli/streams-and-redirection.md): process substitution in `diff <(...)`
- [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md): why `tail -f` keeps the old file

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
