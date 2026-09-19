# Log Parsing Recipes

Most log questions reduce to counting, filtering by time and finding the top offenders, which `grep`, `awk`, `sort` and `uniq` answer in one pipeline. The recipes below run on a real nginx access log and a real SSH authentication log, and each one names the field it relies on.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Count by field | `awk '{print $N}'`, then `sort`, `uniq -c`, `sort -rn`, `head` | Top client IPs |
| nginx combined format fields | `$1` client, `$4` time, `$6` method (with a quote), `$7` path, `$9` status, `$10` bytes | `head -1 access.log` |
| Split on quotes | `awk -F'"' '{print $6}'` gives the user agent | Top user agents |
| Numeric filter | `awk '$9 >= 500'` | 5xx lines |
| Time window | `awk '$4 >= "[17/Sep/2026:05:49" && $4 < "[17/Sep/2026:05:50"'` (same day only) | Requests in one minute |
| Per minute | `awk '{print substr($4, 2, 17)}'`, then `uniq -c` | Traffic shape |
| Sum and average | `awk '{s += $10} END {print s/NR}'` | Bytes per request |
| Only the match | `grep -o` / `grep -oP 'user \K\S+'` | Invalid usernames |
| Live filtering | `tail -f` into `grep --line-buffered` | Watching 5xx |
| Compressed rotations | `zgrep`, or `zcat file.gz` into the same pipeline | Older days |
| Journal as input | `journalctl -u ssh -o cat`, or `-o json` into `jq -r .MESSAGE` | Same pipelines, no files |
| Sort order | `sort -rn` numeric descending; `sort -k4 -rn` by column 4 | Error-rate table |
<!-- --8<-- [end:facts] -->

---

## The Sample Data

An nginx virtual host on Rocky received about five minutes of generated traffic from several loopback addresses (`127.0.0.x`), including one scanner. The log uses nginx's default `main` format.

```bash
cd /var/log/nginx
wc -l shop.access.log; head -2 shop.access.log
```

Output:

```text
970 shop.access.log
127.0.0.1 - - [17/Sep/2026:05:47:22 +0000] "GET /products HTTP/1.1" 200 13 "-" "curl/8.12.1" "-"
127.0.0.12 - - [17/Sep/2026:05:47:22 +0000] "GET / HTTP/1.1" 200 7620 "-" "Mozilla/5.0 (X11; Linux x86_64) Firefox/131.0" "-"
```

| Field | Example |
|---|---|
| `$1` | `127.0.0.12` |
| `$4` | `[17/Sep/2026:05:47:22` |
| `$6` | `"GET` |
| `$7` | `/` |
| `$9` | `200` |
| `$10` | `7620` |

---

## Top Talkers and Status Codes

```bash
awk '{print $1}' shop.access.log | sort | uniq -c | sort -rn | head -5
awk '{print $9}' shop.access.log | sort | uniq -c | sort -rn
```

Output:

```text
    283 127.0.0.11
    201 127.0.0.12
    160 127.0.0.13
     88 127.0.0.14
     69 127.0.0.15
    769 200
     54 404
     50 502
     44 401
     34 500
     19 403
```

### Which endpoints fail

```bash
awk '$9 >= 500 {print $9, $6, $7}' shop.access.log | sort | uniq -c | sort -rn
awk '$9 == 404 {print $7}' shop.access.log | sort | uniq -c | sort -rn | head -6
```

Output:

```text
     50 502 "POST /checkout
     34 500 "GET /api/orders
     14 /favicon.ico
      8 /wp-login.php
      8 /phpmyadmin/
      8 /cgi-bin/luci
      8 /.git/config
      8 /.env
```

The 404 list is a scanner's signature: `/wp-login.php`, `/.env` and `/.git/config` on a site that has none of them.

### Error rate per client

```bash
awk '{n[$1]++; if ($9 >= 400) e[$1]++} END {for (ip in n) printf "%-12s %4d %4d %5.1f%%\n", ip, n[ip], e[ip], 100*e[ip]/n[ip]}' shop.access.log | sort -k4 -rn | head -4
```

Output:

```text
127.0.0.66     48   48 100.0%
127.0.0.22     32    8  25.0%
127.0.0.15     69   15  21.7%
127.0.0.13    160   29  18.1%
```

A client with a 100% error rate and few requests is the scanner; blocking it is a firewall or `deny` rule, not an application fix.

---

## Paths, Agents and Bytes

Query strings make the same page look like different URLs, so the path is split on `?` before counting.

```bash
awk '{split($7, p, "?"); print p[1]}' shop.access.log | sort | uniq -c | sort -rn | head -5
awk -F'"' '{print $6}' shop.access.log | sort | uniq -c | sort -rn
awk '{sum += $10} END {printf "%d requests, %.1f KiB sent\n", NR, sum/1024}' shop.access.log
```

Output:

```text
    287 /products
    233 /
    107 /cart
     99 /static/nginx-logo.png
     50 /checkout
    236 Mozilla/5.0 (X11; Linux x86_64) Firefox/131.0
    232 curl/8.12.1
    231 Mozilla/5.0 (Macintosh) Safari/605.1.15
    223 kube-probe/1.33
     48 Mozilla/5.0 zgrab/0.x
970 requests, 1821.2 KiB sent
```

!!! warning "Splitting on quotes changes the field numbers"
    Splitting on double quotes makes the request line field 2 and the user agent field 6. Mixing that with the space-separated numbering (`$9` for status) is a common source of wrong answers.

---

## Time Windows

The timestamp in `$4` sorts correctly as text within one day, so a string comparison selects a window. `substr` trims it to the minute for a traffic histogram.

```bash
awk '{print substr($4, 2, 17)}' shop.access.log | uniq -c
awk '$4 >= "[17/Sep/2026:05:49" && $4 < "[17/Sep/2026:05:50"' shop.access.log | wc -l
sed -n '/05:50:1/p' shop.access.log | head -2
```

Output:

```text
    110 17/Sep/2026:05:47
    196 17/Sep/2026:05:48
    228 17/Sep/2026:05:49
    187 17/Sep/2026:05:50
    179 17/Sep/2026:05:51
     70 17/Sep/2026:05:52
228
127.0.0.12 - - [17/Sep/2026:05:50:10 +0000] "GET /static/nginx-logo.png HTTP/1.1" 200 368 "-" "curl/8.12.1" "-"
127.0.0.14 - - [17/Sep/2026:05:50:10 +0000] "POST /login HTTP/1.1" 401 179 "-" "kube-probe/1.33" "-"
```

!!! note "Text comparison breaks across months"
    `Sep` sorts after `Oct` as text, so a window that crosses a month or year boundary needs a real date conversion (`mktime` in GNU awk) or `journalctl --since` for journal data.

---

## Correlating with the Error Log

The access log says a request failed; the error log says why.

```bash
grep " 502 " shop.access.log | tail -1
tail -2 shop.error.log
grep -c "connect() failed" shop.error.log
```

Output:

```text
127.0.0.11 - - [17/Sep/2026:05:52:07 +0000] "POST /checkout HTTP/1.1" 502 157 "-" "kube-probe/1.33" "-"
2026/09/17 05:52:07 [error] 2098#2098: *1083 connect() failed (111: Connection refused) while connecting to upstream, client: 127.0.0.11, server: shop.example.test, request: "POST /checkout HTTP/1.1", upstream: "http://127.0.0.1:9099/checkout", host: "shop.example.test"
2026/09/17 05:52:15 [error] 2097#2097: *1111 access forbidden by rule, client: 127.0.0.13, server: shop.example.test, request: "GET /admin HTTP/1.1", host: "shop.example.test"
50
```

50 upstream connection failures match the 50 `502` responses: the checkout backend on port 9099 is not running.

### Watching live

```bash
tail -f shop.access.log | grep --line-buffered " 50[0-9] " & sleep 3; kill %1
```

Output:

```text
127.0.0.11 - - [17/Sep/2026:05:52:21 +0000] "GET /api/orders HTTP/1.1" 500 177 "-" "kube-probe/1.33" "-"
```

Without `--line-buffered`, `grep` holds its output in a buffer when writing to a pipe, and a further stage such as `awk` sees nothing for minutes.

---

## SSH Authentication Failures

The same pipelines work on `/var/log/auth.log`. The sample comes from an Ubuntu host that received password guesses from three loopback addresses, and one successful login. As root:

```bash
cd /var/log
grep "Failed password for invalid" auth.log | head -1
grep -c "Failed password" /var/log/auth.log
grep "Failed password" /var/log/auth.log | grep -oE "from [0-9.]+" | sort | uniq -c | sort -rn
grep -oP "Invalid user \K\S+" /var/log/auth.log | sort | uniq -c | sort -rn | head -5
```

Output:

```text
2026-09-17T05:51:07.166386+00:00 ubuntu-01 sshd[2625]: Failed password for invalid user postgres from 127.0.0.45 port 42045 ssh2
26
     19 from 127.0.0.45
      6 from 127.0.0.46
      1 from 127.0.0.77
      4 deploy
      3 test
      3 postgres
      3 oracle
      3 admin
```

Ubuntu 24.04 writes ISO 8601 timestamps in `auth.log`, so the time recipes above need a different field format there.

### Thresholds and successes after failures

```bash
awk '/Failed password/ {for (i=1;i<=NF;i++) if ($i=="from") print $(i+1)}' /var/log/auth.log | sort | uniq -c | awk '$1 >= 10'
grep "Accepted" auth.log | awk '{print $(NF-3)}' | sort -u | while read ip; do echo "$ip: $(grep -c "Failed password.*from $ip " auth.log) failures before success"; done
```

Output:

```text
     19 127.0.0.45
127.0.0.77: 1 failures before success
```

Looping over the fields to find `from` works whether or not the line contains `invalid user`, which shifts every later field by two.

### From the journal instead of the file

```bash
journalctl -u ssh --since "-10min" -o json --no-pager | jq -r 'select(.MESSAGE|test("Failed password")) | .MESSAGE' | awk '{print $(NF-3)}' | sort | uniq -c
```

Output:

```text
     19 127.0.0.45
      6 127.0.0.46
      1 127.0.0.77
```

!!! tip "Parallel guesses leave their own trace"
    The burst also produced `error: beginning MaxStartups throttling` and `drop connection #12 from [127.0.0.46]:46137 on [127.0.0.1]:22 past MaxStartups`: sshd refused new unauthenticated connections while ten were pending. `grep MaxStartups /var/log/auth.log` is worth adding to a brute-force check.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Which pipeline finds the ten IP addresses with the most requests in an access log?"
    **Say first:** Print the first field, sort, count duplicates, sort by count descending.

    **Proof:** `awk '{print $1}' access.log | sort | uniq -c | sort -rn | head`

    **Follow-up:** Why does `uniq -c` need sorted input?

??? question "L1: Why does grep in the middle of a tail -f pipeline sometimes print nothing?"
    **Say first:** `grep` block-buffers its output when writing to a pipe; `--line-buffered` flushes each line.

    **Proof:** `tail -f access.log | grep --line-buffered " 500 " | awk '{print $7}'`

    **Follow-up:** Which other tools need a similar flag? (`stdbuf -oL`, `sed -u`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Count 5xx responses per endpoint."
    **Say first:** Filter on the status field numerically, print status and path, count.

    **Proof:** `awk '$9 >= 500 {print $9, $7}' access.log | sort | uniq -c | sort -rn`

    **Follow-up:** How do you ignore query strings? (`split($7, p, "?")`.)

??? question "L2: How many requests arrived per minute?"
    **Say first:** Cut the timestamp to the minute and count consecutive values.

    **Proof:** `awk '{print substr($4, 2, 17)}' access.log | uniq -c`

    **Follow-up:** Why is `sort` not needed here? (The log is already in time order.)

??? question "L2: List the IP addresses with at least 10 failed SSH passwords."
    **Say first:** Extract the address after `from` and filter counts.

    **Proof:** `grep "Failed password" /var/log/auth.log | grep -oE "from [0-9.]+" | sort | uniq -c | awk '$1 >= 10'`

    **Follow-up:** Which tool turns this into automatic blocking? (fail2ban.)

??? question "L2: Find the most common user agents."
    **Say first:** Split on double quotes; the agent is field 6.

    **Proof:** `awk -F'"' '{print $6}' access.log | sort | uniq -c | sort -rn | head`

    **Follow-up:** Why can a user agent not be trusted?

??? question "L3: Users report intermittent 502 errors on checkout. Walk through the logs."
    **Say first:** Confirm the 502s and their paths in the access log, then read the matching error log lines for the upstream reason.

    **Proof:** `awk '$9 == 502 {print $7}' access.log | sort | uniq -c`; `grep upstream error.log | tail`; then `ss -tlnp` on the backend port.

    **Follow-up:** How do you tell "backend down" from "backend slow"? (`Connection refused` vs `upstream timed out`.)

??? question "L3: The site was slow between 14:00 and 14:10. What do the logs tell you?"
    **Say first:** Compare request volume and error rates for that window with a normal window, and check the top clients inside it.

    **Proof:** A time-window `awk` filter piped into the per-minute and top-talker recipes; `journalctl --since 14:00 --until 14:10 -p warning` for the host.

    **Follow-up:** Which field would you add to the log format to measure latency? (`$request_time`, `$upstream_response_time`.)

---

## Related

- [awk](../03-text-processing/awk.md): the language behind these recipes
- [cut, sort, uniq and tr](../03-text-processing/cut-sort-uniq-tr.md): counting tools
- [grep and Regular Expressions](../03-text-processing/grep-and-regex.md): `-o`, `-P` and `\K`
- [journalctl](journalctl.md): structured input with `-o json`
- [Log Locations](log-locations.md): which file to parse

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
