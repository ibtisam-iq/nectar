# Locale and Encoding

The locale decides language, character encoding, sort order and number format for every program. Scripts that sort, compare or count text give different results under different locales, which is why automation often pins `LC_ALL=C`.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Precedence | `LC_ALL` overrides every `LC_*`, which override `LANG` | `locale` |
| `C` / `POSIX` locale | Byte order, ASCII, English messages; same result on every machine | `LC_ALL=C sort` |
| `C.UTF-8` | Byte-order sorting with UTF-8 characters | `locale -a` |
| System default | `/etc/locale.conf` (RHEL), `/etc/default/locale` (Ubuntu) | `localectl status` |
| Installed locales | `glibc-langpack-*` (RHEL), `locale-gen` (Ubuntu) | `locale -a` |
| Encoding of a file | Detected, not stored | `file -i <file>` |
| Convert encoding | `iconv -f <from> -t <to>` | `iconv -l` |
<!-- --8<-- [end:facts] -->

---

## Reading the Locale

```bash
locale
locale -a
```

Output:

```text
LANG=C.UTF-8
LANGUAGE=
LC_CTYPE="C.UTF-8"
LC_NUMERIC="C.UTF-8"
# ... (trimmed)
LC_ALL=
C
C.utf8
POSIX
```

!!! note "Each LC_ variable controls one category"
    `LC_CTYPE` controls character classes, `LC_COLLATE` sort order, `LC_NUMERIC` number format and `LC_MESSAGES` the message language. `localectl set-locale LANG=en_US.UTF-8` sets the system default once the locale is installed.

---

## Why Scripts Set LC_ALL=C

Sort order depends on `LC_COLLATE`. After `locale-gen en_US.UTF-8`:

```bash
printf 'b\nB\na\nA\n_c\n' > /tmp/names.txt
LC_ALL=C sort /tmp/names.txt | tr '\n' ' '; echo
LC_ALL=en_US.UTF-8 sort /tmp/names.txt | tr '\n' ' '; echo
```

Output:

```text
A B _c a b 
a A b B _c 
```

!!! warning "sort, uniq and comm must agree on the locale"
    `comm` and `join` require input sorted under the same collation they run with. A file sorted in a cron job (`C`) and compared in an interactive shell (`en_US.UTF-8`) produces wrong results without an error.

---

## Encoding

UTF-8 stores `é` in two bytes, so character and byte counts differ (`wc -m` prints characters before `-c` bytes), and the `C` locale counts bytes:

```bash
printf 'caf\xc3\xa9\n' > /tmp/utf8.txt
iconv -f UTF-8 -t ISO-8859-1 /tmp/utf8.txt > /tmp/latin1.txt
file -i /tmp/utf8.txt /tmp/latin1.txt
wc -c -m /tmp/utf8.txt
LC_ALL=C wc -m /tmp/utf8.txt
```

Output:

```text
/tmp/utf8.txt:   text/plain; charset=utf-8
/tmp/latin1.txt: text/plain; charset=iso-8859-1
5 6 /tmp/utf8.txt
6 /tmp/utf8.txt
```

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Why do many scripts set LC_ALL=C?"
    **Say first:** it gives byte-order sorting, ASCII character classes and English messages, so output is the same on every machine and parsing does not break.

    **Proof:** `LC_ALL=C sort` and `LC_ALL=en_US.UTF-8 sort` order the same file differently.

    **Follow-up:** What does `LC_ALL=C` break? (Multibyte characters are counted as bytes.)
<!-- --8<-- [end:l1] -->

??? question "L2: Set the system locale to en_US.UTF-8."
    **Say first:** install it, then set it with `localectl`.

    **Proof:** `sudo localectl set-locale LANG=en_US.UTF-8; localectl status`

    **Follow-up:** Which file does that write on each family?

??? question "L2: Convert a Latin-1 CSV to UTF-8."
    **Say first:** check the encoding, then convert with `iconv`.

    **Proof:** `file -i data.csv; iconv -f ISO-8859-1 -t UTF-8 data.csv > data-utf8.csv`

    **Follow-up:** How do you find the lines that are not valid UTF-8? (`grep -naxv '.*' data.csv` under a UTF-8 locale.)

??? question "L2: Show which locale variables are in effect and which are inherited."
    **Say first:** `locale` prints quoted values for categories inherited from `LANG`.

    **Proof:** `locale` shows `LANG=C.UTF-8` and `LC_CTYPE="C.UTF-8"`.

    **Follow-up:** Which variable wins if `LANG` and `LC_ALL` disagree?

??? question "L3: Every SSH login prints a setlocale warning."
    **Say first:** the client forwards a locale the server does not have.

    **Proof:** `env | grep -E '^(LANG|LC_)'` shows the client value; `locale -a` lacks it; `grep SendEnv /etc/ssh/ssh_config` on the client.

    **Follow-up:** Fix it on the server and on the client. (The warning text is `setlocale: LC_ALL: cannot change locale (de_DE.UTF-8)`.)

??? question "L3: comm reports lines as different even though both files contain them."
    **Say first:** check how each file was sorted.

    **Proof:** `LC_ALL=C sort -c file1` fails while `sort -c file1` passes under the current locale.

    **Follow-up:** How do you make the pipeline deterministic?

---

## Related

- [Variables and Environment](variables-and-environment.md): how `LANG` reaches programs
- [Shell Basics](shell-basics.md): SSH sessions and terminals

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
