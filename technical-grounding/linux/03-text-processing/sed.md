# sed

`sed` is a stream editor: it reads text line by line, applies editing commands, and writes the result. It is the standard tool for scripted configuration changes, and `sed -i` is behind many deployment scripts, which makes its edge cases worth knowing.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Substitute | `s/old/new/` first match per line; `g` all; `N` the Nth; `I` ignore case (GNU) | `sed 's/a/b/g'` |
| Default output | Every line, edited or not; `-n` plus `p` prints only selected lines | `sed -n '2p'` |
| In-place edit | `-i` rewrites the file; `-i.bak` keeps a backup | `sed -i.bak ...` |
| BSD and macOS | `sed -i ''` needs an explicit empty suffix | `man sed` |
| Addresses | Line number, `$` last line, `/regex/`, ranges `a,b` | `sed -n '/start/,/end/p'` |
| Delete | `d` | `sed '/^#/d'` |
| Insert and append | `i text` before, `a text` after, `c text` replace the line | `sed '/x/a y'` |
| Delimiter | Any character after `s`: `s#a#b#` avoids escaping slashes | `sed 's#/usr#/opt#'` |
| Whole match | `&` in the replacement | `sed 's/[0-9]\+/<&>/'` |
| Groups | `\(...\)` in BRE, `(...)` with `-E`; `\1` in the replacement | `sed -E 's/(a)(b)/\2\1/'` |
| Several commands | `-e cmd -e cmd` or `cmd; cmd` | `sed -e ... -e ...` |
| Symlinks | `-i` replaces a symlink with a regular file unless `--follow-symlinks` | `ls -l` |
<!-- --8<-- [end:facts] -->

---

## Substitution

```bash
sed 's/8080/9090/' app.conf | grep port
grep port app.conf
echo "a-b-c" | sed 's/-/_/'
echo "a-b-c" | sed 's/-/_/g'
echo "a-b-c" | sed 's/-/_/2'
echo "Hello" | sed 's/hello/bye/I'
echo "/usr/local/bin" | sed 's|/usr/local|/opt|'
```

Output:

```text
listen_port = 9090
listen_port = 8080
a_b-c
a_b_c
a-b_c
bye
/opt/bin
```

Without `-i`, `sed` writes to stdout and leaves the file unchanged, which is the safe way to preview an edit.

Groups and `&` reuse matched text:

```bash
echo "2026-09-16 ERROR db down" | sed -E 's/^([0-9-]+) ([A-Z]+) (.*)/\2 [\1] \3/'
echo "port=8080" | sed 's/[0-9]\+/<&>/'
sed -e 's/a/A/' -e 's/b/B/' <<< "abc"
sed 'y/abc/xyz/' <<< "aabbcc"
```

Output:

```text
ERROR [2026-09-16] db down
port=<8080>
ABc
xxyyzz
```

`y` transliterates characters one to one, like `tr`.

---

## Addresses: Selecting Lines

```bash
sed -n '2p' app.conf
sed -n '2,4p' app.conf
sed -n '/db_/p' app.conf
sed '1d' app.conf | head -2
sed '/^#/d; /^$/d' app.conf
sed -n '/14:12:/,/14:13:/p' access.log | cut -c1-45
sed -n '$=' access.log
```

Output:

```text
listen_port = 8080
listen_port = 8080
db_host = db01.internal
db_pool = 10
db_host = db01.internal
db_pool = 10
listen_port = 8080
db_host = db01.internal
listen_port = 8080
db_host = db01.internal
db_pool = 10
log_level = info
feature_x = off
198.51.100.23 - - [16/Sep/2026:14:12:42 +0000
198.51.100.23 - - [16/Sep/2026:14:12:49 +0000
198.51.100.23 - - [16/Sep/2026:14:12:56 +0000
198.51.100.23 - - [16/Sep/2026:14:13:03 +0000
17
```

A regex range starts at the first line matching the first pattern and ends at the first later line matching the second, inclusive; it is how a time window is cut from a log. `$=` prints the line count.

| Address | Selects |
|---|---|
| `3` | Line 3 |
| `$` | Last line |
| `2,5` | Lines 2 to 5 |
| `/re/` | Lines matching `re` |
| `/start/,/end/` | From a `start` line to the next `end` line |
| `5,$` | Line 5 to the end |
| `0~2` (GNU) | Every second line |
| `/re/!` | Lines not matching `re` |

---

## Editing Files in Place

```bash
cp app-v1.conf app.conf
sed -i.bak 's/^log_level = .*/log_level = debug/' app.conf
grep log_level app.conf app.conf.bak
sed -i 's/^#debug = true/debug = true/' app.conf
sed -i '/^db_pool/a db_timeout = 30' app.conf
sed -i '1i # managed by deploy script' app.conf
sed -i '$a # end' app.conf
cat app.conf
```

Output:

```text
app.conf:log_level = debug
app.conf.bak:log_level = info
# managed by deploy script
# app configuration
listen_port = 8080
db_host = db01.internal
db_pool = 10
db_timeout = 30
log_level = debug
debug = true
feature_x = off
# end
```

!!! warning "sed -i is not idempotent by default"
    Running `sed -i '/^db_pool/a db_timeout = 30'` twice adds the line twice. Deployment scripts should check first (`grep -q '^db_timeout' app.conf || sed -i ...`) or use a configuration management tool that manages the whole file.

`sed -i` writes a new file and renames it over the original. The file keeps its mode and owner when `sed` runs as a user who can set them, but a symlink is replaced by a regular file:

```bash
ln -sf app.conf link.conf
sed -i 's/tls/TLS/' link.conf
ls -l link.conf
ln -sf app.conf link2.conf
sed -i --follow-symlinks 's/debug/DEBUG/' link2.conf
ls -l link2.conf
```

Output:

```text
-rw-r--r-- 1 laborant laborant 172 Sep 16 14:24 link.conf
lrwxrwxrwx 1 laborant laborant 8 Sep 16 14:24 link2.conf -> app.conf
```

!!! danger "sed -i on a symlinked config breaks the link"
    Many systems link configuration into place (`/etc/nginx/sites-enabled/`, alternatives, Kubernetes ConfigMap mounts). `sed -i` turns the link into a copy, so later changes to the target no longer apply. Use `--follow-symlinks` or edit the target path.

---

## Common Tasks

```bash
printf 'one\r\ntwo\r\n' > crlf.txt
sed -i 's/\r$//' crlf.txt
cat -A crlf.txt
mkdir -p site && printf 'url=http://old.example.com\n' > site/a.conf && printf 'url=http://old.example.com/x\n' > site/b.conf
grep -rl 'old.example.com' site | xargs sed -i 's/old\.example\.com/new.example.com/g'
grep -r example site
```

Output:

```text
one$
two$
site/b.conf:url=http://new.example.com/x
site/a.conf:url=http://new.example.com
```

| Task | Command |
|---|---|
| Strip Windows line endings | `sed -i 's/\r$//' file` |
| Remove comments and blank lines | `sed '/^\s*#/d; /^\s*$/d' file` |
| Trim trailing whitespace | `sed -i 's/[[:space:]]*$//' file` |
| Uncomment a setting | `sed -i 's/^#\(PermitRootLogin\)/\1/' sshd_config` |
| Change a key's value | `sed -i 's/^\(PasswordAuthentication\).*/\1 no/' sshd_config` |
| Print lines 10 to 20 | `sed -n '10,20p' file` |
| Insert after a match | `sed -i '/^\[main\]/a key=value' file` |
| Bulk replace across files | `grep -rl old dir` into `xargs sed -i 's/old/new/g'` |

In the bulk replace, the dots in the search pattern are escaped so that `old.example.com` does not also match `oldXexampleYcom`.

---

## Common Errors

```bash
sed 's/foo/bar/' nosuch.conf; echo "rc=$?"
echo "x" | sed 's/x/y'
```

Output:

```text
sed: can't read nosuch.conf: No such file or directory
rc=2
sed: -e expression #1, char 5: unterminated `s' command
```

### ``sed: -e expression #1, char 5: unterminated `s' command``

**Cause:** the `s` command is missing its final delimiter, or the pattern contains an unescaped `/`.

**Fix:** close the command (`s/x/y/`), or switch delimiters (`s#/a#/b#`).

### `sed: no input files`

**Cause:** `sed -i` was used in a pipeline; in-place editing needs a file argument, and GNU `sed` exits with status 4.

**Fix:** drop `-i` in pipelines, or pass the file name.

### `unescaped newline inside substitute pattern`

On macOS (BSD `sed`, captured on macOS 26.6.1), `-i` takes the next word as the backup suffix, so the script becomes the suffix and the file name becomes the script:

```bash
printf 'a\n' > sedtest.conf
sed -i 's/a/b/' sedtest.conf
```

Output:

```text
sed: 1: "sedtest.conf
": unescaped newline inside substitute pattern
```

**Fix:** `sed -i '' 's/a/b/' sedtest.conf` on macOS, or install GNU sed (`gsed`). Scripts that must run on both use `sed -i.bak` and delete the backup.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does sed 's/a/b/' do, and what changes with g and -i?"
    **Say first:** it replaces the first `a` on each line with `b` and prints every line; `g` replaces every match on the line, and `-i` writes the result back to the file.

    **Proof:** `echo a-a | sed 's/a/b/'` prints `b-a`; with `g`, `b-b`.

    **Follow-up:** How do you keep a backup when editing in place?

??? question "L1: Why does sed print every line unless you use -n?"
    **Say first:** the default cycle prints the pattern space after each line; `-n` turns that off so only explicit `p` commands print.

    **Proof:** `sed '2p' file` prints line 2 twice; `sed -n '2p' file` prints it once.

    **Follow-up:** How do you print lines 10 to 20?
<!-- --8<-- [end:l1] -->

??? question "L2: Disable password authentication in sshd_config with one command."
    **Say first:** replace the whole line, whether commented or not, then validate.

    **Proof:**

    ```bash
    sudo sed -i.bak -E 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sshd -t && sudo systemctl reload sshd
    ```

    **Follow-up:** Why check `/etc/ssh/sshd_config.d/` as well?

??? question "L2: Replace a hostname in every .conf file under /etc/app."
    **Say first:** find the files that contain it, then edit only those, with dots escaped.

    **Proof:** `grep -rl 'old\.host' /etc/app --include='*.conf' | xargs sudo sed -i 's/old\.host/new.host/g'`

    **Follow-up:** How would you handle file names with spaces? (`grep -rlZ` and `xargs -0`.)

??? question "L2: Print the log lines between 14:12 and 14:13."
    **Say first:** use a regex address range.

    **Proof:** `sed -n '/14:12:/,/14:13:/p' access.log`

    **Follow-up:** What happens if no line matches the end pattern? (The range runs to the end of the file.)

??? question "L2: Swap the first two fields of a line with sed."
    **Say first:** capture groups and back-references.

    **Proof:** `echo 'b a' | sed -E 's/^(\S+) (\S+)/\2 \1/'`

    **Follow-up:** When is `awk` the better tool for this?

??? question "L3: After a deployment script ran sed -i, nginx still serves the old configuration."
    **Say first:** check whether the edited path was a symlink and which file nginx reads.

    **Proof:** `ls -l /etc/nginx/sites-enabled/app.conf` now shows a regular file instead of `-> ../sites-available/app.conf`; the edit went into a copy.

    **Follow-up:** Which `sed` option prevents it, and what else must happen after an edit? (`--follow-symlinks`; `nginx -t` and a reload.)

??? question "L3: A config line was added three times to a file."
    **Say first:** the script appends with `sed -i ... a` on every run without checking.

    **Proof:** `grep -c '^db_timeout' app.conf` returns 3; the script has no guard.

    **Follow-up:** How do you make the change idempotent?

---

## Related

- [grep and Regex](grep-and-regex.md): the regex syntax `sed` uses
- [awk](awk.md): when edits depend on fields
- [Viewing and Comparing](viewing-and-comparing.md): `diff` before and after an edit
- [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md): why `-i` replaces symlinks

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), and macOS 26.6.1 where noted, 2026-09.
