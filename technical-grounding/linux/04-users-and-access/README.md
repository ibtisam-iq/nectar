# Users and Access

Who an account is, which groups it carries, how it authenticates, and how it gains root: the identity layer that every permission check and every audit trail depends on.

---

## Revision Card

| Fact | Value |
|---|---|
| Root | UID 0; the kernel checks the number, not the name |
| System UIDs | RHEL 10: 201 to 999; Ubuntu: 100 to 999; regular from 1000 |
| `/etc/passwd` | 7 fields, mode 644; `x` means the hash is in `/etc/shadow` |
| `/etc/shadow` | 9 fields, mode 000; `!` prefix means locked |
| `/etc/group` | 4 fields; member list holds supplementary members only |
| Hash format | `$y$` yescrypt on RHEL 10 and Ubuntu 24.04 |
| Admin group | `wheel` (RHEL), `sudo` (Ubuntu) |
| Group changes | Apply to new logins only; running sessions keep the old list |
| Sudo password | The caller's own; cached 5 minutes per terminal |
| Sudoers arguments | Matched exactly unless the rule ends in `*` |
| Lockout | `pam_faillock`, default 3 failures |
| Password lock vs SSH keys | A locked password does not block key logins |

| Task | Command |
|---|---|
| Create a login user (both families) | `useradd -m -s /bin/bash <user>` |
| Create a service account | `useradd -r -s /usr/sbin/nologin -d /srv/<app> -M <app>` |
| Append a group | `usermod -aG <group> <user>` |
| Remove from one group | `gpasswd -d <user> <group>` |
| Lock / check / restore a password | `passwd -l`, `passwd -S`, `passwd -u` |
| Force a password change | `chage -d 0 <user>` |
| Expire an account | `chage -E 0 <user>` (remove with `-E -1`) |
| Delegate one command | Drop-in in `/etc/sudoers.d/`, checked with `visudo -cf` |
| List a user's sudo rights | `sudo -l -U <user>` |
| Clear a lockout | `faillock --user <user> --reset` |
| Find orphaned files | `find / -xdev -nouser` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Users](users.md) | `/etc/passwd`, UID ranges, `useradd`/`adduser` differences, service accounts, `usermod`, `userdel` | Core | High |
| [Groups](groups.md) | Primary vs supplementary, `usermod -aG`, `gpasswd`, group admins, when membership takes effect | Core | High |
| [Passwords and Aging](passwords-and-aging.md) | `/etc/shadow`, hash formats, locking, `chage`, expiry, scripted passwords | Core | Med |
| [Sudo and Su](sudo-and-su.md) | `su` vs `sudo`, sudoers rules, drop-ins, exact argument matching, builtins, how sudo gets root | Core | High |
| [PAM](pam.md) | Stack types and control flags, `authselect`, `pam_faillock` | Core | Low |
| [Login Sessions](login-sessions.md) | `who`, `w`, `last`, `lastb`, `lastlog`, the accounting files | Core | Low |
| [Centralized Identity](centralized-identity.md) | NSS, SSSD, `realm join`, directory caching | Advanced | Low |

---

## Scenarios and Labs

- [Cannot Log In or Use Sudo](../interview/scenarios/cannot-login-or-sudo.md): the troubleshooting drill for this module
- [Users and Permissions Lab](../labs/users-and-permissions-lab.md): hands-on tasks with collapsed solutions
