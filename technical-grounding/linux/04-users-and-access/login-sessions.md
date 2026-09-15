# Login Sessions

Every login is recorded in binary accounting files: who is on now, who logged in before, and which attempts failed. These records answer the first questions of any access investigation.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Current sessions | `/run/utmp` (read by `who`, `w`) | `who` |
| Login history and reboots | `/var/log/wtmp` (read by `last`) | `last -n 5` |
| Failed logins | `/var/log/btmp`, mode 660, root and group `utmp` only (read by `lastb`) | `sudo lastb -n 5` |
| Last login per user | `/var/log/lastlog`, a sparse file indexed by UID | `lastlog -u <user>` |
| Load and activity | `w` prints uptime, load and each user's current command | `w` |
| systemd view | `loginctl list-sessions` | `loginctl` |
<!-- --8<-- [end:facts] -->

---

## Current Users and History

```bash
w
last -n 5
lastlog -u amor
```

Output:

```text
 12:35:44 up 18 min,  0 user,  load average: 0.00, 0.00, 0.00
USER     TTY        LOGIN@   IDLE   JCPU   PCPU WHAT
reboot   system boot  6.1.167          Tue Sep 15 12:17   still running

wtmp begins Tue Sep 15 12:17:13 2026
Username         Port     From                                      Latest
amor                                                                Tue Sep 15 12:22:32 +0000 2026
```

No terminal session was open when this ran, so `w` lists no users. `last` lists reboots as the pseudo-user `reboot`, with the kernel version, which makes it a quick uptime history.

---

## Failed Logins

```bash
sudo lastb -n 3
```

Output:

```text
amor                                   Tue Sep 15 12:21 - 12:21  (00:00)
amor                                   Tue Sep 15 12:21 - 12:21  (00:00)
amor                                   Tue Sep 15 12:21 - 12:21  (00:00)

btmp begins Tue Sep 15 12:20:57 2026
```

These are the three failed `su` attempts that triggered the `pam_faillock` lock in the PAM topic.

---

## The Sparse lastlog File

```bash
ls -ls /var/log/lastlog
du -h --apparent-size /var/log/lastlog
du -h /var/log/lastlog
```

Output:

```text
12 -rw-rw-r-- 1 root utmp 438876 Sep 15 12:22 /var/log/lastlog
429K	/var/log/lastlog
12K	/var/log/lastlog
```

`lastlog` stores one fixed-size record at the offset of each UID, so a high UID makes the file look large while only 12 KB of blocks exist. Copying it with a tool that does not preserve holes (`cp --sparse=never`) inflates it for real.

!!! note "Where these files are going"
    `utmp`, `wtmp` and `lastlog` use 32-bit timestamps, which overflow in 2038. Newer releases replace them with `wtmpdb` and `lastlog2`; Rocky Linux 10.2 and Ubuntu 24.04 still use the classic files.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Which files record current logins, past logins and failed logins?"
    **Say first:** `/run/utmp` for current sessions, `/var/log/wtmp` for history and reboots, `/var/log/btmp` for failures.

    **Proof:** `who`, `last` and `sudo lastb` read them in that order.

    **Follow-up:** Why is `btmp` not world-readable? (Users sometimes type a password into the username prompt.)
<!-- --8<-- [end:l1] -->

??? question "L2: Show when the server last rebooted and who logged in since."
    **Say first:** `last` reads `wtmp`, which records both.

    **Proof:** `last -x -n 20` includes `reboot` and `shutdown` entries.

    **Follow-up:** Which command gives only the current uptime? (`uptime` or the first line of `w`.)

??? question "L2: List users who have never logged in."
    **Say first:** `lastlog` marks them explicitly.

    **Proof:** `lastlog | grep 'Never logged in'`.

    **Follow-up:** Why is this useful during an access review?

??? question "L3: The server feels slow and you suspect someone is running a heavy job."
    **Say first:** `w` shows logged-in users, their idle time and their current command next to the load average.

    **Proof:** `w`, then `ps -u <user> --sort=-%cpu | head`.

    **Follow-up:** What does `w` miss? (Processes started by cron or services, which have no login session.)

??? question "L3: lastb shows thousands of entries from one address."
    **Say first:** a password-guessing attack against SSH or another PAM service.

    **Proof:** `sudo lastb | awk '{print $3}' | sort | uniq -c | sort -rn | head`.

    **Follow-up:** Which controls stop it? (Key-only SSH, `fail2ban`, `pam_faillock`.)

??? question "L4: Why does ls show /var/log/lastlog as hundreds of kilobytes on a server with three users?"
    **Say first:** it is a sparse file: records are written at the offset of each UID, and the gaps have no allocated blocks.

    **Proof:** `ls -ls` shows 12 blocks against a 438876-byte size.

    **Don't say:** "the log needs rotation."

---

## Related

- [PAM](pam.md): the lockout behind the failed attempts above
- [Users](users.md): the UIDs that index `lastlog`

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
