# Round 4: Internals

Senior, SRE and production engineering loops ask what happens underneath a command: which system calls run, which kernel structures change, and why the design trades one property for another. Each question links to the topic file that answers it.

---

## Users and Access

| Question | Answered in |
|---|---|
| How does `sudo` get root privileges, and how does `passwd` update a root-only file? | [Sudo and Su](../04-users-and-access/sudo-and-su.md) |
| `ls -l` prints owner names, but inodes store only UIDs. Where do the names come from? | [Users](../04-users-and-access/users.md) |
| Where does a process get its group list, and why can't it see a new group? | [Groups](../04-users-and-access/groups.md) |
| Why do modern systems hash passwords with yescrypt instead of a fast hash? | [Passwords and Aging](../04-users-and-access/passwords-and-aging.md) |
| What is the difference between `required` and `requisite` in PAM? | [PAM](../04-users-and-access/pam.md) |
| Why does `/var/log/lastlog` look large on a server with three users? | [Login Sessions](../04-users-and-access/login-sessions.md) |
| Why keep a local admin account when all users come from LDAP? | [Centralized Identity](../04-users-and-access/centralized-identity.md) |

---

## How to Answer

- Start from the mechanism (the SUID bit, the NSS lookup, the credentials stored per process), then show the evidence (`ls -l`, `/proc/<pid>/status`).
- Name the trade-off: speed against safety, caching against freshness.
- Stop when the interviewer stops asking; depth on request beats a lecture.
