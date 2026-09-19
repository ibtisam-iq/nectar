# auditd

The Linux audit system records selected system calls and file accesses in the kernel and writes them to `/var/log/audit/audit.log` through `auditd`. It answers "who changed this file" and "which admin ran that as root" after the fact, and it stores SELinux denials.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Pieces | Kernel audit subsystem, `auditd` daemon, rules in `/etc/audit/rules.d/*.rules` compiled by `augenrules`; package `audit` (RHEL, enabled) or `auditd` (Ubuntu) | `sudo auditctl -s` |
| Rules | Watch: `-w PATH -p rwxa -k KEY`; syscall: `-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k KEY` | `sudo auditctl -l` |
| auid | The login UID, set at login and kept through `sudo` and `su`; `unset` for services | `cat /proc/self/loginuid` |
| Search | `ausearch -k KEY -i`, `-m AVC`, `-ts recent` (10 minutes) or `today`, `--format text`; reports with `aureport -au`, `-k`, `-x` | `sudo aureport -k --summary` |
<!-- --8<-- [end:facts] -->

---

## Rules

`web` (Rocky Linux 10.2) had no rules loaded (`sudo auditctl -l` printed `No rules`). A rules file watches `/etc/passwd` and the SSH drop-in directory and records commands that a logged-in user runs as root.

```bash
sudo tee /etc/audit/rules.d/50-lab.rules >/dev/null <<'EOF'
-w /etc/passwd -p wa -k identity
-w /etc/ssh/sshd_config.d/ -p wa -k sshd-config
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=unset -k root-exec
EOF
sudo augenrules --load | tail -3
sudo auditctl -l
sudo systemctl restart auditd; echo "exit=$?"
```

Output:

```text
Old style watch rules are slower
backlog 0
backlog_wait_time 60000
backlog_wait_time_actual 0
-w /etc/passwd -p wa -k identity
-w /etc/ssh/sshd_config.d -p wa -k sshd-config
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=-1 -F key=root-exec
Failed to restart auditd.service: Operation refused, unit auditd.service may be requested by dependency only (it is configured to refuse manual start/stop).
See system logs and 'systemctl status auditd.service' for details.
exit=4
```

`augenrules --load` applied the rules without a restart; `service auditd restart` is the supported way to restart the daemon. The unit refuses manual stops so that an attacker with `systemctl` cannot silently switch auditing off.

!!! tip "Lock the rules on sensitive hosts"
    A final `-e 2` line makes the loaded rules immutable until the next reboot, so even root cannot remove a watch without leaving a reboot in the logs.

---

## Searching Events

Three events followed: root ran `useradd auditdemo` and touched a file in `/etc/ssh/sshd_config.d/`, and `deploy`, logged in over SSH, ran `sudo systemctl reload nginx` (allowed by a one-line sudoers rule).

```bash
sudo ausearch -k identity -ts today --format text
sudo ausearch -k root-exec -ts today --format text | tail -2
sudo ausearch -k sshd-config -ts today --format text
sudo aureport -k --summary
```

Output:

```text
At 16:37:02 09/17/26 system, acting as root, successfully add_rule identity using /usr/sbin/auditctl
At 16:37:20 09/17/26 system, acting as root, successfully opened-file /etc/passwd using /usr/sbin/useradd
At 16:37:20 09/17/26 system, acting as root, successfully renamed /etc/passwd+ to /etc/passwd using /usr/sbin/useradd
At 16:37:25 09/17/26 deploy, acting as root, successfully executed /usr/sbin/unix_chkpwd 
At 16:37:25 09/17/26 deploy, acting as root, successfully executed /usr/bin/systemctl 
At 16:37:02 09/17/26 system, acting as root, successfully add_rule sshd-config using /usr/sbin/auditctl
At 16:37:20 09/17/26 system, acting as root, successfully opened-file /etc/ssh/sshd_config.d/99-audit-test.conf using /usr/bin/coreutils
At 16:37:20 09/17/26 system, acting as root, successfully deleted /etc/ssh/sshd_config.d/99-audit-test.conf using /usr/bin/coreutils

Key Summary Report
===========================
total  key
===========================
4  root-exec
3  identity
3  sshd-config
```

`deploy, acting as root` is the login UID at work: `sudo` changed the user, the audit record kept who logged in. The playground's root shell has no login session, so it appears as `system`. `/usr/bin/coreutils` is the multi-call binary behind `touch` and `rm` on this image.

!!! warning "ausearch reads standard input when it is a pipe"
    In a script or remote command, `ausearch` without a terminal on standard input reads that input instead of the log. `echo | sudo ausearch -k identity` printed `<no matches>` with exit 1, and `--input-logs` made the same pipeline print 15 record lines.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the audit login UID, and why does it matter?"
    **Say first:** it is the UID a user logged in with; it survives `sudo` and `su`, so audit records show the real person behind root actions.

    **Proof:** `ausearch -k root-exec --format text` printed `deploy, acting as root`.

    **Follow-up:** Why do services show `unset`?
<!-- --8<-- [end:l1] -->

??? question "L2: Record every change to /etc/passwd and find who made it."
    **Say first:** add a watch rule with a key and search by the key.

    **Proof:** `-w /etc/passwd -p wa -k identity` in `/etc/audit/rules.d/`; `sudo augenrules --load`; `sudo ausearch -k identity -i`.

    **Follow-up:** Why is `-p wa` better than `-p rwa` here?

??? question "L2: Load new audit rules without rebooting."
    **Say first:** `augenrules --load` compiles `rules.d` and loads the result.

    **Proof:** `sudo augenrules --load`; `sudo auditctl -l`.

    **Follow-up:** What does `-e 2` at the end of the rules do?

??? question "L2: Show a summary of logins recorded by audit."
    **Say first:** `aureport -au` lists authentication events with user, host and result.

    **Proof:** `sudo aureport -au -ts today | tail -3` showed `deploy 172.16.0.2 ? /usr/libexec/openssh/sshd-session yes`.

    **Follow-up:** Where else would failed SSH logins appear?

??? question "L2: A script that runs ausearch over SSH always prints no matches. Why?"
    **Say first:** `ausearch` reads standard input when it is not a terminal; the script must pass `--input-logs`.

    **Proof:** `echo | sudo ausearch -k identity` returned `<no matches>`; with `--input-logs` it found the records.

    **Follow-up:** How does `ausearch -if FILE` differ?

??? question "L3: A config file changed overnight and nobody admits it. How would audit help, and what if no rule existed?"
    **Say first:** with a watch rule, `ausearch -k` gives time, auid, command and result; without one, the audit log has nothing and the evidence comes from package verification, file times and shell or sudo logs.

    **Proof:** `sudo ausearch -k sshd-config --format text`; otherwise `rpm -V`, `stat`, `journalctl _COMM=sudo`.

    **Follow-up:** How do you keep the audit log itself from being altered?

---

## Related

- [SELinux](selinux.md), [Log Locations](../09-logging/log-locations.md) and [Suspected Compromise](../interview/scenarios/suspected-compromise.md): AVC records and audit evidence in an investigation

Captured on Rocky Linux 10.2 (audit 4.0.3) on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
