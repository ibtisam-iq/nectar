# What Is Linux

Linux is a Unix-like operating system kernel released by Linus Torvalds in 1991 under the GNU GPL version 2. Combined with GNU tools and other userland software, it runs most servers, clouds, containers, Android phones and supercomputers.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Linux is | A kernel; a full system adds a userland and becomes a distribution | `uname -s` |
| Author and year | Linus Torvalds, first release 1991 | `cat /proc/version` |
| Kernel license | GPL version 2 only, plus the Linux syscall exception, which keeps user programs outside the GPL | `dnf repoquery --qf '%{license}' kernel-core` |
| Userland license (bash, coreutils) | GPL version 3 or later | `rpm -q --qf '%{LICENSE}\n' bash` |
| Ancestor design | Unix (Bell Labs, 1969); Linux reimplements it, sharing no code | `man 7 standards` |
| Standards | POSIX and the Single UNIX Specification (Linux is not certified) | `getconf _POSIX_VERSION` |
| Release cadence | A new mainline kernel roughly every 9 to 10 weeks | `uname -r` |
<!-- --8<-- [end:facts] -->

---

## Timeline

| Year | Event |
|---|---|
| 1969 | Ken Thompson and Dennis Ritchie start Unix at Bell Labs |
| 1983 | Richard Stallman announces the GNU project: a free Unix-like system |
| 1987 | Andrew Tanenbaum releases MINIX for teaching |
| 1991 | Linus Torvalds announces Linux 0.01 on comp.os.minix |
| 1992 | Linux relicensed under GPL version 2; GNU tools plus Linux form a complete free system |
| 1993 | Slackware and Debian released |
| 1995 | Red Hat Linux released; Red Hat Enterprise Linux follows in 2002 |
| 2004 | Ubuntu released |
| 2008 | Android ships on the Linux kernel |
| 2013 | Docker popularizes Linux containers |

---

## Licensing in Practice

GPL is copyleft: anyone who distributes a modified version must publish the source under the same license. Permissive licenses (MIT, BSD, Apache 2.0) allow closed derivatives. Package metadata records each component's license:

```bash
rpm -q --qf '%{NAME}: %{LICENSE}\n' bash coreutils-single systemd rpm
```

Output:

```text
bash: GPL-3.0-or-later
coreutils-single: GPL-3.0-or-later AND GFDL-1.3-no-invariants-or-later AND LGPL-2.1-or-later AND LGPL-3.0-or-later
systemd: LGPL-2.1-or-later AND MIT AND GPL-2.0-or-later
rpm: GPL-2.0-or-later
```

The kernel package is not installed on the microVM playground, but the repository metadata carries its license. RHEL 10 ships kernel 6.12, and the expression starts with the Linux syscall exception, which allows proprietary programs to run on a GPL kernel:

```bash
dnf repoquery -q --latest-limit 1 --qf '%{name}-%{version}: %{license}\n' kernel-core | cut -c1-72
```

Output:

```text
kernel-core-6.12.0: ((GPL-2.0-only WITH Linux-syscall-note) OR BSD-2-Cla
```

!!! note "Debian packages keep their license in a copyright file"
    On Debian and Ubuntu, the license text lives in `/usr/share/doc/<package>/copyright`.

!!! note "Copyleft applies to distribution, not use"
    A company can run modified GPL software internally without publishing anything. The obligation starts when binaries are shipped to others; the AGPL extends it to software offered over a network.

---

## Where Linux Runs

| Area | Example |
|---|---|
| Servers and cloud | Most public cloud instances; AWS, Azure and GCP managed services |
| Containers | Every Docker and Kubernetes Linux container shares the host's Linux kernel |
| Mobile and embedded | Android, routers, TVs, cars |
| Supercomputers | All of the TOP500 list since November 2017 |
| Desktops | Ubuntu, Fedora, Linux Mint; ChromeOS uses the Linux kernel |

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Is Linux an operating system?"
    **Say first:** strictly, Linux is the kernel; an operating system also needs a C library, shell and tools, which distributions supply.

    **Proof:** `uname -s` names the kernel; `/etc/os-release` names the distribution.

    **Follow-up:** What does a distribution add on top of the kernel?

??? question "L1: What does the GPL require from a company that modifies Linux?"
    **Say first:** if the company distributes the modified kernel, it must provide the source under GPL version 2; internal use carries no obligation.

    **Proof:** the kernel's `COPYING` file; `rpm -q --qf '%{LICENSE}' rpm`.

    **Follow-up:** How is that different from software under the MIT license?

??? question "L1: How is Linux related to Unix?"
    **Say first:** Linux is a Unix-like clone written from scratch; it follows POSIX but contains no Unix source code.

    **Proof:** `getconf _POSIX_VERSION` reports the POSIX level the C library supports.

    **Follow-up:** Name a certified Unix still in use. (macOS, AIX.)
<!-- --8<-- [end:l1] -->

??? question "L2: Show the license of three installed packages."
    **Say first:** query the package database.

    **Proof:**

    ```bash
    rpm -q --qf '%{NAME}: %{LICENSE}\n' bash systemd rpm
    ```

    **Follow-up:** Where is the same information on Ubuntu?

??? question "L2: Show the kernel build a machine is running, including who built it."
    **Say first:** `/proc/version` includes the compiler and build host.

    **Proof:** `cat /proc/version`

    **Follow-up:** Why would a Rocky Linux machine show an Ubuntu compiler there?

??? question "L2: Prove a container uses the host's kernel."
    **Say first:** compare `uname -r` inside and outside the container.

    **Proof:** `uname -r; docker run --rm alpine uname -r` print the same release.

    **Follow-up:** What does that mean for running a container built for a newer kernel?

---

## Related

- [Kernel vs OS vs Distro](kernel-vs-os-vs-distro.md): what the kernel does and what it leaves to userland
- [Distributions](distributions.md): families and release models

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
