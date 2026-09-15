# Cannot Log In or Use Sudo

An access failure with several look-alike causes: locked password, expired account, refused shell, PAM lockout, forced password change, or a missing sudo rule. Interviewers use it to see whether the candidate reads the exact message and checks the account record before changing anything.

---

## Symptom

> "A user says they cannot log in to the server, and a second user can log in but gets an error from sudo. Walk me through it."

---

## Clarifying Questions

- **What is the exact message?** Each cause prints a different line; "it doesn't work" is not enough.
- **Password or SSH key?** A locked password does not affect key logins, which changes the whole branch.
- **Did it ever work, and what changed?** Recent `usermod`, sudoers edits or a new security policy narrow the search.
- **One user or everyone?** Everyone failing points at PAM, SSSD or sudoers syntax rather than one account.

---

## Diagnostic Path

### 1. Check the Account Record and Shell

```bash
getent passwd app
sudo su - app
```

Output:

```text
app:x:997:997::/srv/app:/usr/sbin/nologin
su: warning: cannot change directory to /srv/app: No such file or directory
This account is currently not available.
```

A `nologin` or missing shell ends the login after authentication succeeds.

### 2. Check the Password Status

```bash
sudo passwd -S amor
```

Output:

```text
amor L 2026-09-15 0 99999 7 -1
```

`L` means the hash carries a `!` prefix: password logins fail, key logins do not.

### 3. Check Expiry

```bash
sudo chage -l amor | sed -n '4p'
su - amor -c id
```

Output:

```text
Account expires						: Sep 01, 2026
Password: Your account has expired; please contact your system administrator.
su: User account has expired
```

### 4. Check PAM Lockout

```bash
sudo faillock --user amor
```

Output:

```text
amor:
When                Type  Source                                           Valid
2026-09-15 12:21:31 SVC   su-l                                                 V
2026-09-15 12:21:35 SVC   su-l                                                 V
2026-09-15 12:21:38 SVC   su-l                                                 V
```

Three valid failures reach the default `deny=3`, so even the correct password returns `su: Authentication failure`.

### 5. Check for a Forced Password Change

```bash
sudo chage -l amor | head -2
```

Output:

```text
Last password change					: password must be changed
Password expires					: password must be changed
```

The next login prints `You are required to change your password immediately (administrator enforced).`; a non-interactive session fails with `Authentication token manipulation error`.

### 6. Check the Sudo Rule

```bash
sudo -l -U deploy
```

Output:

```text

User deploy may run the following commands on rocky-01:
    (root) NOPASSWD: /usr/bin/systemctl restart nginx, /usr/bin/journalctl -u nginx
```

The rule list shows exactly which commands and arguments match. For a refused user, the journal names the user and the command (Ubuntu host):

```bash
sudo journalctl -t sudo --no-pager | grep 'NOT in sudoers'
```

Output:

```text
Sep 15 12:20:34 ubuntu-01 sudo[1146]:  ibtisam : user NOT in sudoers ; PWD=/home/ibtisam ; USER=root ; COMMAND=/usr/bin/whoami
```

### 7. Check Session Groups and Sudoers Syntax

```bash
id amor
grep Groups /proc/<pid>/status    # a process the user started before the change
sudo visudo -c
```

Output:

```text
uid=1501(amor) gid=1501(amor) groups=1501(amor),1502(developers)
Groups:	1501
/etc/sudoers: parsed OK
/etc/sudoers.d/deploy: parsed OK
/etc/sudoers.d/laborant: parsed OK
```

`id` reads the group files; `/proc` shows what the running session carries. A group added after the session started is missing there until a new login.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Refused shell | `getent passwd` shows `nologin` or a missing path; `pwck -r` reports it | `usermod -s /bin/bash <user>` if the account should log in |
| Locked password | `passwd -S` shows `L` | `passwd -u <user>` |
| Expired account | `chage -l` shows a past "Account expires" | `chage -E -1 <user>` or a new date |
| PAM lockout | `faillock --user` lists failures at the limit | `faillock --user <user> --reset`, then find the source |
| Forced change | "password must be changed" | Interactive login to change it, or `chpasswd` by an admin |
| Not in sudoers | `user NOT in sudoers` in the journal | Add to `wheel` or `sudo`, or a drop-in rule |
| Session predates group change | Group in `id`, missing from `/proc/<pid>/status` | New login or `newgrp` |
| Argument mismatch | `sudo: a password is required` with `-n` | Match the command exactly as listed by `sudo -l` |
| Broken sudoers file | `visudo -c` reports a syntax error | Fix from a root console or with `pkexec visudo` |

---

## Fix

Apply only the branch the evidence supports, and confirm with the same command that found it:

```bash
sudo passwd -u amor && sudo passwd -S amor
sudo chage -E -1 amor && sudo chage -l amor | sed -n '4p'
sudo faillock --user amor --reset
sudo usermod -aG wheel amor
sudo visudo -c
```

---

## Prevention

- Validate every sudoers drop-in with `visudo -cf` before installing it.
- Use `gpasswd -a` or `usermod -aG`; never `usermod -G` alone on admin accounts.
- Disable departing accounts with `chage -E 0` plus key removal, not a password lock alone.
- Keep one local admin account and a root console path for when PAM, SSSD or sudo is broken.
- Alert on repeated `lastb` entries and `faillock` records to catch guessing early.

---

## Related

- [Users](../../04-users-and-access/users.md): the account record and shells
- [Passwords and Aging](../../04-users-and-access/passwords-and-aging.md): locking, expiry, forced change
- [PAM](../../04-users-and-access/pam.md): `pam_faillock` behaviour
- [Groups](../../04-users-and-access/groups.md): when group membership takes effect
- [Sudo and Su](../../04-users-and-access/sudo-and-su.md): rules, exact argument matching, `visudo`

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
