# Groups

A group is a GID that several users share, so one permission grant covers all of them. Every user has exactly one primary group and any number of supplementary groups, and a process receives its group list at login, not when the group file changes.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Primary group | GID in field 4 of `/etc/passwd` | `id -gn <user>` |
| Supplementary groups | Member list in field 4 of `/etc/group` | `id -Gn <user>` |
| `/etc/group` fields | 4: name, `x`, GID, member list | `getent group wheel` |
| Group passwords and admins | `/etc/gshadow`, root only | `sudo grep <group> /etc/gshadow` |
| User private groups | Each new user gets a group of the same name (`USERGROUPS_ENAB yes`) | `grep USERGROUPS_ENAB /etc/login.defs` |
| RHEL admin group | `wheel`, GID 10 | `getent group wheel` |
| Ubuntu admin group | `sudo`, GID 27 | `getent group sudo` |
| New files get | The creator's primary (effective) group | `touch f; ls -l f` |
| Membership takes effect | At the next login or `newgrp`, not in running sessions | `grep Groups /proc/$$/status` |
| Append a group | `usermod -aG <group> <user>` (`-G` alone replaces the list) | `id <user>` |
<!-- --8<-- [end:facts] -->

---

## The /etc/group Record

```bash
sudo groupadd devs
sudo groupadd -g 5000 ops
getent group devs ops wheel
```

Output:

```text
devs:x:1502:
ops:x:5000:
wheel:x:10:laborant,amor
```

| # | Field | Example | Meaning |
|---|---|---|---|
| 1 | Name | `wheel` | Group name |
| 2 | Password | `x` | Placeholder; real data in `/etc/gshadow` |
| 3 | GID | `10` | Numeric ID stored on files |
| 4 | Members | `laborant,amor` | Supplementary members only |

The member list never includes users whose primary group this is. `getent group amor` shows an empty list even though `amor` is in it through `/etc/passwd`.

---

## Adding and Removing Members

`usermod -G` sets the complete supplementary list, so any group left out is removed. `-a` switches it to append mode.

```bash
sudo usermod -aG devs amor
id amor
sudo usermod -G ops amor
id amor
sudo usermod -aG devs,wheel amor
id amor
```

Output:

```text
uid=1501(amor) gid=1501(amor) groups=1501(amor),1502(devs)
uid=1501(amor) gid=1501(amor) groups=1501(amor),5000(ops)
uid=1501(amor) gid=1501(amor) groups=1501(amor),10(wheel),1502(devs),5000(ops)
```

The second command dropped `devs` silently because `-a` was missing.

!!! warning "usermod -G without -a replaces every supplementary group"
    On an admin account this removes `wheel` or `sudo` along with everything else, and the mistake only shows at the next `sudo`. `gpasswd -a` has no replace mode, which makes it the safer habit for single additions.

`gpasswd` edits one group at a time and reports what it did:

```bash
sudo gpasswd -d amor devs
sudo gpasswd -a amor devs
sudo gpasswd -M amor,ibt devs
getent group devs
groups amor
```

Output:

```text
Removing user amor from group devs
Adding user amor to group devs
devs:x:1502:amor,ibt
amor : amor wheel devs ops
```

| Task | Command |
|---|---|
| Add one member | `gpasswd -a <user> <group>` or `usermod -aG <group> <user>` |
| Remove one member | `gpasswd -d <user> <group>` |
| Set the full member list | `gpasswd -M <u1,u2> <group>` |
| Remove a user from one group (keep others) | `usermod -rG <group> <user>` (present in shadow-utils 4.13 on Ubuntu 24.04 and 4.15 on RHEL 10) |

---

## Group Administrators

`gpasswd -A` delegates membership management of one group to a non-root user. The delegation lives in `/etc/gshadow`.

```bash
sudo gpasswd -A amor devs
sudo grep devs /etc/gshadow
```

Output:

```text
devs:!:amor:amor,ibt
```

`/etc/gshadow` fields: name, password (`!` means no group password), administrators, members.

---

## Primary Group Changes

`usermod -g` changes the primary group, and `groupdel` refuses to remove a group that is still someone's primary group.

```bash
sudo groupdel amor
sudo usermod -g ops amor
id amor
sudo groupmod -n developers devs
id amor
```

Output:

```text
groupdel: cannot remove the primary group of user 'amor'
uid=1501(amor) gid=5000(ops) groups=5000(ops),10(wheel),1502(devs)
uid=1501(amor) gid=5000(ops) groups=5000(ops),10(wheel),1502(developers)
```

`groupmod -n` changes only the name. Files keep GID 1502, so they follow the rename with no `chgrp` needed.

---

## When Membership Takes Effect

The kernel stores the group list in each process's credentials. `id <user>` reads the group files and shows the new state, while processes started before the change keep the old list until they exit.

```bash
sudo usermod -g amor -G "" amor
sudo su - amor -c 'sleep 600' &
sudo usermod -aG developers amor
id amor
grep -E '^(Uid|Gid|Groups)' /proc/$(pgrep -u amor sleep)/status
sudo su - amor -c id
```

Output:

```text
uid=1501(amor) gid=1501(amor) groups=1501(amor),1502(developers)
Uid:	1501	1501	1501	1501
Gid:	1501	1501	1501	1501
Groups:	1501
uid=1501(amor) gid=1501(amor) groups=1501(amor),1502(developers)
```

The running `sleep` still carries only group 1501. A new login (the last command) receives `developers`.

`newgrp` starts a new shell with a different effective group, which also decides the group of files created in that shell:

```bash
sudo su - amor -c 'id -gn; newgrp developers <<< "id -gn; touch /tmp/ng-test; ls -l /tmp/ng-test"'
```

Output:

```text
amor
developers
-rw-r--r-- 1 amor developers 0 Sep 15 12:22 /tmp/ng-test
```

!!! tip "Refreshing groups without logging out"
    `newgrp <group>` or `su - $USER` starts a shell with the new list. Services need a restart for the same reason, which is why a user added to the `docker` group still gets a socket permission error until a new session starts.

---

## Admin Groups by Distribution

=== "RHEL / Rocky"

    ```bash
    getent group wheel
    sudo grep -E '^%wheel' /etc/sudoers
    ```

    Output:

    ```text
    wheel:x:10:laborant,amor
    %wheel	ALL=(ALL)	ALL
    ```

=== "Ubuntu / Debian"

    ```bash
    getent group sudo
    sudo grep -E '^%(sudo|admin)' /etc/sudoers
    ```

    Output:

    ```text
    sudo:x:27:ubuntu,laborant,ibtisam
    %admin ALL=(ALL) ALL
    %sudo	ALL=(ALL:ALL) ALL
    ```

    `%admin` is a legacy rule; the `admin` group does not exist on a fresh 24.04 install (`getent group admin` returns nothing).

---

## Common Errors

### `groupdel: cannot remove the primary group of user 'amor'`

**Cause:** the group is the primary group (GID field in `/etc/passwd`) of an existing user.

**Fix:** move the user first with `usermod -g <other-group> amor`, or delete the user.

### `groupadd: group 'amor' already exists`

**Cause:** the name is taken, often by the user private group that `useradd` created for a user of the same name.

**Fix:** `getent group amor` to inspect it; reuse it or pick another name.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a primary and a supplementary group?"
    **Say first:** the primary group is the single GID in `/etc/passwd` and becomes the group of new files; supplementary groups come from the member lists in `/etc/group` and only add access.

    **Proof:** `id amor` shows `gid=` (primary) and `groups=` (all of them).

    **Follow-up:** How do you create a file owned by a supplementary group without `chgrp`? (`newgrp`, or an SGID directory.)

??? question "L1: Why does every new user get a group with the same name?"
    **Say first:** user private groups (`USERGROUPS_ENAB yes`) let the default umask allow group write without exposing files to other users.

    **Proof:** `useradd amor` creates group `amor` with the same ID; `grep USERGROUPS_ENAB /etc/login.defs`.

    **Follow-up:** What changes about group collaboration because of this default?
<!-- --8<-- [end:l1] -->

??? question "L2: Add a user to the docker group without touching their other groups."
    **Say first:** append, never replace.

    **Proof:**

    ```bash
    sudo usermod -aG docker <user>
    id <user>
    ```

    **Follow-up:** The user runs `docker ps` right after this and gets permission denied. Why?

??? question "L2: Let a team lead manage members of the devs group without root."
    **Say first:** make them a group administrator.

    **Proof:** `sudo gpasswd -A lead devs`; the lead then runs `gpasswd -a newhire devs`.

    **Follow-up:** Where is that delegation stored? (`/etc/gshadow`, third field.)

??? question "L3: A user was added to a group but still gets permission denied on the group's files."
    **Say first:** compare the group files with the live process credentials before touching permissions.

    **Proof:** `id <user>` shows the group; `grep Groups /proc/<pid>/status` for the user's shell does not. The session started before the change.

    **Follow-up:** Which fix avoids a full logout? (`newgrp <group>` or a fresh `su - <user>`.)

??? question "L3: After a routine change, an engineer lost sudo and access to every project directory."
    **Say first:** suspect `usermod -G` without `-a`.

    **Proof:** `id <user>` shows only the last group set; `sudo journalctl -t usermod` shows each change (`usermod[2110]: lock user 'amor' password` is the format).

    **Follow-up:** How do you restore the previous membership? (`/etc/group-` holds the previous copy of the file.)

??? question "L4: Where does a process get its group list, and why can't it see a new group?"
    **Say first:** at login, `login`, `sshd` or `su` call `initgroups()` and `setgroups()` from the group database; children inherit the list across `fork()` and `exec()`.

    **Proof:** `/proc/<pid>/status` shows the `Groups:` line fixed at the value the session started with.

    **Don't say:** "Linux caches groups and the cache needs a refresh."

---

## Related

- [Users](users.md): the primary GID lives in `/etc/passwd`
- [Sudo and Su](sudo-and-su.md): `wheel` and `sudo` group rules
- [Login Sessions](login-sessions.md): when a new session starts

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
