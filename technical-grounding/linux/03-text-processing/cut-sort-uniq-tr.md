# Cut, Sort, Uniq and Tr

Small single-purpose filters combine into the pipelines that answer most log questions: which client sent the most requests, which values appear in both lists, how many unique errors occurred. Each tool does one job, and most mistakes come from their defaults.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `cut -d X -f N` | Field N split on exactly one character; repeated delimiters give empty fields | `cut -d: -f1 /etc/passwd` |
| `cut -c` | Character positions | `cut -c1-10` |
| `sort` default | Text order by locale; `10` sorts before `9` | `sort nums.txt` |
| Numeric sorts | `-n` numbers, `-h` human sizes (`2G`), `-V` versions (`v1.10`) | `sort -h` |
| Sort by field | `-t` separator, `-k2,2` one field; `-k2` means field 2 to end of line | `sort -t: -k3,3n` |
| Key options | An option on a key (`-k2n`) replaces all global ordering options for that key | `sort -k2,2nr` |
| `uniq` | Removes adjacent duplicates only, so sort first | `uniq -c` after `sort` |
| Counting | `uniq -c`; `-d` only repeated lines; `-u` only unique lines | `uniq -c` |
| `sort -u` | Sort and deduplicate in one step | `sort -u f` |
| `tr` | Translate, squeeze (`-s`) or delete (`-d`) characters; reads stdin only | `tr 'a-z' 'A-Z'` |
| `paste`, `join`, `comm` | Merge lines side by side, join on a key, compare sorted lists | `comm -12 a b` |
| Decimal math | `bc` or `awk`; `$(( ))` is integer only | `awk 'BEGIN {print 10/3}'` |
<!-- --8<-- [end:facts] -->

---

## cut

```bash
cut -d: -f1,7 /etc/passwd | head -3
cut -d' ' -f1 access.log | head -2
cut -c1-10 access.log | head -2
```

Output:

```text
root:/bin/bash
daemon:/usr/sbin/nologin
bin:/usr/sbin/nologin
192.0.2.10
192.0.2.10
192.0.2.10
192.0.2.10
```

`cut` treats every delimiter as a boundary, so command output padded with spaces yields empty fields; `awk` splits on runs of whitespace:

```bash
ps -eo pid,user,comm | head -3 | cut -d' ' -f2
ps -eo pid,user,comm | head -3 | awk '{print $2}'
```

Output:

```text



USER
root
root
```

---

## sort

```bash
printf '10\n9\n100\n' | sort
printf '10\n9\n100\n' | sort -n
printf '1K\n512M\n2G\n' | sort -h
printf 'v1.10\nv1.9\nv1.2\n' | sort -V
sort -t: -k3,3n /etc/passwd | tail -3 | cut -d: -f1,3
awk '{print $9, $NF}' access.log | sort -k2,2nr | head -3
```

Output:

```text
10
100
9
9
10
100
1K
512M
2G
v1.2
v1.9
v1.10
ubuntu:1000
laborant:1001
nobody:65534
500 1.855
500 1.828
301 1.551
```

A key with its own option ignores the global ones:

```bash
printf 'x 2\ny 10\nz 1\n' | sort -k2n -r
printf 'x 2\ny 10\nz 1\n' | sort -k2,2nr
```

Output:

```text
z 1
x 2
y 10
y 10
x 2
z 1
```

`-k2n -r` sorted ascending, because `n` on the key replaced the global `-r`. Put every ordering option on the key (`-k2,2nr`).

| Option | Effect |
|---|---|
| `-n`, `-h`, `-V` | Numeric, human-readable, version order |
| `-r` | Reverse |
| `-f` | Ignore case |
| `-u` | Output unique lines only |
| `-t X -k M,N` | Fields M to N, separated by `X` |
| `-o file` | Write to a file, safe even when it is the input |
| `-c` | Check whether input is sorted |
| `-S 1G`, `--parallel=4` | Memory buffer and threads for large files |

---

## uniq

```bash
printf 'b\na\nb\na\n' | uniq
printf 'b\na\nb\na\n' | sort | uniq
printf 'b\na\nb\nc\n' | sort | uniq -c
printf 'b\na\nb\nc\n' | sort | uniq -d
printf 'b\na\nb\nc\n' | sort | uniq -u
```

Output:

```text
b
a
b
a
a
b
      1 a
      2 b
      1 c
b
a
c
```

`uniq` alone changed nothing, because no duplicate lines were adjacent.

The classic "top N" pipeline:

```bash
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -3
```

Output:

```text
      6 192.0.2.10
      4 198.51.100.23
      3 203.0.113.5
```

!!! tip "Read the pipeline in four steps"
    Extract the field, sort so equal values are adjacent, count them, then sort the counts numerically in reverse. The same shape answers top paths, top status codes and top error messages.

---

## tr

```bash
echo "Hello World" | tr 'a-z' 'A-Z'
echo "a  b   c" | tr -s ' '
echo "id: 42-x" | tr -d -c '0-9\n'
echo "PATH:with:colons" | tr ':' '\n'
printf 'win\r\n' | tr -d '\r' | od -c | head -1
```

Output:

```text
HELLO WORLD
a b c
42
PATH
with
colons
0000000   w   i   n  \n
```

`-c` complements the set, so `-d -c '0-9\n'` deletes everything except digits and newlines. `tr` reads only stdin: `tr a b file` is an error, `tr a b < file` works.

---

## paste, join, comm and split

```bash
paste -d, <(printf 'web01\nweb02\n') <(printf '10.0.0.1\n10.0.0.2\n')
printf 'a\nb\nc\nd\n' | paste - -
printf '1 apache\n2 nginx\n' > ids.txt; printf '1 80\n2 443\n' > ports.txt
join ids.txt ports.txt
printf 'a\nb\nc\n' > left.txt; printf 'b\nc\nd\n' > right.txt
comm left.txt right.txt
comm -12 left.txt right.txt
seq 1 10 > nums.txt
split -l 4 -d nums.txt part_
ls part_*; cat part_02
```

Output:

```text
web01,10.0.0.1
web02,10.0.0.2
a	b
c	d
1 apache 80
2 nginx 443
a
		b
		c
	d
b
c
part_00
part_01
part_02
9
10
```

`comm` prints three columns: only in the first file, only in the second, in both; `-12` keeps the third. `join` and `comm` need sorted input.

---

## Arithmetic with bc

```bash
echo '2.5 * 4 + 1' | bc
echo 'scale=3; 10/3' | bc
awk "BEGIN {print 10/3}"
echo $((10/3))
column -t -s: <(head -3 /etc/passwd | cut -d: -f1,3,7)
```

Output:

```text
11.0
3.333
3.33333
3
root    0  /bin/bash
daemon  1  /usr/sbin/nologin
bin     2  /usr/sbin/nologin
```

`column -t` aligns delimited text into a table for reading.

---

## Common Errors

```bash
sort -c access.log; echo "rc=$?"
```

Output:

```text
sort: access.log:14: disorder: 192.0.2.44 - - [16/Sep/2026:14:14:31 +0000] "GET /api/orders/42 HTTP/1.1" 404 3796 "-" "curl/8.5.0" 0.549
rc=1
```

### `sort: access.log:14: disorder:`

**Cause:** the file is not sorted in the current locale's order; `comm`, `join` and `uniq` then give wrong results.

**Fix:** sort both inputs with the same `LC_ALL` before comparing.

### `bash: bc: command not found`

**Cause:** `bc` is not installed on minimal images.

**Fix:** install `bc`, or compute in `awk "BEGIN {print ...}"`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Why does uniq need sorted input?"
    **Say first:** `uniq` compares each line only with the previous one, so duplicates must be adjacent.

    **Proof:** `printf 'b\na\nb\n' | uniq` prints all three lines; adding `sort` first leaves two.

    **Follow-up:** What does `sort -u` do differently? (Sorts and deduplicates in one process.)

??? question "L1: Why does sort put 10 before 9, and how do you fix it?"
    **Say first:** the default is text order, compared character by character; `-n` compares numbers, `-h` sizes, `-V` versions.

    **Proof:** `printf '10\n9\n' | sort -n`

    **Follow-up:** Which option sorts `du -h` output correctly?
<!-- --8<-- [end:l1] -->

??? question "L2: Show the top 10 client IPs in an access log with their counts."
    **Say first:** extract, sort, count, sort by count.

    **Proof:**

    ```bash
    cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -10
    ```

    **Follow-up:** How would you exclude health checks first?

??? question "L2: Sort /etc/passwd by UID and show the three highest."
    **Say first:** numeric sort on field 3 with a colon separator.

    **Proof:** `sort -t: -k3,3n /etc/passwd | tail -3`

    **Follow-up:** What goes wrong with `-k3` without `,3`?

??? question "L2: List users present in both of two exported user lists."
    **Say first:** sort both, then `comm -12`.

    **Proof:** `comm -12 <(sort list1) <(sort list2)`

    **Follow-up:** How do you list users only in the first file?

??? question "L2: Convert a colon-separated PATH into one directory per line."
    **Say first:** translate colons to newlines.

    **Proof:** `echo "$PATH" | tr ':' '\n'`

    **Follow-up:** How would you find duplicate entries? (`sort | uniq -d`.)

??? question "L3: A report of repeated errors shows every error once, though the log has many duplicates."
    **Say first:** check whether the pipeline sorts before `uniq`.

    **Proof:** the pipeline is `grep ERROR app.log | uniq -c`; duplicates are not adjacent because other lines separate them in time.

    **Follow-up:** How do you ignore the timestamp so that equal messages group together? (`cut` the message field first, or `uniq -f N`.)

??? question "L3: A script sorts by the second column in reverse, but the output is ascending."
    **Say first:** check the key definition for per-key options.

    **Proof:** `sort -k2n -r` ignores `-r` for the key; `sort -k2,2nr` works.

    **Follow-up:** Why does `-k2` without an end field cause surprises too?

---

## Related

- [awk](awk.md): counting and summing in one tool
- [grep and Regex](grep-and-regex.md): selecting lines before counting
- [Locale and Encoding](../01-shell-and-cli/locale-and-encoding.md): why sort order depends on `LC_COLLATE`
- [xargs and tee](xargs-and-tee.md): the next stage of a pipeline

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
