# Hardening Checklist

Hardening reduces what an attacker can reach and use: fewer accounts and services, tighter SSH, kernel settings that block common tricks, and updates that close known holes. The checks below are CIS-style and each one has a command that proves its state.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Updates | Security updates applied; automatic on servers that allow it (`dnf-automatic`, `unattended-upgrades`) | `sudo dnf updateinfo list --security` |
| Accounts | Only `root` has UID 0; no empty password fields; service accounts use `nologin` | `awk -F: '$3 == 0' /etc/passwd` |
| sudo | Narrow command rules; `NOPASSWD: ALL` only where justified | `sudo -l -U USER` |
| setuid | Inventory setuid files and remove unneeded ones; world-writable directories carry the sticky bit | `find / -xdev -perm -4000 -type f` |
| Services | Every listening socket is known and needed | `sudo ss -tulpn` |
| SSH | Keys only, no root login, `MaxAuthTries` low, a legal banner | `sudo sshd -T` |
| Firewall, MAC | Default deny for incoming traffic; SELinux enforcing or AppArmor profiles loaded | `getenforce` |
| Kernel | `kptr_restrict`, `dmesg_restrict`, `rp_filter` on; ICMP redirects off; ASLR `2` | `sysctl -a` |
| Filesystems | Unused modules (`cramfs`, `udf`, `usb-storage` on servers) blocked with `install ... /bin/false` | `modprobe -n -v cramfs` |
| Logging, audits | `auditd` and time sync active, logs shipped off the host; Lynis or OpenSCAP scans | `systemctl is-active auditd chronyd` |
<!-- --8<-- [end:facts] -->

---

## Accounts, sudo and setuid Files

```bash
awk -F: '$3 == 0 {print $1}' /etc/passwd
sudo awk -F: '$2 == "" {print $1}' /etc/shadow | wc -l
awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ {print $1, $7}' /etc/passwd
sudo grep -rhE '^[^#].*NOPASSWD' /etc/sudoers /etc/sudoers.d/
sudo find / -xdev -perm -4000 -type f 2>/dev/null | sort
sudo find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | head -5
```

Output:

```text
root
0
root /bin/bash
laborant /bin/bash
deploy /bin/bash
auditdemo /bin/bash
deploy ALL=(root) NOPASSWD: /usr/bin/systemctl reload nginx
laborant ALL=(ALL) NOPASSWD:ALL
/usr/bin/chage
# ... (trimmed)
/usr/sbin/exim
# ... (trimmed)
```

Findings on `web`: `auditdemo` was a leftover test account (removed with `sudo userdel -r auditdemo`), `laborant ALL=(ALL) NOPASSWD:ALL` is the playground's own admin user, and `deploy` has one narrow rule. No world-writable directory lacked the sticky bit.

!!! warning "Security tools can add attack surface"
    `/usr/sbin/exim` is a setuid mail server binary that nobody installed on purpose: `fail2ban` from EPEL pulled in `fail2ban-sendmail`, which needs `/usr/sbin/sendmail`, which `exim` provides (`dnf repoquery --installed --whatrequires /usr/sbin/sendmail`). Review the dependency list of every package added for security.

---

## Listening Services

```bash
sudo ss -tulpn | awk 'NR>1 {print $1, $5, $7}' | sed -E 's/,pid=[0-9]+,fd=[0-9]+//g' | sort -u
```

Output:

```text
tcp *:40059 users:(("examiner"))
tcp 0.0.0.0:22 users:(("sshd"))
tcp 0.0.0.0:50061 users:(("systemd"))
# ... (trimmed)
tcp 127.0.0.1:953 users:(("named"))
# ... (trimmed)
udp 0.0.0.0:123 users:(("chronyd"))
udp 0.0.0.0:51820 
# ... (trimmed)
```

Each line needs an owner and a reason: `examiner` and the systemd socket on 50061 belong to the playground, `rndc` (953) listens on loopback only, and `51820/udp` has no process because the kernel's WireGuard module owns it. Anything unexplained is stopped and disabled, and the firewall covers the rest.

---

## Kernel Settings and Unused Modules

The defaults here left ICMP redirects accepted, reverse-path filtering off and `dmesg` world-readable. A drop-in fixes them:

```bash
sysctl kernel.kptr_restrict kernel.dmesg_restrict kernel.randomize_va_space fs.protected_symlinks net.ipv4.conf.all.accept_redirects net.ipv4.conf.all.rp_filter
sudo tee /etc/sysctl.d/90-hardening.conf >/dev/null <<'EOF'
kernel.dmesg_restrict = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 1
EOF
sudo sysctl --system >/dev/null
sysctl kernel.dmesg_restrict net.ipv4.conf.all.accept_redirects net.ipv4.conf.all.rp_filter
printf 'install cramfs /bin/false\nblacklist cramfs\n' | sudo tee /etc/modprobe.d/cramfs.conf >/dev/null
sudo modprobe -n -v cramfs; echo "exit=$?"
```

Output:

```text
kernel.kptr_restrict = 1
kernel.dmesg_restrict = 0
kernel.randomize_va_space = 2
fs.protected_symlinks = 1
net.ipv4.conf.all.accept_redirects = 1
net.ipv4.conf.all.rp_filter = 0
kernel.dmesg_restrict = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 1
install /bin/false 
exit=0
```

`modprobe -n -v` shows that loading `cramfs` would run `/bin/false` instead. A router such as `gw` keeps `ip_forward = 1` and may need loose `rp_filter` (`2`) with asymmetric routes.

---

## SSH

Before the change, `sshd -T` reported `maxauthtries 50`, `permitrootlogin without-password`, `passwordauthentication yes`, `x11forwarding yes` and `banner none`.

```bash
echo 'Authorized use only. Activity is logged.' | sudo tee /etc/issue.net >/dev/null
sudo tee /etc/ssh/sshd_config.d/10-hardening.conf >/dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
MaxAuthTries 3
Banner /etc/issue.net
EOF
sudo sshd -t && sudo systemctl reload sshd
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|x11forwarding|maxauthtries|banner) '
```

Output:

```text
maxauthtries 3
permitrootlogin no
passwordauthentication no
x11forwarding no
banner /etc/issue.net
```

`passwordauthentication yes` was misleading here: the image's `AuthenticationMethods publickey` already refused passwords. The drop-in states the intent explicitly; [sshd Server](../14-ssh-and-remote-access/sshd-server.md) explains the order of these files.

!!! tip "Prove each step, do not assume it"
    Read a setting before and after a change: it can be overridden by a later drop-in or already enforced elsewhere, as `passwordauthentication yes` was here.

---

## Banning Repeated SSH Failures

On `client` (Ubuntu), the `fail2ban` package enables the `sshd` jail with the `nftables` ban action. A local file lowers the threshold, and four logins as a nonexistent user from `gw` trigger a ban.

```bash
printf '[sshd]\nmaxretry = 3\nfindtime = 10m\nbantime = 10m\n' | sudo tee /etc/fail2ban/jail.d/sshd.local >/dev/null
sudo systemctl start fail2ban
for i in 1 2 3 4; do ssh -o BatchMode=yes -o ConnectTimeout=5 admin@172.16.0.2 true; done    # on gw
sudo fail2ban-client status sshd    # on client
```

Output:

```text
admin@172.16.0.2: Permission denied (publickey).
# ... (trimmed: three more identical lines)
Status for the jail: sshd
# ... (trimmed)
|  |- Total failed:	4
# ... (trimmed)
   |- Currently banned:	1
# ... (trimmed)
   `- Banned IP list:	172.16.0.3
```

`sudo nft list table inet f2b-table` shows the reject rule for the banned address, the next attempt from `gw` gets `Connection refused`, and `sudo fail2ban-client set sshd unbanip 172.16.0.3` lifts the ban.

---

## Updates

=== "RHEL / Rocky"

    ```bash
    sudo dnf -q updateinfo list --security | wc -l
    sudo sed -i -e 's/^upgrade_type = default/upgrade_type = security/' -e 's/^apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
    sudo systemctl enable --now dnf-automatic.timer
    systemctl list-timers dnf-automatic.timer --no-pager | head -2
    ```

    Output:

    ```text
    35
    NEXT                        LEFT LAST PASSED UNIT     ACTIVATES
    Fri 2026-09-18 06:52:37 UTC  13h -  - dnf-automatic.timer dnf-automatic.service
    ```


=== "Ubuntu / Debian"

    ```bash
    systemctl is-enabled unattended-upgrades
    apt list --upgradable 2>/dev/null | grep -c security
    ```

    Output:

    ```text
    not-found
    40
    ```

    The playground image omits `unattended-upgrades` (a standard Ubuntu Server install includes it); `sudo apt install unattended-upgrades` and `sudo dpkg-reconfigure -plow unattended-upgrades` enable daily security updates.

---

## An Automated Audit With Lynis

```bash
sudo lynis audit system --quick --no-colors > /tmp/lynis.out 2>&1; echo "exit=$?"
grep -E 'Hardening index|Tests performed' /tmp/lynis.out
sed -n '/^  Warnings/,/^  Suggestions/p' /tmp/lynis.out | grep '!'
```

Output:

```text
  Hardening index : 65 [#############       ]
  Tests performed : 259
  ! Reboot of system is most likely needed [KRNL-5830] 
  ! Found one or more vulnerable packages. [PKGS-7392] 
  ! No AIDE database was found, needed for AIDE functionality [FINT-4316] 
```

Lynis also printed 54 suggestions (installing `needrestart`, copying `jail.conf` to `jail.local`). The index is a trend to improve between runs, not a pass mark.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are the first things you harden on a new Linux server?"
    **Say first:** updates, SSH (keys only, no root), a default-deny firewall, only needed services and accounts, and MAC left enforcing.

    **Proof:** `sudo dnf updateinfo list --security`; `sudo sshd -T`; `sudo firewall-cmd --list-all`; `sudo ss -tulpn`; `getenforce`.

    **Follow-up:** Which of these would you automate first, and how?
<!-- --8<-- [end:l1] -->

??? question "L2: Find accounts that could give root access."
    **Say first:** UID 0 accounts, broad sudo rules, and setuid binaries.

    **Proof:** `awk -F: '$3 == 0' /etc/passwd`; `sudo grep -rE 'NOPASSWD|ALL' /etc/sudoers /etc/sudoers.d`; `sudo find / -xdev -perm -4000`.

    **Follow-up:** Why is `sudo vim` or `sudo less` as good as `sudo ALL`?

??? question "L2: Make kernel network settings safer and persistent."
    **Say first:** a file in `/etc/sysctl.d/`, loaded with `sysctl --system`.

    **Proof:** `accept_redirects = 0`, `rp_filter = 1`, `dmesg_restrict = 1` in `/etc/sysctl.d/90-hardening.conf`; `sysctl` shows the new values.

    **Follow-up:** Why can strict `rp_filter` break a router?

??? question "L2: Block a filesystem module that the server never needs."
    **Say first:** an `install MODULE /bin/false` line in `/etc/modprobe.d/`.

    **Proof:** `sudo modprobe -n -v cramfs` printed `install /bin/false`.

    **Follow-up:** Why is `blacklist` alone not enough?

??? question "L3: A security scan flags a server you hardened last week. How do you handle the report?"
    **Say first:** separate real findings from context: check `notapplicable` and false positives, backported fixes, and items accepted by design, then fix or document each one.

    **Proof:** Lynis warnings and OpenSCAP results; `rpm -q --changelog` for backports; a recorded exception for a router's `ip_forward`.

    **Follow-up:** How do you keep a fleet from drifting back?

??? question "L3: An unexpected setuid binary shows up in an inventory. What do you do?"
    **Say first:** find which package owns it and why that package is installed, then remove or neutralize it.

    **Proof:** `rpm -qf /usr/sbin/exim`; `dnf repoquery --installed --whatrequires /usr/sbin/sendmail` showed `fail2ban-sendmail`; if the file belongs to no package, treat it as a possible compromise.

    **Follow-up:** How would you catch this automatically next time?

---

## Related

- [Compliance and Integrity](compliance-and-integrity.md), [sshd Server](../14-ssh-and-remote-access/sshd-server.md), [firewalld and ufw](firewalld-and-ufw.md) and [SELinux](selinux.md): the scanners and controls behind these checks

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 (fail2ban 1.0.2, Lynis 3.0.9) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
