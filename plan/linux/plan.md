# Linux Plan

Rebuild `technical-grounding/linux/` into a complete Linux notebook and interview kit that serves four uses: learning a topic in depth, revising before an interview, preparing for interview rounds, and day-to-day lookup. Linux is the pilot tool; its layout becomes the template for every later tool folder.

**Approved:** 2026-09-15. **Standards:** [`../standards/`](../standards/). **Decisions:** [`decisions.md`](decisions.md). **Research:** [`research.md`](research.md). **Progress:** [`checklist.md`](checklist.md).

---

## Context

- The first DevOps interview exposed gaps in fundamentals, not in advanced topics. The notes must make fundamentals fast to revise and hard to forget.
- Before this plan, `technical-grounding/linux/` was effectively empty: `Linux.md` held one URL, `cheatSheet.md` and `troubleshooting.md` were empty, `STDOUT_STDERR_Guide.md` was beginner-level, and `tar-command.md` was narrow.
- Red Hat diploma material (about 50 session handouts, institute PDFs, a duplicate 62 MB zip, and a third-party resume) sat untracked in `rhcsa/` and `NOTES/`.

---

## Scope

- **In scope:** core Linux administration and internals, plus everything DevOps work depends on (container primitives, network storage, virtualization and provisioning basics).
- **Distro approach:** distro-neutral commands first; RHEL and Ubuntu shown in equal tabs where they differ.
- **Out of scope (skipped):** GUI and X11 configuration, accessibility, CUPS printing, mail transfer agents, kernel compilation, and running BIND, DHCP, Apache, Squid, OpenLDAP or FTP servers.
- **Out of scope (covered elsewhere):** Git (`delivery/git/`), Python (`technical-grounding/python/`), Ansible and IaC (future tool folders), full shell scripting (`technical-grounding/bash/`, a later tool). `_sources/INVENTORY.md` records every deferred item and its target.

---

## Verified Structure

The structure was checked against certification objectives, interview sources and the course inventory (details in [`research.md`](research.md)). The authoritative file list, with Track, Weight and internals flags, is [`manifest.yml`](manifest.yml).

Markers: `(I)` internals topic that feeds round 4; `→` links to an existing Nectar or runbook page instead of duplicating it.

```text
technical-grounding/linux/
├── README.md        # the 4 layers, module map, study paths (15-min / 1-hour / 1-week / 30-day), out-of-scope list
├── roadmap.md       # checkbox tracker for every topic and lab, with Track and Weight columns
│
├── 00-foundations/
│   ├── what-is-linux.md              # Unix → GNU → Torvalds 1991; GPLv2, copyleft vs permissive; where Linux runs
│   ├── kernel-vs-os-vs-distro.md     # kernel vs GNU userland vs shell vs distro; the GNU/Linux naming debate
│   ├── distributions.md              # families, why so many, LTS vs rolling, Alpine/musl, CPU architectures
│   ├── linux-vs-windows.md           # security argued by mechanism; why servers run Linux
│   ├── architecture.md               # hardware → kernel → syscalls → libc → shell → apps; kernel vs user space; X11 vs Wayland
│   └── system-information.md         # uname, /etc/os-release, lscpu, lsmem, free, lsblk, lspci, lsusb, lshw, dmidecode, uptime
│
├── 01-shell-and-cli/
│   ├── shell-basics.md               # terminal vs shell vs console, virtual consoles and getty, command anatomy, history, shortcuts
│   ├── getting-help.md               # man sections, man -k, --help, info, /usr/share/doc, type/which/whereis
│   ├── command-resolution.md         # alias → keyword → function → builtin → PATH hash; "command not found" ladder
│   ├── variables-and-environment.md  # shell vs environment variables, export, PATH, login vs non-login startup files
│   ├── locale-and-encoding.md        # LANG, LC_*, LC_ALL=C sort gotcha, localectl, iconv, UTF-8
│   ├── quoting-and-expansion.md      # quotes, globs, brace, $(...), arithmetic, expansion order, --, odd filenames
│   ├── streams-and-redirection.md    # fd 0/1/2, 2>&1 order, &>, tee, here-docs, /dev/null, pipes, SIGPIPE, pipefail (absorbs STDOUT guide)
│   ├── exit-codes-and-chaining.md    # $?, && || ;, 0/1/2/126/127/128+n/130/137/143
│   ├── text-editors.md               # vim survival keys, nano, EDITOR → ../../vim/
│   └── scripting-essentials.md       # RHCSA-level if/test, case, loops, positional parameters, read, functions → ../../bash/
│
├── 02-files-and-filesystem/
│   ├── filesystem-hierarchy.md       # FHS, usrmerge, /tmp vs /var/tmp, /run, /srv, /opt
│   ├── file-types.md                 # - d l c b s p with working FIFO and socket examples; decoding ls -l
│   ├── navigation-and-listing.md     # pwd, cd, ls flags, tree, absolute vs relative paths
│   ├── file-operations.md            # mkdir -p, touch, cp -a vs -r, mv semantics, rm, sparse files, dd basics, curl/wget
│   ├── inodes-and-links.md           # inode contents, a/m/ctime, hard vs soft links, what rm does (unlink)
│   ├── file-descriptors.md       (I) # fd table → open file description → inode; fork inheritance, dup2, O_APPEND/CLOEXEC, epoll
│   ├── finding-files.md              # find (size/mtime/perm/user, -exec vs xargs, -delete), locate/updatedb
│   └── archiving-and-compression.md  # tar (absorbs tar-command.md), gzip/bzip2/xz/zstd, zip/7z, cpio
│
├── 03-text-processing/
│   ├── viewing-and-comparing.md      # cat/less/head/tail -F, wc, nl, od, diff/sdiff/cmp, zcat/zgrep, checksums, base64
│   ├── grep-and-regex.md             # flags, BRE/ERE/PCRE, patterns worth memorising
│   ├── sed.md                        # s///, -i with backup, addresses, bulk replace with find + sed
│   ├── awk.md                        # fields, -F, patterns, BEGIN/END, sums, printf
│   ├── cut-sort-uniq-tr.md           # plus paste, split, join, comm, bc
│   ├── xargs-and-tee.md              # -0 -n -P -I, parallel runs
│   └── json-and-yaml-on-cli.md       # jq on AWS CLI and kubectl output, yq → ../../yaml/
│
├── 04-users-and-access/              # PILOT MODULE
│   ├── users.md                      # UID ranges, /etc/passwd, useradd/usermod/userdel, adduser, /etc/skel, login.defs, getent
│   ├── groups.md                     # primary vs secondary, group/gshadow, gpasswd, newgrp, id
│   ├── passwords-and-aging.md        # /etc/shadow fields and hash formats, passwd, chage, lock/expire, nologin, rbash
│   ├── sudo-and-su.md                # su vs su - vs sudo -i, sudoers and sudoers.d, visudo -c, wheel vs sudo, how sudo works (I), polkit
│   ├── pam.md                        # stack basics, pam_faillock, pam_pwquality/pwhistory, pam_limits
│   ├── login-sessions.md             # who, w, last, lastb, lastlog, utmp/wtmp/btmp
│   └── centralized-identity.md       # nsswitch, sssd, realm join, ldapsearch, kinit/klist
│
├── 05-permissions/
│   ├── basic-permissions.md          # rwx on files vs directories, chmod, chown/chgrp, -R gotchas
│   ├── umask.md                      # calculation and where it is set
│   ├── special-permissions.md        # SUID/SGID/sticky, collaboration directories, s vs S, real vs effective UID
│   ├── acl.md                        # getfacl/setfacl, default ACLs, mask, the + in ls
│   └── file-attributes.md            # chattr +i/+a, lsattr
│
├── 06-package-management/
│   ├── packaging-concepts.md         # repositories, dependencies, signing, rpm and deb naming, architectures
│   ├── rpm-and-dnf.md                # rpm queries and verify, dnf provides/history undo, versionlock/exclude
│   ├── dpkg-and-apt.md               # dpkg queries and verify, apt, apt-cache policy, apt-mark hold, debsums
│   ├── repositories.md               # adding repos and keys, local ISO repo, subscription-manager
│   ├── flatpak-and-snap.md           # remotes, install, system vs --user
│   ├── shared-libraries.md       (I) # ELF, ld.so, ldd, ldconfig, LD_LIBRARY_PATH/LD_PRELOAD
│   └── other-install-methods.md      # /usr/local binaries, build from source, update-alternatives, pip/npm, zypper/rpm2cpio
│
├── 07-processes/
│   ├── process-fundamentals.md       # program vs process vs thread, PID/PPID, PID 1, process tree
│   ├── process-lifecycle.md      (I) # fork, COW, exec, wait, exit, SIGCHLD, reaping, daemons, sessions and TTY
│   ├── viewing-processes.md          # ps, pstree, top/htop fields, pgrep, pidof, watch
│   ├── process-states.md             # R S D Z T I, zombie vs orphan, D state and load average
│   ├── signals.md                    # TERM/KILL/HUP/INT/STOP/CONT, kill -0, pkill/killall, trap, delivery (I)
│   ├── job-control.md                # &, jobs, fg/bg, Ctrl-C/D/Z, nohup, disown, tmux
│   ├── priority-and-nice.md          # nice/renice, ionice, chrt, scheduler (CFS to EEVDF in 6.6)
│   └── system-calls-and-tracing.md (I) # syscall path, errno, vDSO, strace, ltrace, /proc/PID/stack, gdb/pstack
│
├── 08-systemd-and-services/
│   ├── init-and-targets.md           # SysV to systemd, runlevel and target table, default target, isolate, power states
│   ├── systemctl.md                  # start/enable/mask, reading status, --failed
│   ├── unit-files.md                 # unit types, path precedence, Type=, Restart=, After= vs Wants=, drop-ins, socket units
│   ├── writing-a-service.md          # script to enabled service, hardening directives
│   └── systemd-toolbox.md            # systemd-analyze, loginctl, systemd-tmpfiles, systemd-run
│
├── 09-logging/
│   ├── log-locations.md              # /var/log map, RHEL vs Ubuntu
│   ├── journalctl.md                 # filters, persistence, vacuum, journald.conf, logger, systemd-cat
│   ├── rsyslog.md                    # facility.priority, rules, remote logging
│   ├── logrotate.md                  # copytruncate vs create, -d dry run
│   └── log-parsing-recipes.md        # access logs, auth failures, journal plus awk
│
├── 10-scheduling/
│   ├── cron-and-at.md                # syntax, crontabs, cron.d, anacron, environment gotchas, MAILTO, allow/deny, at/batch
│   └── systemd-timers.md             # OnCalendar, Persistent=, list-timers, timers vs cron
│
├── 11-kernel-and-hardware/
│   ├── proc-and-sys.md               # /proc, /proc/sys, /sys, /dev, tmpfs
│   ├── sysctl.md                     # runtime vs persistent, /etc/sysctl.d
│   ├── kernel-modules.md             # lsmod, modprobe, modinfo, blacklist, modules-load.d
│   ├── devices-and-udev.md           # udevadm, rules.d, major/minor numbers, hardware sensors
│   └── dmesg-and-kernel-messages.md  # OOM, segfault, I/O errors, oops lines, coredumpctl
│
├── 12-storage/
│   ├── disks-and-devices.md          # device naming, lsblk, blkid, MBR vs GPT, smartctl/nvme-cli
│   ├── partitioning.md               # fdisk, gdisk, parted, partprobe, disk layout design
│   ├── filesystems.md                # ext4 vs xfs vs btrfs vs vfat, mkfs, journaling, fsck/xfs_repair, labels and UUIDs
│   ├── mounting-and-fstab.md         # options, fstab, nofail/_netdev, mount -a, findmnt, mount units, target is busy, removable media
│   ├── swap.md                       # partition vs file, mkswap/swapon, swappiness
│   ├── lvm.md                        # PV/VG/LV/PE, create/extend/reduce, extend root, snapshots, thin pools
│   ├── resizing-and-cloud-disks.md   # growpart plus resize2fs/xfs_growfs, cloud volume resize
│   ├── disk-usage.md                 # df -h/-i, du, ncdu, deleted-but-open files, largest files, read-only remount
│   ├── quotas.md                     # xfs_quota, quota/edquota/repquota
│   ├── backup-and-restore.md         # backup types, rsync --link-dest, LVM snapshot backups, dd/ddrescue, restore testing
│   └── raid-and-encryption.md        # mdadm, /proc/mdstat, LUKS2; Stratis/VDO noted as dropped from RHCSA 9/10
│
├── 13-networking/                    # Linux commands and configuration; theory → ../../networking/
│   ├── interfaces-and-addresses.md   # ip addr/link/neigh, predictable names, ethtool, ifconfig to ip mapping
│   ├── network-configuration.md      # nmcli/nmtui vs netplan, static IPv4/IPv6, hostname
│   ├── routing.md                    # ip route, default gateway, ip_forward, static and policy routes
│   ├── dns-resolution.md             # hosts, nsswitch, resolv.conf, systemd-resolved, dig/host/getent, resolvectl
│   ├── ports-and-sockets.md          # ss -tulpn, lsof -i, 127.0.0.1 vs 0.0.0.0, well-known ports, /proc/net/tcp
│   ├── sockets-and-tcp-states.md (I) # bind/listen/accept, SYN and accept queues, TIME_WAIT/CLOSE_WAIT, conntrack
│   ├── connectivity-testing.md       # ping/tracepath/mtr, curl -v, nc, /dev/tcp, arping, iperf3, MTU probe
│   ├── packet-capture.md             # tcpdump filters, pcap for Wireshark
│   ├── bridges-bonds-vlans.md        # bridges and veth, bonding modes, teaming deprecated, VLANs
│   ├── time-and-timezones.md         # timedatectl, chrony, TZ and zoneinfo, hwclock, clock skew and TLS
│   ├── reverse-proxy-and-load-balancing.md # nginx proxy_pass and upstream, HAProxy basics, health checks → ../../../servers/nginx/
│   ├── vpn-wireguard.md              # short → ../../../operations/wireguard/
│   └── troubleshooting-ladder.md     # link, IP, route, ARP, DNS, port, firewall, application
│
├── 14-ssh-and-remote-access/         # operational use; protocol deep dive → ../../ssh/
│   ├── ssh-client.md                 # keys, ~/.ssh/config, agent, ProxyJump, known_hosts, X11 forwarding
│   ├── ssh-tunnels.md                # -L, -R, -D with use cases
│   ├── sshd-server.md                # sshd_config, sshd -t/-T, key-only login, AllowUsers, SFTP chroot, fail2ban
│   ├── file-transfer.md              # scp, rsync, sftp, tar over ssh
│   └── ssh-troubleshooting.md        # Permission denied (publickey) ladder, slow login, -vvv decoding
│
├── 15-security/
│   ├── firewalld-and-ufw.md          # zones, services, ports, rich rules, --permanent
│   ├── nftables-and-iptables.md      # netfilter hooks, stateful filtering, conntrack, NAT, forward-port, ipset
│   ├── selinux.md                    # modes, contexts, chcon vs restorecon, semanage, booleans, audit tools, LSM hooks (I)
│   ├── apparmor.md                   # aa-status, complain vs enforce
│   ├── capabilities.md               # getcap/setcap, ping without SUID, cap_net_bind_service, AmbientCapabilities
│   ├── auditd.md                     # auditctl rules, ausearch, aureport
│   ├── gpg.md                        # keygen, sign/verify, encrypt, apt keyrings vs rpm --import
│   ├── openssl-and-trust-store.md    # inspect/verify certificates, CSR, s_client, CA trust store, crypto policies
│   ├── compliance-and-integrity.md   # OpenSCAP, AIDE, rkhunter, package verification, CVE/CVSS and backporting, shred
│   └── hardening-checklist.md        # CIS-style hardening, banners, unused filesystems, privilege-escalation audit
│
├── 16-boot-and-recovery/
│   ├── boot-process.md               # UEFI/BIOS, GRUB2, kernel, initramfs, switch_root, systemd, target; Secure Boot; PXE
│   ├── grub2.md                      # grub2-mkconfig vs update-grub, kernel parameters, default kernel, grub2-setpassword
│   ├── recovery.md                   # root password reset, rescue and emergency targets, bad fstab, kdump
│   ├── kernel-panic.md           (I) # oops vs panic, cannot mount root fs, SysRq, netconsole
│   └── kernel-updates.md             # installed kernels, dracut and initramfs, livepatch
│
├── 17-performance-and-troubleshooting/
│   ├── methodology.md                # USE method, 60-second checklist, sar history, first questions
│   ├── cpu-and-load.md               # load average, CPU time categories, vmstat, mpstat, pidstat, cgroup throttling
│   ├── memory.md                     # free decoded, swap, OOM killer, oom_score_adj, exit 137, leak hunting
│   ├── virtual-memory.md         (I) # address space, page tables, page faults, overcommit, RSS/VSZ/PSS, page cache, writeback
│   ├── disk-io.md                    # iostat -x, iotop, await and utilisation
│   ├── limits-and-file-descriptors.md # ulimit vs limits.conf vs LimitNOFILE, too many open files, nproc/pid_max
│   ├── profiling-and-tracing.md  (I) # perf, flame graphs, bcc/bpftrace, choosing strace vs perf vs eBPF
│   ├── monitoring-and-capacity.md    # SLI/SLO/SLA, agent vs agentless, thresholds → ../../../observability-security/
│   └── tuning.md                     # tuned profiles, sysctl links
│
├── 18-network-storage/
│   ├── nfs.md                        # exports, client mounts, fstab, firewall and SELinux, hard mounts and D state
│   ├── autofs.md                     # direct vs indirect maps, NFS home directories
│   ├── samba-cifs.md                 # CIFS client with credentials file, short server section
│   └── iscsi-and-nbd.md              # targetcli, iscsiadm
│
├── 19-containers/                    # bridge to ../../../containers-orchestration/docker/
│   ├── namespaces.md             (I) # lsns, unshare, nsenter, clone/setns, container by hand with veth and a bridge
│   ├── cgroups.md                (I) # v1 vs v2, slices, systemd-cgls, memory.max, cpu.max, pids.max, cgroup OOM
│   ├── overlayfs-and-chroot.md       # union filesystems and image layers
│   ├── containers-vs-vms.md          # a container is a process; PID 1 in containers
│   └── podman-and-quadlet.md         # rootless, subuid/subgid, skopeo, Containerfile, :Z volumes, Quadlet
│
├── 20-virtualization-and-provisioning/
│   ├── kvm-and-libvirt.md            # virsh, virt-install, network types, snapshots
│   ├── vm-images-and-cloning.md      # virtio, machine-id and host key reset, templates
│   └── cloud-init-and-kickstart.md   # user-data, Kickstart, image mode note
│
├── reference/
│   ├── cheatsheet.md                 # one printable page of commands by task
│   ├── must-know-facts.md            # every topic's facts table, included by snippet
│   ├── command-index.md              # A to Z: command, one-liner, topic link
│   ├── important-files.md            # key files: purpose, format, managing command
│   ├── rhel-vs-ubuntu.md             # full comparison matrix
│   ├── error-messages.md             # exact error text, cause, fix
│   ├── no-tools-fallbacks.md         # /proc and shell builtin replacements for missing tools
│   ├── glossary.md                   # one-line definitions
│   └── coverage-map.md               # certification objective to file
│
├── interview/
│   ├── README.md                     # how rounds work, answer method, what each round scores
│   ├── round-1-screening.md          # L1, every topic's l1 section by snippet
│   ├── round-2-hands-on.md           # L2 timed tasks plus output-reading drills
│   ├── round-3-troubleshooting.md    # L3 method plus scenario index
│   ├── round-4-internals.md          # L4 question bank
│   ├── scenarios/                    # 19 scenarios (list in manifest.yml)
│   └── mock-interviews.md            # three 45-minute mocks mixing L1 to L4
│
├── labs/
│   ├── README.md                     # lab environments
│   ├── users-and-permissions-lab.md
│   ├── processes-and-services-lab.md
│   ├── storage-and-lvm-lab.md
│   ├── networking-lab.md
│   ├── security-lab.md
│   ├── containers-by-hand-lab.md
│   ├── rhcsa-style-tasks.md
│   └── break-fix-lab.md
│
└── _sources/                         # git-ignored, excluded from MkDocs: rhcsa/, NOTES/, INVENTORY.md
```

Size (from `manifest.yml`): 21 modules, 140 topic files (51 High, 56 Med, 33 Low; 13 internals), 19 scenarios, 9 lab pages, 9 reference pages.

---

## Phases

**Phase 0: log the plan.** `plan/` (this folder), LLM pointers in `CLAUDE.md`, `GEMINI.md` and a new `AGENTS.md`, `plan/` added to `exclude_docs`, and `scripts/gen-checklist.py`. Committed locally on its own branch; the owner pushes and merges it.

**Git rule for every phase:** agents commit locally only. They never push, open pull requests, or add AI attribution lines to commits or pull requests. The owner decides when work leaves the machine.

**Phase 1: housekeeping** (branch `feature/linux-notes`).

- Move `rhcsa/` and `NOTES/` into `technical-grounding/linux/_sources/`. Move the third-party resume out of the repository. Delete the duplicate zip.
- Add `_sources/` to `.gitignore` and to `exclude_docs` (MkDocs does not read `.gitignore`).
- Remove `Linux.md`, `cheatSheet.md` and `troubleshooting.md`; move the LWN link into `00-foundations/distributions.md`.
- Fix the links in `technical-grounding/basics/index.md` that point to removed files.
- Sync the local virtual environment with `requirements.txt` (local pymdown-extensions 10.16 vs 11.0.2 in CI).
- Write `_sources/INVENTORY.md`: every course topic and question source mapped to a file, a fact, a deferral, or a drop.

**Phase 2: pilot, then stop for owner sign-off.**

- `templates/topic.md`, `templates/module-readme.md`, `templates/scenario.md`.
- `scripts/lint-prose.py`, `scripts/audit-tool.py`.
- `technical-grounding/linux/README.md`, `roadmap.md`, `.pages`.
- All of `04-users-and-access/`.
- `reference/must-know-facts.md` and `interview/round-1-screening.md` with module 04 snippets.
- `interview/scenarios/cannot-login-or-sudo.md` and the module 04 part of `labs/users-and-permissions-lab.md`.
- No forward links to files that do not exist yet.
- Sign-off questions: can the module be revised in 15 minutes; are outputs real; do tabs help; does it meet the writing standard.
- After sign-off: add the Notes Conventions section to `CLAUDE.md`.

**Phase 3: modules in batches.** One commit per batch; each batch waits for owner approval.

| Batch | Modules |
|---|---|
| A | 00, 01 (absorbs `STDOUT_STDERR_Guide.md`), 02 (absorbs `tar-command.md`) |
| B | 03, 05, 06 |
| C | 07, 08 |
| D | 09, 10, 11 |
| E | 12 |
| F | 13 |
| G | 14, 15 |
| H | 16, 17 |
| I | 18, 19, 20 |

Each batch updates `roadmap.md`, the snippet aggregators, `reference/coverage-map.md`, its scenarios and lab sections; passes `lint-prose.py` and `audit-tool.py --scope <modules>`; ticks its boxes in `checklist.md`; and lists the places where the owner adds first-hand lines. Absorbed legacy files are deleted in the same commit as their replacement.

**Phase 4:** complete `interview/` (rounds 2 to 4 with output-reading drills, remaining scenarios, three mock interviews).

**Phase 5:** complete `reference/` and `labs/` (`rhcsa-style-tasks.md`, `break-fix-lab.md`); resolve every `INVENTORY.md` item and every `coverage-map.md` row.

**Phase 6: completion audit.** Nothing is complete until this passes (see [`../standards/definition-of-done.md`](../standards/definition-of-done.md)).

1. `python scripts/audit-tool.py --manifest plan/linux/manifest.yml --full` exits 0.
2. Build, lint, format and link checks pass.
3. Independent review by a fresh agent that receives only this plan, the standards and the repository.
4. Findings fixed; audit re-run until clean.
5. Results written to `audit-report.md`; `plan/README.md` marks Linux complete; work is committed locally and handed to the owner to push and open the pull request.
6. Owner sign-off.

---

## Capture Environments

- **Primary:** iximiuz Labs playgrounds with systemd: `rockylinux` (Rocky Linux 10.2) and `ubuntu-24-04` (Ubuntu 24.04.4 LTS), both on the iximiuz microVM kernel 6.1.167. `flexbox` multi-VM for NFS, iSCSI, bridges, NAT and host-to-host networking. Loop devices (`losetup`) for partitions, LVM, RAID and quotas. The Rocky playground has no SELinux tooling, so SELinux output is captured on a local VM.
- **Fedora fallback for the RHEL side:** when a single item is missing or broken on the Rocky playground (a tool, a package, a behavior the image removes), capture that item on the iximiuz Fedora playground instead. Everything else on the page stays on Rocky.

    - Keep the tab label `=== "RHEL / Rocky"` unchanged (tabs are linked site-wide).
    - Inside the tab, before the output, add a note naming the source and its version, for example `!!! note "Captured on Fedora <version>"` followed by one sentence on why.
    - Name Fedora in the page's capture footer, with its version, for example: `Captured on Rocky Linux 10.2, Fedora <version> (where noted) and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), YYYY-MM.`
    - State the version for anything that differs from Rocky 10.2 (package version, default, message text) next to the output that shows it.
    - SELinux is the exception: it is still captured on a local VM, not on Fedora.

- **Rocky playground image fixes:** from batch C on, the Rocky playground runs full `coreutils` (`dnf swap coreutils-single coreutils`), as a standard RHEL server install does, so process and tracing output shows real binaries instead of wrapper scripts. Pages written earlier keep their D25 notes.
- **Known kernel limits of the playgrounds:** the iximiuz kernel has no Yama module (`kernel.yama.ptrace_scope` is absent) and does not enable the `cpu` cgroup controller for units, so `CPUQuota=` and `CPUWeight=` are not enforced there. Pages state these facts without claiming a capture; module 19 captures cgroup CPU limits on a VM where the controller is available.
- **Packages missing from the playground images:** from batch D on, the Rocky playground also has `rsyslog`, `at`, `lm_sensors` and `smartmontools`, and the Ubuntu playground has `rsyslog`, `logrotate`, `cron`, `anacron`, `at`, `sshpass` and `jq`. Standard server installs include the logging and scheduling packages; pages that list `/var/log` say the files appeared after the install.
- **Playground kernel and modules:** the kernel and `/lib/modules` come from iximiuz Labs, not from the distribution. Some drivers that are modules on RHEL and Ubuntu are built in (`br_netfilter`, `loop`, `dummy`), so module pages demonstrate with loadable modules such as `sctp` and `nbd` and state the distribution behavior for the rest.
- **Storage captures:** the playground root is a whole-disk ext4 filesystem with an empty `/etc/fstab`, so module 12 and its lab use sparse files attached as loop devices (`losetup -fP`), and cloud-disk growth is shown by enlarging the backing file and running `losetup -c`. From batch E on, both playgrounds have `lvm2`, `xfsprogs`, `parted`, `gdisk`, `mdadm`, `cryptsetup`, `quota`, `rsync`, `dosfstools`, `ncdu`, `btrfs-progs` and the `growpart` package; Rocky also has `nvme-cli`.

- **Full local VM** (VirtualBox RHEL from the course, or UTM): `16-boot-and-recovery/` (GRUB, rd.break) and `20-virtualization-and-provisioning/` (nested KVM).
- **Fallback:** local Docker for modules 00 to 05.

---

## Files Touched Outside the Tool Folder

| File | Change | Phase |
|---|---|---|
| `plan/**` | New | 0 |
| `CLAUDE.md`, `GEMINI.md`, `AGENTS.md` | Pointer to `plan/` (AGENTS.md new) | 0 |
| `mkdocs.yml` | `plan/` and `_sources/` in `exclude_docs` | 0, 1 |
| `scripts/gen-checklist.py` | New | 0 |
| `.gitignore` | `_sources/` | 1 |
| `technical-grounding/basics/index.md` | Repoint links | 1 |
| `templates/*.md` | New | 2 |
| `scripts/lint-prose.py`, `scripts/audit-tool.py` | New | 2 |
| `CLAUDE.md` | Notes Conventions section | 2 |
