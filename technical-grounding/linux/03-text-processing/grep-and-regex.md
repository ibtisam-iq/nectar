# grep and Regex

`grep` prints lines that match a pattern, and regular expressions describe the pattern. Filtering logs, checking configuration and extracting fields during an incident all start here, and interviews test both the flags and the regex syntax.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Common flags | `-i` ignore case, `-v` invert, `-n` line numbers, `-c` count, `-w` whole word, `-x` whole line | `grep -in error app.log` |
| Output only the match | `-o` | `grep -o '[0-9]*' f` |
| Context | `-A N` after, `-B N` before, `-C N` both | `grep -C2 ERROR log` |
| Recursive | `-r` (`-R` follows symlinks); `--include`, `--exclude`, `--exclude-dir` | `grep -r --include='*.conf' x /etc` |
| File names only | `-l` matching, `-L` not matching | `grep -rl TODO .` |
| Quiet test | `-q`; status 0 match, 1 no match, 2 error | `grep -q x f; echo $?` |
| Regex flavors | Basic (default), `-E` extended, `-P` Perl, `-F` fixed string | `grep -E 'a+'` |
| BRE vs ERE | In BRE, `+`, `?`, the bar, parentheses and braces need a backslash to be special | `grep 'a\+'` |
| Anchors | `^` line start, `$` line end, `\b` word boundary | `grep '^#'` |
| Classes | `[0-9]`, `[^a-z]`, `[[:space:]]`, `[[:digit:]]`; `\s`, `\w` in GNU grep | `grep '[[:digit:]]'` |
| Repetition | `*` 0+, `+` 1+, `?` 0 or 1, `{n,m}` (ERE) | `grep -E 'a{2,}'` |
| Dot | Any character; `\.` is a literal dot | `grep -c '\.'` |
| Binary files | Reports "binary file matches"; `-a` treats them as text | `grep -a` |
<!-- --8<-- [end:facts] -->

---

## Basic Matching

All examples run against the sample access log from [Viewing and Comparing](viewing-and-comparing.md).

```bash
grep 'POST' access.log
grep -c ' 500 ' access.log
grep -n 'admin' access.log
grep -i 'mozilla' access.log | wc -l
grep -v 'kube-probe' access.log | wc -l
grep -w 'on' app-v2.conf
grep -x 'tls = enabled' app-v2.conf
```

Output:

```text
192.0.2.10 - - [16/Sep/2026:14:10:07 +0000] "POST /login HTTP/1.1" 401 118 "-" "Mozilla/5.0" 0.041
192.0.2.10 - - [16/Sep/2026:14:11:21 +0000] "POST /login HTTP/1.1" 200 4634 "-" "Mozilla/5.0" 0.808
203.0.113.99 - - [16/Sep/2026:14:15:52 +0000] "POST /login HTTP/1.1" 401 118 "-" "Mozilla/5.0" 0.037
4
13:203.0.113.5 - - [16/Sep/2026:14:14:24 +0000] "GET /admin HTTP/1.1" 403 790 "-" "Mozilla/5.0" 0.092
6
15
feature_x = on
tls = enabled
```

`-w` matched `on` as a whole word and skipped `# app configuration`, where `on` is only part of a word.

---

## Regular Expressions

| Element | Meaning | Example |
|---|---|---|
| `.` | Any single character | `h.t` matches `hat`, `hot` |
| `*` | Previous item 0 or more times | `ab*c` |
| `+` (ERE) | 1 or more | `[0-9]+` |
| `?` (ERE) | 0 or 1 | `https?` |
| `{n,m}` (ERE) | Between n and m times | `[0-9]{1,3}` |
| `[abc]`, `[^abc]` | One of, none of | `[^#]` |
| `^`, `$` | Line start, line end | `^$` is an empty line |
| Vertical bar (ERE), backslash and bar (BRE) | Alternation: either side matches | `GET` or `POST` in one pattern |
| `( )` (ERE) | Group | `(ab)+` |
| `\1` | Back-reference to group 1 | `(.)\1` finds doubled characters |
| `\b`, `\<`, `\>` | Word boundaries (GNU) | `\bport\b` |

Extended and basic syntax give the same result when the special characters are escaped for BRE:

```bash
grep -E '" (4|5)[0-9]{2} ' access.log | wc -l
grep '" \(4\|5\)[0-9]\{2\} ' access.log | wc -l
grep -oE '"(GET|POST) [^ ]+' access.log | sort | uniq -c | sort -rn | head -3
grep -Ev '^\s*(#|$)' app-v1.conf
```

Output:

```text
8
8
      3 "POST /login
      3 "GET /static/app.js
      3 "GET /
listen_port = 8080
db_host = db01.internal
db_pool = 10
log_level = info
feature_x = off
```

The last command removes comments and blank lines, the fastest way to read a long default configuration file.

Special characters behave differently in each flavor:

```bash
grep -E 'a{2,}' <<< $'a\naa\naaa'
echo 'price: $5' | grep '\$5'
echo 'a+b' | grep 'a+b'
echo 'a+b' | grep -E 'a+b'
echo 'a+b' | grep -E 'a\+b'
grep -E '^(.)(.).?\2\1$' <<< $'abba\nabcba\nabcd'
```

Output:

```text
aa
aaa
price: $5
a+b
a+b
abba
abcba
```

In basic syntax, `+` is a literal plus; in extended syntax it means "one or more", so `-E 'a+b'` found no `ab` in `a+b` and printed nothing. The back-reference example finds four- and five-letter palindromes.

!!! warning "Quote every pattern"
    Unquoted, `grep [0-9]* file` is expanded by the shell if a matching file exists, and `$` or `\` are processed before `grep` sees them. Single quotes pass the pattern unchanged.

---

## Extracting Values

```bash
grep -o '^[0-9.]*' access.log | sort -u
grep -oP '(?<=" )\d{3}(?= )' access.log | sort | uniq -c
grep -oP '\d+\.\d+$' access.log | sort -n | tail -1
```

Output:

```text
192.0.2.10
192.0.2.44
198.51.100.23
198.51.100.7
203.0.113.5
203.0.113.99
      7 200
      2 301
      2 401
      1 403
      1 404
      4 500
1.855
```

`-P` enables Perl syntax: `\d`, and look-behind `(?<=...)` and look-ahead `(?=...)`, which match context without including it in `-o` output. `-P` exists in GNU grep, not in BSD or BusyBox grep.

---

## Context, Recursion and Files

```bash
grep -B1 -A1 -n '/admin' access.log | cut -c1-40
grep -r 'listen_port' conf.d
grep -rl 'tls' conf.d
grep -rL 'tls' conf.d
grep -r --include='*.conf' 'db_pool' conf.d
```

Output:

```text
12-203.0.113.5 - - [16/Sep/2026:14:13:17
13:203.0.113.5 - - [16/Sep/2026:14:14:24
14-192.0.2.44 - - [16/Sep/2026:14:14:31 
conf.d/b.conf:listen_port = 8443
conf.d/a.conf:listen_port = 8080
conf.d/b.conf
conf.d/notes.txt
conf.d/a.conf
conf.d/b.conf:db_pool = 20
conf.d/a.conf:db_pool = 10
```

With `-n`, a colon marks the matching line and a dash marks context lines.

---

## Exit Status, Binaries and Self-Matches

```bash
grep -q 'tls' app-v2.conf && echo "tls configured"
grep 'nomatch' app-v2.conf; echo "rc=$?"
grep 'x' /nope; echo "rc=$?"
grep GLIBC_2.34 /usr/bin/ls
grep -a -o 'GLIBC_2\.[0-9]*' /usr/bin/ls | sort -uV | tail -2
```

Output:

```text
tls configured
rc=1
grep: /nope: No such file or directory
rc=2
grep: /usr/bin/ls: binary file matches
GLIBC_2.34
GLIBC_2.38
```

The last command lists the newest glibc symbol versions a binary needs, which explains `GLIBC_2.38 not found` when it runs on an older distribution.

`grep` also matches its own command line in `ps` output:

```bash
sleep 100 &
ps aux | grep sleep
ps aux | grep '[s]leep'
pgrep -a sleep
```

Output:

```text
laborant    3128  0.0  0.0   6116  1004 ?        S    14:23   0:00 sleep 100
laborant    3130  0.0  0.0   7080  2060 ?        S    14:23   0:00 grep sleep
laborant    3128  0.0  0.0   6116  1004 ?        S    14:23   0:00 sleep 100
3128 sleep 100
```

`[s]leep` still matches `sleep`, but the `grep` command line contains `[s]leep`, which the pattern does not match. `pgrep` avoids the problem entirely.

!!! tip "grep -F for fixed strings"
    Searching for text with dots, brackets or slashes (`1.1" 5`, `[error]`, IP addresses) is safer and faster with `-F`, which disables regex parsing.

---

## Common Errors

### `grep: /usr/bin/ls: binary file matches`

**Cause:** the file contains NUL bytes, so `grep` suppresses the matching line.

**Fix:** `grep -a` to treat it as text, or `strings <file> | grep <pattern>`.

### `grep: Invalid regular expression`

**Cause:** an unbalanced bracket or brace, such as `grep '['`.

**Fix:** escape the character (`'\['`) or use `grep -F` for literal text.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between grep, grep -E and grep -F?"
    **Say first:** basic regex needs backslashes for `+ ? | ( ) { }`; `-E` makes them special without escapes; `-F` treats the pattern as a fixed string.

    **Proof:** `grep -E 'a+b'` does not match `a+b`; `grep 'a+b'` does.

    **Follow-up:** When is `-P` needed?

??? question "L1: What does grep return when nothing matches, and why does it matter?"
    **Say first:** exit status 1 for no match and 2 for an error, so scripts can distinguish them.

    **Proof:** `grep nomatch file; echo $?` prints 1.

    **Follow-up:** What does that do to a `set -e` script?
<!-- --8<-- [end:l1] -->

??? question "L2: Show the configuration file without comments and blank lines."
    **Say first:** invert-match an extended pattern.

    **Proof:** `grep -Ev '^\s*(#|$)' /etc/ssh/sshd_config`

    **Follow-up:** How would you also drop lines that start with `;`?

??? question "L2: Count requests per HTTP status code in an access log."
    **Say first:** extract the status field and count.

    **Proof:** `grep -oP '(?<=" )\d{3}(?= )' access.log | sort | uniq -c`

    **Follow-up:** How does `awk '{print $9}'` compare?

??? question "L2: List every file under /etc that mentions a hostname, without printing the lines."
    **Say first:** recursive, file names only.

    **Proof:** `sudo grep -rl 'db01.internal' /etc`

    **Follow-up:** How do you skip a directory? (`--exclude-dir`.)

??? question "L2: Show five lines before and after every OutOfMemoryError in a log."
    **Say first:** context flags.

    **Proof:** `grep -n -C5 OutOfMemoryError app.log`

    **Follow-up:** How do you read compressed rotated logs the same way? (`zgrep`.)

??? question "L3: A monitoring script reports a process as running even after it was stopped."
    **Say first:** check whether the check matches its own `grep`.

    **Proof:** `ps aux | grep myapp | wc -l` returns 1 because of the `grep` line; `pgrep -x myapp` or `grep '[m]yapp'` fixes it.

    **Follow-up:** Why is `pgrep -f` also risky? (It matches full command lines, including the script's.)

??? question "L3: A binary fails with version GLIBC_2.38 not found on an older server."
    **Say first:** compare the glibc versions the binary needs with the ones installed.

    **Proof:** `grep -a -o 'GLIBC_2\.[0-9]*' ./app | sort -uV | tail -1` against `ldd --version`.

    **Follow-up:** What are the fixes? (Build on the oldest target, static linking, or a container.)

---

## Related

- [Viewing and Comparing](viewing-and-comparing.md): the sample log and `zgrep`
- [awk](awk.md): field-based filtering
- [Cut, Sort, Uniq and Tr](cut-sort-uniq-tr.md): counting what `grep` extracts
- [Quoting and Expansion](../01-shell-and-cli/quoting-and-expansion.md): why patterns need quotes

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
