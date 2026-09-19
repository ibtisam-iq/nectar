# Text Processing

Reading, searching, editing and summarizing text from logs, configuration files and command output, from `grep` to `jq`.

---

## Revision Card

| Fact | Value |
|---|---|
| Follow a rotating log | `tail -F`, not `tail -f` |
| Hidden characters | `cat -A` shows `^M` and tabs |
| `diff` exit status | 0 same, 1 different, 2 error |
| `grep` exit status | 0 match, 1 no match, 2 error |
| BRE vs ERE | Basic regex needs backslashes for `+`, `?`, braces and groups; `grep -E` does not |
| Self-matching `grep` in `ps` | Use `pgrep` or a `[p]attern` |
| `sed -i` | Rewrites the file; replaces symlinks unless `--follow-symlinks`; BSD needs `-i ''` |
| `awk` fields | `$1`...`$NF`; `NR` line, `NF` field count; `-F` separator |
| Ubuntu `awk` | `mawk` until `gawk` is installed |
| `uniq` | Needs sorted input |
| `sort` keys | `-k2,2nr`; options on a key replace global ones |
| `xargs` safety | `-0` with `-print0`; `-r` for empty input |
| `jq -r` | Raw strings for shell variables; missing keys return `null` |
| Two `yq` tools | Go `mikefarah/yq` (EPEL, releases) and Python `kislyuk/yq` (Ubuntu `apt`) |

| Task | Command |
|---|---|
| Last 50 lines, then follow | `tail -n 50 -F <log>` |
| Config without comments | `grep -Ev` with the comment-or-blank pattern from [grep and Regex](grep-and-regex.md) |
| Count a status code | `grep -c ' 500 ' access.log` |
| Replace text in place with a backup | `sed -i.bak 's/old/new/g' <file>` |
| Lines in a time window | `sed -n '/14:12:/,/14:13:/p' <log>` |
| Sum a column | `awk '{s += $10} END {print s}' <log>` |
| Top 10 values of a field | `cut -d' ' -f1 <log>` into `sort`, `uniq -c`, `sort -rn`, `head` |
| Compare sorted lists | `comm -12 a b` |
| Parallel commands | `xargs -P4 -I{} <cmd> {}` |
| Extract a JSON field | `jq -r '.items[].metadata.name'` |
| Edit YAML in place | `yq -i '.spec.replicas = 3' <file>` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Viewing and Comparing](viewing-and-comparing.md) | `less`, `head`, `tail -F`, `cat -A`, `diff`, `cmp`, compressed logs, checksums, base64 | Core | Med |
| [grep and Regex](grep-and-regex.md) | Flags, BRE, ERE and PCRE, extraction, recursion, exit status | Core | High |
| [sed](sed.md) | Substitution, addresses, in-place edits, symlink and BSD pitfalls | Core | High |
| [awk](awk.md) | Fields, filters, sums, arrays, joins, `mawk` vs `gawk` | Core | High |
| [Cut, Sort, Uniq and Tr](cut-sort-uniq-tr.md) | Column tools, sort keys, counting, `paste`, `join`, `comm`, `bc` | Core | High |
| [xargs and tee](xargs-and-tee.md) | Arguments from input, safe names, parallel runs, logging pipelines | Core | Med |
| [JSON and YAML on the CLI](json-and-yaml-on-cli.md) | `jq` queries and reshaping, `yq` edits and conversion | Core | Med |

---

## Scenarios and Labs

- [Round 1: Screening](../interview/round-1-screening.md): the L1 questions from this module
- [Error Messages](../reference/error-messages.md): errors from these tools and their causes
