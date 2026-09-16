# awk

`awk` splits every input line into fields and runs `pattern { action }` rules against them. It covers most one-off reporting on logs and command output (filter by a column, sum a column, count by key) without writing a script in another language.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Program shape | `pattern { action }`; a missing pattern matches every line, a missing action prints the line | `awk '/x/'` |
| Fields | `$1`...`$NF`; `$0` is the whole line | `awk '{print $1}'` |
| Built-in variables | `NR` line number, `NF` field count, `FS`/`OFS` input and output separators, `FNR` line number per file | `awk '{print NR, NF}'` |
| Field separator | Whitespace by default; `-F:` or `-F' = '` to change it | `awk -F: '{print $1}' /etc/passwd` |
| Special blocks | `BEGIN` runs before input, `END` after | `awk 'END {print NR}'` |
| Comparisons | Numeric when both sides look numeric: `$9 >= 500` | `awk '$9 >= 500'` |
| Regex match | `$7 ~ /re/`, `$7 !~ /re/` | `awk '$9 !~ /^2/'` |
| Accumulate | `sum += $10` in the body, print in `END` | `awk '{s+=$10} END {print s}'` |
| Associative arrays | `count[$1]++`, then `for (k in count)` | `awk '{c[$1]++} END {for (k in c) print c[k], k}'` |
| Pass shell values | `-v name=value` | `awk -v t=1.5 '$NF > t'` |
| Implementations | `gawk` on RHEL; `mawk` by default on Ubuntu until `gawk` is installed | `readlink -f "$(command -v awk)"` |
| CSV with quoted commas | `gawk --csv` (gawk 5.3 and later) | `awk --csv` |
<!-- --8<-- [end:facts] -->

---

## Fields and Records

The sample access log from [Viewing and Comparing](viewing-and-comparing.md) has 13 whitespace-separated fields per line: `$1` is the client, `$6` the method (with its quote), `$7` the path, `$9` the status, `$10` the bytes and `$NF` the response time.

```bash
awk '{print $1, $9}' access.log | head -3
awk '{print NR": "$NF}' access.log | head -2
awk '{print NF}' access.log | sort -u
awk -F: '{print $1, $7}' /etc/passwd | head -3
awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd
awk -F' = ' '$1 == "db_pool" {print $2}' app-v1.conf
```

Output:

```text
192.0.2.10 200
192.0.2.10 401
192.0.2.10 200
1: 1.237
2: 0.041
13
root /bin/bash
daemon /usr/sbin/nologin
bin /usr/sbin/nologin
ubuntu
laborant
10
```

A comma in `print` inserts the output separator (`OFS`, a space by default); without it, values are joined directly.

---

## Filtering

```bash
awk '$9 >= 500' access.log | cut -c1-60
awk '/POST/ {print $1, $7, $9}' access.log
awk '$9 !~ /^2/ {print $9}' access.log | sort | uniq -c
awk -v threshold=1.5 '$NF > threshold {print $7, $NF}' access.log
```

Output:

```text
192.0.2.10 - - [16/Sep/2026:14:11:35 +0000] "GET /static/app
203.0.113.5 - - [16/Sep/2026:14:13:10 +0000] "GET /static/ap
192.0.2.44 - - [16/Sep/2026:14:14:38 +0000] "GET / HTTP/1.1"
198.51.100.7 - - [16/Sep/2026:14:15:45 +0000] "GET /api/orde
192.0.2.10 /login 401
192.0.2.10 /login 200
203.0.113.99 /login 401
      2 301
      2 401
      1 403
      1 404
      4 500
/static/app.js 1.855
/ 1.551
/api/orders 1.51
/api/orders/42 1.828
```

!!! warning "Pass shell variables with -v, not by quoting tricks"
    `awk "\$NF > $limit"` mixes shell and awk quoting and breaks on unexpected input. `awk -v limit="$limit" '$NF > limit'` keeps the program in single quotes and passes the value safely.

---

## Sums, Averages and Maximums

```bash
awk '{bytes += $10} END {print "total bytes:", bytes}' access.log
awk '{sum += $NF; n++} END {printf "avg response: %.3f s over %d requests\n", sum/n, n}' access.log
awk '$NF > max {max = $NF; line = $7} END {print "slowest:", line, max}' access.log
```

Output:

```text
total bytes: 33441
avg response: 0.862 s over 17 requests
slowest: /static/app.js 1.855
```

Uninitialized variables are 0 or the empty string, so `sum` and `max` need no setup. `printf` controls number formatting; `print` uses the default.

---

## Counting by Key

Associative arrays group values without sorting the input first:

```bash
awk '{count[$1]++} END {for (ip in count) print count[ip], ip}' access.log | sort -rn
awk '{hits[$9]++; bytes[$9] += $10} END {for (c in hits) printf "%s %3d %6d\n", c, hits[c], bytes[c]}' access.log | sort
awk '{print substr($4, 14, 5)}' access.log | uniq -c
```

Output:

```text
6 192.0.2.10
4 198.51.100.23
3 203.0.113.5
2 192.0.2.44
1 203.0.113.99
1 198.51.100.7
200   7  16624
301   2   6864
401   2    236
403   1    790
404   1   3796
500   4   5131
      3 14:10
      3 14:11
      3 14:12
      3 14:13
      3 14:14
      2 14:15
```

The last command counts requests per minute by cutting `HH:MM` out of the timestamp field. `for (k in array)` returns keys in no guaranteed order, hence the `sort`.

---

## Command Output and Two-File Joins

```bash
df -h | awk 'NR > 1 && $5+0 > 1 {print $6, $5}'
ps -eo pid,rss,comm --sort=-rss | awk 'NR <= 4'
awk 'BEGIN {FS=":"; OFS="\t"; print "USER", "SHELL"} $7 ~ /bash/ {print $1, $7}' /etc/passwd
awk '{ $1 = "x.x.x.x"; print }' access.log | head -2 | cut -c1-50
```

Output:

```text
/ 3%
    PID   RSS COMMAND
    578 157572 examiner
    335 18228 systemd-journal
      1 12860 systemd
USER	SHELL
root	/bin/bash
ubuntu	/bin/bash
laborant	/bin/bash
x.x.x.x - - [16/Sep/2026:14:10:00 +0000] "GET /api
x.x.x.x - - [16/Sep/2026:14:10:07 +0000] "POST /lo
```

`$5+0` turns `3%` into the number 3. Assigning to a field rebuilds `$0` with `OFS`, which is how awk masks or rewrites a column.

`NR==FNR` is true only while reading the first file, which turns it into a lookup table for the second:

```bash
awk 'NR==FNR {skip[$1]; next} !($1 in skip)' <(printf '192.0.2.10\n198.51.100.23\n') access.log | awk '{print $1}' | sort -u
```

Output:

```text
192.0.2.44
198.51.100.7
203.0.113.5
203.0.113.99
```

---

## Implementations and CSV

=== "RHEL / Rocky"

    ```bash
    readlink -f "$(command -v awk)"
    awk --version | head -1
    printf 'a,b,"c,d",e\n' | awk -F, '{print NF}'
    printf 'a,b,"c,d",e\n' | awk --csv '{print NF, $3}'
    ```

    Output:

    ```text
    /usr/bin/gawk
    GNU Awk 5.3.0, API 4.0, PMA Avon 8-g1, (GNU MPFR 4.2.1, GNU MP 6.2.1)
    5
    4 c,d
    ```

=== "Ubuntu / Debian"

    ```bash
    update-alternatives --display awk | head -3
    awk -W version 2>&1 | head -1
    ```

    Output:

    ```text
    awk - auto mode
      link best version is /usr/bin/gawk
      link currently points to /usr/bin/gawk
    GNU Awk 5.2.1, API 3.2, PMA Avon 8-g1, (GNU MPFR 4.2.1, GNU MP 6.3.0)
    ```

    Ubuntu ships `mawk` as `awk`; installing `gawk` (as on this machine) moves the alternative to `gawk`. Ubuntu 24.04's gawk 5.2.1 has no `--csv`.

!!! tip "Write portable awk"
    `mawk` lacks GNU extensions such as `gensub()`, `asort()`, `PROCINFO` and `--csv`. Scripts that must run everywhere stick to POSIX awk, or call `gawk` explicitly and install it.

---

## Common Errors

```bash
awk '{print $1' access.log
awk '{print $1}' nosuch.log
```

Output:

```text
awk: cmd. line:1: {print $1
awk: cmd. line:1:          ^ unexpected newline or end of string
awk: fatal: cannot open file `nosuch.log' for reading: No such file or directory
```

### `awk: cmd. line:1:          ^ unexpected newline or end of string`

**Cause:** a brace or quote in the program is not closed.

**Fix:** check the braces; keep the program in single quotes so the shell does not alter it.

### ``awk: fatal: cannot open file `nosuch.log' for reading: No such file or directory``

**Cause:** the input path is wrong or unreadable.

**Fix:** check the path and permissions. When fields come out shifted instead, the separator is wrong: use `-F'\t'` for TSV, `gawk --csv` for quoted CSV, and print `NF` to confirm the count.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What do NR, NF, $0 and $NF mean in awk?"
    **Say first:** `NR` is the current line number, `NF` the number of fields, `$0` the whole line, and `$NF` the last field.

    **Proof:** `awk '{print NR, NF, $NF}' file`

    **Follow-up:** What is `FNR`, and when does it differ from `NR`?

??? question "L1: When would you use awk instead of grep or cut?"
    **Say first:** when the decision or output depends on field values: numeric comparisons, sums, counts per key, or reformatting.

    **Proof:** `awk '$9 >= 500'` compares numbers; `grep` can only match text.

    **Follow-up:** Why does `cut -d' '` fail on `ps` output where `awk` works? (Repeated spaces.)
<!-- --8<-- [end:l1] -->

??? question "L2: Print usernames with a UID of 1000 or higher."
    **Say first:** split `/etc/passwd` on colons and compare field 3.

    **Proof:** `awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd`

    **Follow-up:** Why use `getent passwd` instead of the file on LDAP-joined hosts?

??? question "L2: Find the top 5 client IPs in an access log."
    **Say first:** count by the first field, then sort.

    **Proof:** `awk '{c[$1]++} END {for (k in c) print c[k], k}' access.log | sort -rn | head -5`

    **Follow-up:** How do you do the same with `cut`, `sort` and `uniq`?

??? question "L2: Sum the size of all 500 responses and compute the average response time."
    **Say first:** filter, accumulate, report in `END`.

    **Proof:** `awk '$9 == 500 {b += $10; t += $NF; n++} END {print b, t/n}' access.log`

    **Follow-up:** What happens if no line matches? (Division by zero; guard with `if (n)`.)

??? question "L2: Show filesystems above 80 percent usage."
    **Say first:** skip the header and compare the numeric part of the use column.

    **Proof:** `df -hP | awk 'NR > 1 && $5+0 > 80 {print $6, $5}'`

    **Follow-up:** Why `-P`? (Keeps each filesystem on one line.)

??? question "L3: An alert says the error rate spiked. Show errors per minute from the access log."
    **Say first:** group non-2xx statuses by the minute in the timestamp.

    **Proof:** `awk '$9 >= 500 {m[substr($4, 14, 5)]++} END {for (k in m) print k, m[k]}' access.log | sort`

    **Follow-up:** How would you find which path caused the spike?

??? question "L3: A script's awk report works on RHEL but prints errors on a fresh Ubuntu server."
    **Say first:** check which awk runs; Ubuntu defaults to `mawk`, which lacks GNU extensions.

    **Proof:** `readlink -f "$(command -v awk)"` shows `mawk`; the script uses `gensub()` or `--csv`.

    **Follow-up:** Two fixes? (Install `gawk` and call it explicitly, or rewrite in POSIX awk.)

---

## Related

- [grep and Regex](grep-and-regex.md): the regex syntax used in patterns
- [Cut, Sort, Uniq and Tr](cut-sort-uniq-tr.md): simpler column tools
- [sed](sed.md): line edits without fields
- [Users](../04-users-and-access/users.md): the `/etc/passwd` fields

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
