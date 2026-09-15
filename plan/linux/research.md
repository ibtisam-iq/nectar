# Linux Plan Research

Summary of the three checks that verified the structure in [`plan.md`](plan.md). Performed 2026-09-15. Frequency tags come from roughly 15 interview sources and are approximate.

---

## 1. Certification Objectives

| Curriculum | Version | Source quality |
|---|---|---|
| Red Hat RHCSA EX200 | RHEL 10 | Official exam page |
| Red Hat RHCSA EX200 | RHEL 9 | Secondary (study guide); Red Hat no longer publishes the list |
| Red Hat RH124 / RH134 | v10 | Official course pages |
| Linux Foundation LFCS | Current domains | Official |
| LPI LPIC-1 | v5.0 (101-500, 102-500) | Official wiki |
| CompTIA Linux+ | XK0-006 | Secondary (official PDF not fetchable) |
| LPI LPIC-2 | v4.5 titles | Official wiki |

**Gaps found in the first draft and fixed:** shell scripting, Flatpak, RHEL subscription, power states, VFAT and removable media, NAT and port redirection, bridges, virtualization and provisioning (KVM, cloud-init, Kickstart), Podman containers (RHCSA 9), centralized identity (LDAP, SSSD), reverse proxies, GPG, compliance and integrity tools, shared libraries, udev, backup, quotas, monitoring concepts, kernel crash handling, localisation.

**Ordering problems found and fixed:** packages taught after tools that need installing; file transfer before SSH; log parsing before logging; sysctl and kernel modules after their first use; capabilities before processes; SSH troubleshooting before SELinux.

**Deliberately skipped:** GUI and X11 configuration, accessibility, CUPS, MTA, kernel compilation, alternate bootloaders, and running BIND, DHCP, Apache, Squid, OpenLDAP, mail or FTP servers.

The objective-by-objective mapping is maintained in `technical-grounding/linux/reference/coverage-map.md`.

---

## 2. Interview Topics

**How rounds work across sources:**

- **Screening (L1):** short concept checks (process vs thread, hard vs soft link, `df` vs `du`, load average, zombies, start vs enable).
- **Hands-on (L2):** live shell tasks (log one-liners, `find`, `jq`, fixing a unit, cron, permissions).
- **Troubleshooting (L3):** open-ended symptoms; the path (clarify, hypothesise, ordered checks) is scored, not only the answer.
- **Internals (L4):** senior and SRE loops drill from "the server is slow" into syscalls, memory, scheduler and TCP; real `top`, `vmstat` and `iostat` output is shown and interpreted.

**Highest-frequency topics (weighted High in the manifest):** disk full (blocks, inodes, deleted-but-open files), load average including D state, `free` and available memory, OOM and exit 137, zombie vs D state, TERM vs KILL, fork and exec, inodes and links, directory permission semantics, how sudo works, `ss`, `lsof` and `strace`, name resolution order, `~/.ssh` permissions, start vs enable and `journalctl`, the cron environment, the boot sequence, namespaces and cgroups, `2>&1` ordering.

**Internals gaps found and fixed:** system calls, process lifecycle (copy-on-write, reaping, daemons, sessions), file descriptor internals, virtual memory and page cache, TCP socket states, shared libraries, kernel panic, profiling with perf and eBPF.

**Scenarios added:** service unreachable, cron job not running, high load with low CPU, too many open files, cannot fork, process will not die, cannot reach host, TLS certificate errors, binary will not execute, suspected compromise, cannot log in or use sudo.

**Over-weighted in the first draft (kept short):** Samba, Stratis and VDO, NIC teaming, GRUB passwords, livepatch, snap and Flatpak, tuned profiles.

**Sources:**

- [bregman-arie/devops-exercises (Linux)](https://github.com/bregman-arie/devops-exercises/blob/master/topics/linux/README.md)
- [chassing/linux-sysadmin-interview-questions](https://github.com/chassing/linux-sysadmin-interview-questions)
- [trimstray/test-your-sysadmin-skills](https://github.com/trimstray/test-your-sysadmin-skills)
- [Linux Performance Analysis in 60 Seconds (Brendan Gregg)](https://www.brendangregg.com/Articles/Netflix_Linux_Perf_Analysis_60s.pdf)
- [USE Method: Linux Performance Checklist](https://www.brendangregg.com/USEmethod/use-linux.html)
- [Linux Load Averages](https://www.brendangregg.com/blog/2017-08-08/linux-load-averages.html)
- [SadServers scenarios](https://sadservers.com/scenarios)
- [Google SRE interview handbook (AceInterviews)](https://github.com/AceInterviews/google-sre-interview-handbook)
- [sre-interview-prep-guide](https://github.com/mxssl/sre-interview-prep-guide)
- [what-happens-when](https://github.com/alex/what-happens-when)
- [Linux Page Cache for SRE](https://biriukov.dev/docs/page-cache/0-linux-page-cache-for-sre/)
- [KodeKloud Linux interview questions (2026)](https://kodekloud.com/blog/linux-interview-questions/)

---

## 3. Course Inventory

- About 50 session handouts (RHCSA-oriented, RHEL 9 in VirtualBox), 2 slide PDFs, an extracted notes folder of 68 files, and a 62 MB zip that duplicates that folder.
- Two interview question PDFs: about 170 short questions (course-ordered, fresher level) and about 600 long questions (RHEL 6 and 7 era; Veritas, cluster and mail sections are legacy).
- Assignments and exam practice (RHCSA and RHCE tasks) are the input for `labs/rhcsa-style-tasks.md`.
- Known errors in the handouts are corrected, never copied (tar `-f` means file and `-t` lists contents; `mkdir -p` means parents; GRUB passwords use `grub2-setpassword`; `option routers`; `hosts allow`; `--privileged`).
- Every course topic maps to a Linux topic file or to a deferred tool folder (Ansible, Apache, MariaDB, DHCP). The item-by-item map is `_sources/INVENTORY.md` (git-ignored, written in Phase 1).

---

## 4. Writing Standard Sources

- [My Core AI Engineering Persona](https://blog.ibtisam-iq.com/my-core-ai-engineering-persona/) (hard rules).
- Runbook meta prompts (`runbook/docs/_meta/`) and published pages edited after 2026-06-25; blog posts (zero em dashes in prose).
- [Diátaxis](https://diataxis.fr/).
- [Google developer documentation style guide](https://developers.google.com/style).
