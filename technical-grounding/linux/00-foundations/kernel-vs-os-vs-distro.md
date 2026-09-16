# Kernel vs OS vs Distro

The kernel manages hardware and processes; the userland (C library, shell, core tools, init system) turns it into a usable operating system; a distribution packages both with an installer, package manager, defaults and a support policy. The layer that owns a component decides where its version, bug reports and updates come from.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Kernel | Process scheduling, memory, filesystems, networking, drivers | `uname -r` |
| Userland | glibc, bash, coreutils, systemd, package manager | `ldd --version` |
| Shell | A user program that starts other programs; not part of the kernel | `echo $0` |
| Distribution | Kernel + userland + package manager + defaults + support lifecycle | `cat /etc/os-release` |
| GNU/Linux | Name that credits the GNU userland; Alpine and Android use Linux without GNU | `ls --version` |
| Kernel and distro versions | Independent numbers | `uname -r; grep VERSION_ID /etc/os-release` |
| Containers | Bring their own userland and share the host kernel | `uname -r` inside a container |
| Kernel package | `kernel` / `kernel-core` (RHEL), `linux-image-*` (Ubuntu) | `rpm -q kernel` |
<!-- --8<-- [end:facts] -->

---

## Components and Their Owners

| Component | Layer | Package on Rocky 10 | Package on Ubuntu 24.04 |
|---|---|---|---|
| Kernel | Kernel | `kernel-core` | `linux-image-*` |
| C library | Userland | `glibc` | `libc6` |
| Shell | Userland | `bash` | `bash` (login), `dash` (`/bin/sh`) |
| Core tools (`ls`, `cp`) | Userland | `coreutils` or `coreutils-single` | `coreutils` |
| Init system | Userland | `systemd` | `systemd` |
| Package manager | Distribution | `dnf`, `rpm` | `apt`, `dpkg` |

The package database answers "which component owns this file" on each family:

=== "RHEL / Rocky"

    ```bash
    rpm -qf /usr/bin/bash /usr/bin/ls /usr/lib64/libc.so.6 /usr/bin/dnf /usr/lib/systemd/systemd
    ```

    Output:

    ```text
    bash-5.2.26-6.el10.x86_64
    coreutils-single-9.5-8.el10_2.x86_64
    glibc-2.39-128.el10_2.x86_64
    dnf-4.20.0-22.el10_2.rocky.0.1.noarch
    systemd-257-23.el10_2.2.rocky.0.1.x86_64
    ```

=== "Ubuntu / Debian"

    ```bash
    dpkg -S /usr/bin/bash /usr/bin/ls /usr/lib/x86_64-linux-gnu/libc.so.6 /usr/bin/apt /usr/lib/systemd/systemd
    ```

    Output:

    ```text
    bash: /usr/bin/bash
    coreutils: /usr/bin/ls
    libc6:amd64: /usr/lib/x86_64-linux-gnu/libc.so.6
    apt: /usr/bin/apt
    systemd: /usr/lib/systemd/systemd
    ```

---

## Same Kernel, Different Distributions

The two playgrounds used for this site run different distributions on one kernel build. `uname` and `/proc/version` describe the kernel; `/etc/os-release` describes the distribution. On the Rocky Linux machine:

```bash
uname -r
cat /proc/version
grep -E '^(NAME|VERSION_ID)=' /etc/os-release
```

Output:

```text
6.1.167
Linux version 6.1.167 (root@buildkitsandbox) (gcc (Ubuntu 11.5.0-1ubuntu1~24.04.1) 11.5.0, GNU ld (GNU Binutils for Ubuntu) 2.42) #1 SMP PREEMPT_DYNAMIC Thu Apr 16 10:07:08 UTC 2026
NAME="Rocky Linux"
VERSION_ID="10.2"
```

The kernel on the Rocky machine was compiled with Ubuntu's GCC because the playground provider builds one kernel for every image. No kernel package is installed:

=== "RHEL / Rocky"

    ```bash
    rpm -q kernel kernel-core
    ```

    Output:

    ```text
    package kernel is not installed
    package kernel-core is not installed
    ```

=== "Ubuntu / Debian"

    ```bash
    dpkg -l 'linux-image*'
    ```

    Output:

    ```text
    dpkg-query: no packages found matching linux-image*
    ```

!!! info "Where this happens in practice"
    Containers, WSL 2, microVMs (Firecracker) and some managed platforms run a userland whose distribution never shipped the kernel underneath. A distribution version therefore says nothing reliable about kernel features such as cgroup v2 or eBPF; check `uname -r`.

---

## The Userland Is Versioned Separately

```bash
ls --version | head -1
bash --version | head -1
ldd --version | head -1
```

=== "RHEL / Rocky"

    Output:

    ```text
    ls (GNU coreutils) 9.5
    GNU bash, version 5.2.26(1)-release (x86_64-redhat-linux-gnu)
    ldd (GNU libc) 2.39
    ```

=== "Ubuntu / Debian"

    Output:

    ```text
    ls (GNU coreutils) 9.4
    GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)
    ldd (Ubuntu GLIBC 2.39-0ubuntu8.9) 2.39
    ```

"GNU coreutils" and "GNU libc" are the GNU part of GNU/Linux. Alpine replaces both with BusyBox and musl, which is why some GNU-only flags fail inside Alpine containers.

!!! warning "A distribution backports fixes without changing the upstream version"
    RHEL and Ubuntu apply security patches to old upstream versions (`glibc-2.39-128.el10_2`). Scanners that compare only the upstream number (`2.39`) report vulnerabilities that are already fixed; the package release and the vendor advisory decide.

---

## What a Distribution Adds

| Distribution adds | Rocky / RHEL | Ubuntu |
|---|---|---|
| Package format and manager | RPM, `dnf` | DEB, `apt` |
| Default security module | SELinux | AppArmor |
| Network configuration | NetworkManager | netplan with systemd-networkd or NetworkManager |
| Firewall front end | `firewalld` | `ufw` |
| Admin group | `wheel` | `sudo` |
| Release and support policy | 10 years per major release | 5 years standard for an LTS release, 10 with Ubuntu Pro |

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between the kernel, the shell and a distribution?"
    **Say first:** the kernel manages hardware and processes, the shell is a user program that starts other programs, and a distribution bundles the kernel, userland, package manager and support into an installable system.

    **Proof:** `uname -r`, `echo $0`, `cat /etc/os-release`.

    **Follow-up:** Which of the three does a container image contain?

??? question "L1: Why do some people say GNU/Linux?"
    **Say first:** most of the userland on a typical distribution (C library, core tools, shell, compiler) comes from the GNU project; Linux is the kernel.

    **Proof:** `ls --version` prints "GNU coreutils"; `ldd --version` prints "GNU libc".

    **Follow-up:** Name a Linux system that is not GNU/Linux. (Alpine with musl and BusyBox, Android.)
<!-- --8<-- [end:l1] -->

??? question "L2: Find which package owns /usr/bin/ls on RHEL and on Ubuntu."
    **Say first:** ask the package database.

    **Proof:** `rpm -qf /usr/bin/ls` and `dpkg -S /usr/bin/ls`.

    **Follow-up:** How do you find which package would provide a file that is not installed? (`dnf provides`, `apt-file search`.)

??? question "L2: A server reports Ubuntu 24.04. Which kernel is it running?"
    **Say first:** the distribution version does not say; read the kernel directly.

    **Proof:** `uname -r` and `cat /proc/version`.

    **Follow-up:** Why can the running kernel differ from the newest installed kernel package?

??? question "L3: A binary built on Ubuntu fails inside an Alpine container."
    **Say first:** check which C library and loader the binary expects.

    **Proof:** `file ./app` shows `interpreter /lib64/ld-linux-x86-64.so.2`, which Alpine does not have; the shell reports `not found` even though the file exists.

    **Follow-up:** What are the fixes? (Build against musl, link statically, or use a glibc-based image.)

??? question "L3: A vulnerability scanner flags glibc 2.39 on a patched RHEL host."
    **Say first:** check whether the vendor backported the fix before upgrading anything.

    **Proof:** `rpm -q --changelog glibc | grep CVE-<id>`; the RHEL errata page lists the fixed package release.

    **Follow-up:** How do you report this so the finding is closed rather than ignored?

??? question "L4: A container needs a kernel feature the host lacks. What happens?"
    **Say first:** the container fails, because it shares the host kernel; the image cannot bring its own.

    **Proof:** `uname -r` inside and outside match; a system call the host kernel does not implement returns `ENOSYS`.

    **Don't say:** "Use a newer base image to get the newer kernel."

---

## Related

- [What Is Linux](what-is-linux.md): history and licensing
- [Architecture](architecture.md): how userland reaches the kernel
- [Distributions](distributions.md): families, release models, support windows

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
