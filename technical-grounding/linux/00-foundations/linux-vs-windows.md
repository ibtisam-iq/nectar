# Linux vs Windows

Linux dominates servers and containers because it is free to run at scale, scriptable end to end, and built around a strict separation between users and root. "More secure" is only a useful interview answer when it names the mechanisms behind it.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Privilege model | Root (UID 0) versus unprivileged users; daily work runs unprivileged | `id` |
| Password hashes | `/etc/shadow`, readable by root only | `ls -l /etc/shadow` |
| Package trust | Repositories and packages are GPG-signed and checked on install | `rpm -q gpg-pubkey` |
| Mandatory access control | SELinux (RHEL) or AppArmor (Ubuntu) on top of file permissions | `cat /sys/kernel/security/lsm` |
| Memory randomization | ASLR on by default (`2` = full) | `sysctl kernel.randomize_va_space` |
| Configuration | Plain-text files under `/etc`, no central registry | `ls /etc` |
| Remote administration | SSH and a shell; no GUI required | `systemctl status sshd` |
| License cost | No per-core or per-instance fee for the OS itself | Vendor pricing |
<!-- --8<-- [end:facts] -->

---

## Security Mechanisms

| Mechanism | Linux | Windows equivalent |
|---|---|---|
| Separate admin identity | `sudo` for one command; root login usually disabled over SSH | UAC elevation prompt |
| Executable permission | A file runs only with the `x` bit | Any `.exe` can run by default |
| Signed software sources | GPG-signed repositories, one update command for the whole system | Microsoft Update plus per-application updaters |
| Mandatory access control | SELinux, AppArmor | Mandatory Integrity Control, AppLocker |
| Source visibility | Kernel and userland source published | Closed source |

The mechanisms are visible on any installed system:

=== "RHEL / Rocky"

    ```bash
    ls -l /etc/shadow /usr/bin/passwd
    sysctl kernel.randomize_va_space
    rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION} %{SUMMARY}\n'
    ```

    Output:

    ```text
    ---------- 1 root root   665 Aug 29 17:55 /etc/shadow
    -rwsr-xr-x 1 root root 91424 Feb 23  2026 /usr/bin/passwd
    kernel.randomize_va_space = 2
    gpg-pubkey-6fedfc85 Release Engineering (Rocky Linux 10) <releng@rockylinux.org> public key
    gpg-pubkey-e37ed158 Fedora (epel10) <epel@fedoraproject.org> public key
    ```

=== "Ubuntu / Debian"

    ```bash
    ls -l /etc/shadow /usr/bin/passwd
    sysctl kernel.randomize_va_space
    grep -h Signed-By /etc/apt/sources.list.d/*.sources
    ```

    Output:

    ```text
    -rw-r----- 1 root shadow   814 Aug 29 18:08 /etc/shadow
    -rwsr-xr-x 1 root root   64152 May 30  2024 /usr/bin/passwd
    kernel.randomize_va_space = 2
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
    ```

!!! warning "Linux servers are compromised through configuration, not the kernel"
    Most real incidents come from weak SSH passwords, exposed services, unpatched applications and `chmod 777`. The model is strong only when those defaults stay in place.

---

## Why Servers Run Linux

| Reason | Detail |
|---|---|
| Cost at scale | No OS license per instance; matters for thousands of cloud machines |
| Automation | Every setting is a text file or a command, so Ansible, Terraform and cloud-init can manage it |
| Containers | Docker and Kubernetes are built on Linux namespaces and cgroups |
| Footprint | A minimal server image runs without a GUI in a few hundred megabytes of RAM |
| Uptime | Most updates need a service restart, not a reboot; kernel live patching covers some kernel fixes |

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Why is Linux considered more secure than Windows?"
    **Say first:** name mechanisms: users work unprivileged and gain root per command through `sudo`, software comes from signed repositories, SELinux or AppArmor confine services, and the source is open to review.

    **Proof:** `ls -l /etc/shadow`, `rpm -q gpg-pubkey`, `cat /sys/kernel/security/lsm`.

    **Follow-up:** What are the most common ways Linux servers still get compromised?

??? question "L1: Why do most cloud servers and containers run Linux?"
    **Say first:** no license cost per instance, full automation through text configuration and SSH, and containers are a Linux kernel feature.

    **Proof:** `ls /proc/self/ns` shows the namespaces containers use.

    **Follow-up:** How do Windows containers differ?

??? question "L1: What replaces the Windows registry on Linux?"
    **Say first:** plain-text configuration files, mostly under `/etc`, plus per-user dotfiles in the home directory.

    **Proof:** `ls /etc/ssh/sshd_config /etc/fstab`

    **Follow-up:** What does that make easier for configuration management and version control?
<!-- --8<-- [end:l1] -->

??? question "L2: Show that a password hash file cannot be read by normal users."
    **Say first:** check its mode and try to read it.

    **Proof:** `ls -l /etc/shadow` then `cat /etc/shadow` as a normal user, which fails with `Permission denied`.

    **Follow-up:** How does `passwd` update it then? (The SUID bit on `/usr/bin/passwd`.)

??? question "L2: Show which security modules the running kernel has loaded."
    **Say first:** read the LSM list from securityfs.

    **Proof:** `cat /sys/kernel/security/lsm`

    **Follow-up:** How do you check whether SELinux is enforcing?

??? question "L3: A Windows administrator asks why the Linux server has no antivirus. What do you check before answering?"
    **Say first:** confirm the controls that replace it: patch level, exposed ports, SSH settings, MAC mode and file integrity monitoring.

    **Proof:** `dnf check-update` or `apt list --upgradable`, `ss -tlnp`, `sshd -T | grep -E 'permitrootlogin|passwordauthentication'`.

    **Follow-up:** When is an antivirus scanner still required on Linux? (File servers for Windows clients, compliance rules.)

---

## Related

- [Users](../04-users-and-access/users.md): root and unprivileged accounts
- [Sudo and Su](../04-users-and-access/sudo-and-su.md): per-command elevation
- [Distributions](distributions.md): signed repositories per family

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
