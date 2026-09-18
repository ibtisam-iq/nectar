# Linux Plan Decisions

Dated log of every decision that shaped the plan. Later changes are appended with the reason and the commit that applied them.

---

## 2026-09-15: Plan Approved

| # | Decision | Reason |
|---|---|---|
| D1 | Distro-neutral commands first; RHEL / Rocky and Ubuntu / Debian shown in equal tabs where they differ | The course was RHEL-based; most DevOps servers run Ubuntu or Debian |
| D2 | Interview questions live in two places: checkpoints at the end of every topic, and a separate `interview/` layer with rounds, scenarios and mocks | Topic checkpoints support self-testing while learning; the `interview/` layer supports round-by-round preparation |
| D3 | Raw course material moves to a git-ignored `_sources/`, also listed in `exclude_docs`; the third-party resume leaves the repository | Institute PDFs are not the owner's to publish; MkDocs ignores `.gitignore` |
| D4 | Scope is core Linux plus DevOps-relevant topics; Ansible, Git, Python and full shell scripting are covered in their own folders | Keeps the Linux folder focused while nothing is lost (tracked in `_sources/INVENTORY.md`) |
| D5 | Folder-based depth: 21 numbered modules, one focused file per topic, organised in four layers (Learn, Revise, Interview, Practice) | The owner asked for Kubernetes-style depth, with better structure than existing folders |
| D6 | Every topic declares Track (Core, RHCSA, Advanced) and Interview weight (High, Med, Low); weight sets the line budget and the study paths | Certifications demand breadth; interviews reward depth on a smaller set; both are served without slowing revision |
| D7 | The writing benchmark is the persona post, then runbook and blog practice, then Diátaxis and the Google developer documentation style guide; older Nectar pages are not a benchmark | Owner feedback: early Nectar pages predate any documentation standard and include pasted chatbot output |
| D8 | Output format follows runbook practice: `bash` blocks without prompts, captured output in `text` blocks introduced by `Output:` | Replaces an earlier draft that used `console` blocks with prompts |
| D9 | The plan is logged in `plan/` and committed first; `CLAUDE.md`, `GEMINI.md` and a new `AGENTS.md` point to it | Any LLM working in the repository must read the plan and standards before writing a tool folder |
| D10 | Completion is proven by `scripts/audit-tool.py` (16 automated checks against `manifest.yml`), an independent review, and owner sign-off | The owner asked for an A-to-Z check that nothing in the plan is missed |
| D11 | Pilot is module `04-users-and-access` as a vertical slice through all four layers | Uses every template feature, covers all four interview levels, and was a weak area in the first interview |

---

## 2026-09-15: Structure Corrections from Research

| # | Decision | Reason |
|---|---|---|
| D12 | Package management moved from module 10 to module 06 | Later modules need tools installed (RH124 teaches RPM before processes) |
| D13 | `file-transfer.md` moved into `14-ssh-and-remote-access/`; `log-parsing-recipes.md` moved into `09-logging/`; `capabilities.md` moved into `15-security/` | Each depended on a module taught later |
| D14 | New module `11-kernel-and-hardware/` (proc and sys, sysctl, modules, udev, dmesg) placed before storage, networking and security | Those modules use sysctl and kernel modules |
| D15 | Added topics: scripting essentials, locale, file descriptors, JSON and YAML on the CLI, centralized identity, Flatpak, shared libraries, process lifecycle, system calls and tracing, quotas, backup and restore, TCP socket states, reverse proxy, VPN, GPG, OpenSSL trust store, compliance tools, kernel panic, virtual memory, profiling, monitoring, Podman and Quadlet, virtualization and provisioning | Gaps found against RHCSA 10, LFCS, LPIC-1, Linux+ and interview sources |
| D16 | File sharing renamed `18-network-storage/` and treated as core | NFS and autofs are core objectives in RHCSA 10 and LFCS |
| D17 | Stratis and VDO reduced to one line; NIC teaming documented as deprecated | Dropped from RHCSA 9 and 10 objectives; teaming deprecated in RHEL 9 |
| D18 | 19 interview scenarios (not 20 as first drafted). Read-only filesystem is a branch of `permission-denied.md`; kernel panic at boot is a branch of `boot-failure.md` | Count corrected while building `manifest.yml` |
| D19 | Agents commit locally only: no push, no pull requests, no AI attribution lines. The rule is recorded in `plan/README.md`, `CLAUDE.md`, `GEMINI.md` and `AGENTS.md` | An agent pushed a branch and opened a pull request without being asked, with an attribution trailer. That PR was closed, the remote branch deleted, and the commit amended. |

---

## 2026-09-15: Changes During Execution

| # | Decision | Reason |
|---|---|---|
| D20 | `mdformat` removed from the plan (no `requirements-dev.txt`, no `.mdformat.toml`); `scripts/lint-prose.py` enforces the MkDocs list rules instead | Tested on a sample page: `mdformat` rewrites every `---` section break into an underscore line, which conflicts with the writing standard, and has no option to disable it |
| D21 | The local `.venv` was rebuilt on Python 3.14 (old 3.9 environment kept as a backup outside the repository) | `requirements.txt` pins `pymdown-extensions==11.0.2`, which requires Python 3.10 or later; CI uses 3.14 |
| D22 | Captures use the iximiuz `rockylinux` playground (Rocky Linux 10.2) and `ubuntu-24-04` (Ubuntu 24.04.4 LTS). Capture footers state the shared microVM kernel (6.1.167), not a distribution kernel. SELinux output is captured on a local VM, because the Rocky playground ships without SELinux tooling | The playground provides Rocky 10, not 9 (RHCSA is now RHEL 10 based); both playgrounds boot the iximiuz kernel |

---

## 2026-09-16: Pilot Sign-Off

| # | Decision | Reason |
|---|---|---|
| D23 | The owner approved the module 04 pilot and asked to continue with Phase 3; the `CLAUDE.md` Notes Conventions section was added | Phase 2 exit criterion |
| D24 | The third-party resume stays in the git-ignored `_sources/` until Phase 6, where the owner decides its final location | Owner instruction; `_sources/` is never committed or published |

---

## 2026-09-16: Batch A

| # | Decision | Reason |
|---|---|---|
| D25 | Captures note two quirks of the Rocky playground in the pages where they matter: `/usr/bin/ls` comes from `coreutils-single` (a shebang wrapper, so `ldd` fails), and `dnf.conf` sets `tsflags=nodocs` (no man pages until it is removed and packages are reinstalled). Binary and library demos are captured on Ubuntu | Keeps every output real while explaining differences a reader may not see on a full RHEL install |
| D26 | `reference/error-messages.md` is a table per module (error, cause, fix, topic link), fed from each topic's Common Errors section | One searchable page for error text; the topic keeps the captured output |

---

## 2026-09-16: Fedora Fallback

| # | Decision | Reason |
|---|---|---|
| D27 | When one item is missing or broken on the Rocky playground, that item is captured on the iximiuz Fedora playground. The tab label stays `RHEL / Rocky`; a note inside the tab names Fedora and its version; the capture footer names Fedora with its version; any difference from Rocky 10.2 is stated with its version next to the output. SELinux output still comes from a local VM. Pages already written under D25 keep their Ubuntu captures | Owner instruction. Fedora is RHEL's upstream, so its output is closer to RHEL than Ubuntu's, and the notes keep every capture traceable to the machine that produced it |
| D28 | Batch A backfill under D27: the RHEL / Rocky side of the loader demo in `architecture.md` now comes from Fedora 44, because Rocky's `coreutils-single` has no ELF `ls`. The kernel license in `what-is-linux.md` comes from Rocky's repository metadata (`dnf repoquery`), because no playground installs a kernel package. Other Rocky differences in batch A (`tmp.mount` disabled by preset, `tsflags=nodocs`) are real Rocky 10.2 behavior and stay | Owner asked to close Rocky-caused gaps in batch A before batch B |

---

## 2026-09-16: Batch B

| # | Decision | Reason |
|---|---|---|
| D29 | Batch A approved by the owner ("move to batch B") | Batch exit criterion |
| D30 | Batch B captures use two extra sources, each named on the page: the BSD `sed -i` error was captured on macOS 26.6.1 (the only BSD `sed` available), and a binary built on Fedora 44 demonstrates the `GLIBC_2.42 not found` error on Ubuntu 24.04. Setuid, `rpm -V` and `ldd` demos use a compiled C program or Ubuntu where Rocky's `coreutils-single` wrapper scripts would give misleading results | Keeps every error message real and traceable to the machine that produced it |

---

## 2026-09-17: Batch C

| # | Decision | Reason |
|---|---|---|
| D31 | Batch B approved by the owner ("please continue batch c") | Batch exit criterion |
| D32 | The Rocky playground now runs full `coreutils` instead of `coreutils-single` (`dnf swap`), matching a standard RHEL server install; batch A and B pages keep their D25 notes | `ps`, `strace` and `/proc/<pid>/exe` showed the `coreutils` wrapper instead of the real program, which would mislead readers of the process pages |
| D33 | Where the playground kernel lacks a feature (Yama `ptrace_scope`, the `cpu` cgroup controller), pages state the distribution behavior and say it was not captured; D-state demos use `fsfreeze` on a loop-mounted ext4 image | Keeps every output real; `fsfreeze` reproduces a true uninterruptible sleep without NFS |
| D34 | The Process Won't Die scenario combines two capture runs on the same host and says so on the page | The frozen-filesystem run blocked the first script, so its PIDs come from a second run |

---

## 2026-09-17: Batch D

| # | Decision | Reason |
|---|---|---|
| D35 | Batch C approved by the owner ("continue batch d"); the question about admonitions in 21 batch A and B pages stays open | Batch exit criterion |
| D36 | Batch D installs missing logging and scheduling packages on both playgrounds, enables a persistent journal on Rocky and reboots it once for previous-boot captures. Sample log data is generated on the playgrounds and named as such: nginx traffic from loopback addresses (`127.0.0.x`) to a test virtual host, and SSH password guesses against Ubuntu with password authentication enabled by a drop-in for the demo | Real captures need real log lines; loopback source addresses give distinct clients without exposing real IPs |
| D37 | Kernel pages use the playground's iximiuz-built kernel and say so; where a driver is built in there (`br_netfilter`), the page shows that state and states the distribution default without a capture. Hardware-only tools (`sensors`, `ipmitool`) are described, with the VM's empty result where one exists | Keeps every output real while explaining differences from a stock RHEL or Ubuntu kernel |

---

## 2026-09-17: Admonition Check

| # | Decision | Reason |
|---|---|---|
| D38 | Batch D approved by the owner ("finish that audit, and move to the batch e"). `scripts/audit-tool.py` check 3 now counts titled admonitions (two to five per topic). The 21 batch A and B topics below the minimum wrap an existing paragraph in a titled admonition; `linux-vs-windows.md` gets one new note drawn from its captured `/etc/shadow` modes. Pages at their line budget merge two Must-Know Facts rows, and `repositories.md` folds the `tee` echo line into its trim marker | The blueprint rule existed but was not enforced, so batches A and B passed without it; converting existing text adds no unverified facts |

---

## 2026-09-17: Batch E

| # | Decision | Reason |
|---|---|---|
| D39 | Storage pages demonstrate on loop devices and sparse files, and the Disk Full scenario runs on a dedicated 150 MiB logical volume (`/srv/shop`) with a demo service (`shop-api`), so no incident touches the playground's root filesystem. Pages say where a device is a loop device and name the real equivalents (`sdb`, `nvme0n1`) | Real partitioning, LVM, RAID and full-disk captures without risking the playground |
| D40 | Two findings from the captures are stated as version-specific facts: xfsprogs 6.16 with kernel 6.1 shrinks XFS inside the last allocation group (experimental) and refuses to create XFS below 300 MB; LVM 2.03.36 (Rocky) reduces ext4 by itself, while LVM 2.03.16 (Ubuntu 24.04) goes through `fsadm` | The usual rule "XFS cannot shrink" needed the exact boundary, and the two LVM versions print different output |
| D41 | A manual `fsfreeze` before `lvcreate -s` made LVM abort and leave device-mapper entries; the backup page shows the correct sequence and describes the failure in a titled danger admonition instead of printing the partial state | The failure is a useful warning, but the cleanup steps were ad hoc and not part of a teachable block |

---

## 2026-09-17: Batch F

| # | Decision | Reason |
|---|---|---|
| D42 | Batch E approved by the owner ("start batch f") | Batch exit criterion |
| D43 | Module 13 captures run on an iximiuz Labs FlexBox playground with three VMs: `client` (Ubuntu 24.04) on `lan` (172.16.0.0/24), `gw` (Rocky 10.2) on `lan` and `dmz` (172.16.1.0/24), and `web` (Rocky 10.2) on `dmz`. The playground's own gateways (`.1`) do not route between the two networks, so `gw` is a real Linux router | Routing, return paths, DNS, proxies and captures need separate hosts; namespaces alone would hide the ARP and MAC details |
| D44 | Captures pass through a scrubber on each VM: MAC addresses become `02:00:ac:10:<net>:<host>` (or a hashed `02:00:` value for short-lived veth and dummy devices), MAC-derived IPv6 link-local addresses are recomputed from the placeholder, the provider's resolver becomes `192.0.2.53`, public NTP servers become documentation addresses of equal length, and WireGuard public keys become placeholders. Private keys are never printed. RFC 1918 lab addresses stay | The blueprint requires scrubbing MACs, IPs and keys; deterministic placeholders keep the outputs internally consistent |
| D45 | Lab services live on the playground and are named on each page: BIND with the zone `shop.internal` and nginx on `web`, nginx and HAProxy on `gw`, a second nginx backend on `client`, dnsmasq in the lab. NetworkManager manages only `gw`'s `eth1` (the playground configures `eth0` from the kernel command line), netplan manages `client`'s `eth0`, and `client`'s `/etc/resolv.conf` is relinked to the systemd-resolved stub as on a standard Ubuntu install | Real services give real errors (502, SERVFAIL, refused versus filtered) without touching the playground's control path |
| D46 | Findings stated as version-specific facts: RHEL 10 ships no `ifcfg-rh` plugin; NetworkManager 1.56 replaced a foreign static address with an automatic DHCP profile; the RHEL `named` unit refuses to start with a broken zone while `rndc reload` keeps the old data; `timedatectl set-time` reads the local timezone; iputils 20240117 limits unprivileged ping intervals to 2 ms; each nginx worker keeps its own round-robin position | Each surprised the capture session and changes how an operator reads the output |
| D47 | The Networking lab was run end to end on a second, fresh FlexBox playground; the setup gained `iputils-tracepath`, task 6 relinks `/etc/resolv.conf`, and task 10 waits for `web` to synchronize before `gw` uses it | A fresh Ubuntu image lacks `tracepath`, the playground's plain `resolv.conf` bypasses routing domains, and chrony marks an unsynchronized server unusable |


---

## 2026-09-17: Batch G

| # | Decision | Reason |
|---|---|---|
| D48 | Batch F approved by the owner ("please continue... batch g") | Batch exit criterion |
| D49 | Batch G reuses the batch F FlexBox (D43): `client` (Ubuntu), `gw` (Rocky router) and `web` (Rocky). Firewall, SSH, TLS, capabilities and SELinux capture cleanly across the three hosts and the router path, so no new topology was built | The security topics need a client, a server and a router, which the batch F playground already provides |
| D50 | New lab users: `ops` on `client`, `deploy` on `gw` and `web`, plus a chrooted `partner` for the SFTP demo. The playground's own `laborant` (passwordless sudo) is left in place and noted where it appears in hardening output | Real key-based login, sudo and SFTP-jail captures need ordinary accounts distinct from the playground admin |
| D51 | The three Rocky-side security services need packages the playground images omit: firewalld, the SELinux policy and tools, audit, AIDE, OpenSCAP and EPEL `fail2ban` on the servers; ufw, AppArmor tools, auditd, Lynis and debsums on Ubuntu. Both Rocky hosts were relabeled and rebooted once to bring SELinux from permissive (image default) to enforcing | Enforcing SELinux and real firewalls are the point of the module; the images ship neither |
| D52 | SELinux is captured on the Rocky playground hosts, not a local VM as D22/D27 allowed. The iximiuz kernel enables SELinux (`/sys/kernel/security/lsm` = `capability,selinux`), so `getenforce`, labels, ports, booleans and AVCs are all real on `gw` and `web`; the D22 local-VM fallback was not needed | The playground kernel supports SELinux fully, which D22 predated |
| D53 | AppArmor is described, not enforced: the same kernel activates SELinux as its major LSM, so `aa-status` reports "apparmor filesystem is not mounted" on `client`. The page captures that state, the profile syntax and `apparmor_parser` checks, and states Ubuntu's default behavior without claiming an enforcement capture | Two major LSMs cannot both be active; the page stays honest about what the playground can show |
| D54 | OpenSCAP CIS rules return `notapplicable` on both the Rocky and the Fedora playgrounds, because the SSG platform (`machine`) checks reject the microVM images. The page shows the profile list, the scan command and the `notapplicable` result, and explains it, rather than presenting a scan as pass/fail | The result is real and instructive; faking pass/fail would break the output-honesty rule |
| D55 | The scrubber gained three rules for batch G: the post-restart MAC set (D44 placeholders extended to the new addresses), SSH and CA public-key blobs replaced with `AAAA...(public key)`, and kernel-log `MAC=` header fields (14 octets) mapped to placeholders. WireGuard and TLS private keys are never printed | Restarts changed every MAC, and SSH/TLS output carries key material the D44 scrubber did not cover |
| D56 | Findings stated as version-specific facts: firewalld 2.4.3 runs deny rich rules before allow rules unless `priority` is set; `restorecon` keeps a `chcon` label on a customizable type until `-F`; EPEL `fail2ban` pulls in `fail2ban-sendmail` and a setuid `exim`; `sealert` ranked an unrelated boolean at 89% for a label denial; `ausearch` reads stdin when it is a pipe (`--input-logs` needed); OpenSSH 9.8 per-source penalties refuse a whole NAT address after repeated failures | Each surprised the capture session and changes how an operator reads the output |
| D57 | The Security Lab was written from the batch G capture runs on the same FlexBox, as a tutorial with `??? tip "Solution"` blocks; it was not re-run end to end on a fresh playground as batch F's lab was (D47) | Every command in it was already executed during the topic captures; a second full run added little for a tutorial-style lab |

## 2026-09-18: Batch H

| # | Decision | Reason |
|---|---|---|
| D58 | Batch G approved by the owner ("continue batch h") | Batch exit criterion |
| D59 | Batch H reuses the batch F/G FlexBox (D43/D49), restarted from its preserved state. Module 17 (performance) is captured on the Rocky `web` host, which took `sysstat`, `strace`, `perf`, `stress-ng`, GNU `time` and `tuned` from its mirrors cleanly | The performance tools and `/proc` interfaces are all present or installable on one host; no new topology is needed |
| D60 | Module 17 output is captured on Rocky only, with distro tabs used solely for install and package differences. The Ubuntu `client` cannot resolve public mirrors in this topology (`apt` fails with `Temporary failure resolving archive.ubuntu.com`), so `sysstat`/`strace`/`stress-ng` could not be installed there; `top`, `vmstat`, `free`, `ss`, `iostat`, `pidstat`, `sar` and `/proc` produce identical output across distributions, so a single-host capture is faithful | The genuine distro differences are the package names and `tuned` (RHEL only), not the tool output |
| D61 | Module 16 (boot and recovery) captures what the direct-kernel-boot microVM allows: `systemd-analyze`/`blame`/`critical-chain`, `/proc/cmdline` (with the `systemd.random_seed` blob scrubbed), `systemctl get-default`, a real failed unit (`systemd-network-generator`) and `degraded` state, the SysRq and panic sysctls, `core_pattern`, and a real bad-`fstab` `mount -a` error with the `nofail` fix. GRUB, initramfs (`lsinitrd`), `rd.break` and kernel-package operations are shown as commands without output, and the footers say so | The microVM has no GRUB, no initramfs in `/boot` and no `kernel` package (`root=/dev/vda` via direct boot), which D20 already flagged as needing a full VM; the plan allows command-only blocks for these |
| D62 | The scrubber was recreated on the restarted play (the D49 play's `/usr/local/bin/scrub` did not carry over) with deterministic rules for the random-seed blob, base64 key material, MAC addresses and non-lab IPs | Captures must be scrubbed before they reach a page, and the tool did not survive the restart |
| D63 | The OOM capture uses a hand-made cgroup (`/sys/fs/cgroup/oomdemo` with `memory.max=80M`, `memory.swap.max=0`, `oom_score_adj` reset to 0), because `systemd-run --scope` processes inherit `oom_score_adj=-1000` and are unkillable, giving "Out of memory and no killable processes" instead of a kill. The hand-made cgroup produced the real `Memory cgroup out of memory: Killed process ... (python3)` line and exit 137 | The scope path could not demonstrate the classic OOM kill; the manual cgroup does it honestly |
| D64 | No dedicated lab ships with batch H. Modules 16 and 17 feed the Phase 5 `break-fix` lab, so their READMEs name it in prose without a link, and batch H pages avoid "Related" links to batch I files (`high-load-low-cpu`, `high-memory-oom`, module 19 `cgroups`) that do not exist yet | The plan forbids forward links to unbuilt files; the audit link check enforces it |
| D65 | `eBPF`/bcc tools are not installed on the capture host, so the profiling page shows `execsnoop`, `opensnoop` and `bpftrace` as commands without output and the footer says so; `strace -c`, `strace -e openat`, `perf stat` and `perf record`/`report` are all real captures | `perf` reads real PMU counters on this microVM, but the bcc toolkit is absent; the page stays honest about which is captured |
