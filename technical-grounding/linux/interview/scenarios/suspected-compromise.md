# Suspected Compromise

A server behaves strangely and may be compromised. The interviewer checks whether the candidate triages calmly and in order (processes, connections, accounts, persistence, integrity), preserves evidence, and knows when to isolate and rebuild rather than clean.

---

## Symptom

> "This server is behaving strangely: high CPU, odd network traffic, and we think it's compromised. What do you do?"

---

## Clarifying Questions

- **Can we isolate it now?** Containing the host (network, not power) stops spread and preserves memory and volatile state.
- **What first looked wrong?** CPU, traffic, an alert, or a file, each gives a starting thread.
- **Is there an off-host baseline?** An AIDE database or package manifest the attacker could not touch is the strongest evidence.
- **What is the value at risk?** Decides isolate-and-investigate versus rebuild-from-known-good.

---

## Diagnostic Path

Run read-only commands first and record their output off the host. The examples are from `web` (Rocky Linux 10.2).

### 1. Unexpected Listeners and Processes

```bash
sudo ss -tlnp 'sport = :44444'
```

Output:

```text
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess                                 
LISTEN 0      10         127.0.0.1:44444      0.0.0.0:*    users:(("lab-listener",pid=95686,fd=3))
```

An unfamiliar listener is the thread to pull. Follow the PID to what is actually running:

```bash
sudo ls -l /proc/95686/exe
ps -o pid,ppid,user,cmd -p 95686
```

Output:

```text
lrwxrwxrwx. 1 deploy deploy 0 Sep 17 17:12 /proc/95686/exe -> /tmp/lab-listener
    PID    PPID USER     CMD
  95686   95683 deploy   /tmp/lab-listener -lk 127.0.0.1 44444
```

`/proc/PID/exe` shows the real binary even if the command line is disguised; here it runs from `/tmp`, a strong signal. A binary shown as `(deleted)` is running after its file was removed, common with malware, while `/proc/PID/cwd`, `/proc/PID/environ` and `lsof -p PID` add context. Note the PID and copy the binary before killing anything.

### 2. Recently Written Files in World-Writable Places

```bash
sudo find /tmp /dev/shm /var/tmp -type f -newermt '-30 min' 2>/dev/null | head
sudo find / -xdev -perm -4000 -type f 2>/dev/null | grep -vE '/(chage|chfn|chsh|crontab|gpasswd|mount|newgrp|passwd|pkexec|su|sudo|umount|polkit|pam_timestamp|unix_chkpwd|userhelper)$'
```

Output:

```text
/tmp/lab-listener
/tmp/aide-init.log
/tmp/cis-report.html
/usr/lib/polkit-1/polkit-agent-helper-1
/usr/sbin/exim
/usr/sbin/pam_timestamp_check
```

Recent files in `/tmp`, `/dev/shm` and `/var/tmp`, and any setuid binary outside the known set, are candidates. `/usr/sbin/exim` looked alarming but `rpm -qf /usr/sbin/exim` traced it to an installed package (a `fail2ban` dependency), not an implant: identify the owner before reacting.

### 3. Accounts and Logins

```bash
awk -F: '$3==0 {print $1}' /etc/passwd
last -n 3 -w
sudo lastb -n 3
```

Output:

```text
root
reboot   system boot  6.1.167          Thu Sep 17 12:54   still running
backup   ssh:notty    172.16.0.2       Thu Sep 17 16:00 - 16:00  (00:00)
```

Only `root` should have UID 0; `last` shows successful logins and `lastb` shows failed ones. The `backup` entries in `lastb` are the failed SSH attempts from an earlier test, the kind of noise that also marks a brute-force attempt. Check `/etc/passwd`, `/etc/shadow` and `/etc/sudoers.d/` for added accounts or rules.

### 4. Persistence

```bash
ls /etc/cron.d/
systemctl list-unit-files --state=enabled --type=service --no-legend
crontab -l -u deploy
```

Attackers persist through cron (`/etc/cron.d/`, per-user crontabs), systemd units and timers, shell rc files, and `authorized_keys`. Compare the enabled units and cron jobs with a known-good list; a service that runs a binary from `/tmp` or `/home` is a red flag.

### 5. Integrity Against an Off-Host Baseline

```bash
sudo aide --check
sudo rpm -Va | awk '$1 ~ /5/ && $2 != "c"'
```

An AIDE database kept off the host, or `rpm -Va` run from trusted media, shows changed binaries and configuration. On a host where root may be compromised, the local package database and AIDE database cannot be trusted; verify from outside. [Compliance and Integrity](../../15-security/compliance-and-integrity.md) shows both tools.

---

## Root Causes

Compromise is a category, not one cause. The triage sorts findings into:

| Finding | Evidence | Action |
|---|---|---|
| Malicious process | `/proc/PID/exe` in `/tmp` or `(deleted)`, odd listener | Preserve, then isolate the host |
| Added account or sudo rule | New UID 0, new `sudoers.d` file | Record, disable, investigate |
| Persistence | cron/unit/rc running an odd binary | Record it before removing it |
| Changed binaries | AIDE or `rpm -Va` against an off-host baseline | Treat the host as untrusted |
| Only failed logins, nothing else | `lastb` noise, no other finding | Harden SSH; likely not breached |

---

## Fix

Do not clean a compromised host in place: an attacker with root can hide from every local tool. Isolate it from the network (keep it powered for memory forensics if needed), preserve evidence (process list, `/proc/PID/exe` copies, logs, disk image), rotate every credential the host could reach, and rebuild from known-good media and configuration.

---

## Prevention

- Keep an AIDE baseline off the host and ship logs and audit records to a separate system.
- Enforce keys-only SSH, least-privilege sudo, SELinux enforcing and a default-deny firewall ([Hardening Checklist](../../15-security/hardening-checklist.md)).
- Watch for processes running from writable directories and for new setuid files.
- Have an incident plan: isolate, preserve, rotate, rebuild.

---

## Related

- [Viewing Processes](../../07-processes/viewing-processes.md) and [Ports and Sockets](../../13-networking/ports-and-sockets.md): finding the process behind a socket
- [auditd](../../15-security/auditd.md) and [Compliance and Integrity](../../15-security/compliance-and-integrity.md): audit records and integrity checks
- [Hardening Checklist](../../15-security/hardening-checklist.md): the controls that prevent and detect this

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The suspicious process was a benign lab listener; the failed logins are from an earlier SSH test.
