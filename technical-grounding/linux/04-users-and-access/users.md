# Users

A Linux user is a numeric UID with a name, a home directory and a login shell recorded in `/etc/passwd`. Every file owner, every process and every permission check resolves to that UID, so account mistakes surface later as permission problems.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Superuser | UID 0 (any account with UID 0 is root) | `awk -F: '$3 == 0' /etc/passwd` |
| Account database | `/etc/passwd`, mode 644 (world-readable) | `ls -l /etc/passwd` |
| Password hashes | `/etc/shadow`, mode 000 (root only) | `ls -l /etc/shadow` |
| `/etc/passwd` fields | 7: name, `x`, UID, GID, GECOS, home, shell | `getent passwd root` |
| Regular UID range | 1000 to 60000 | `grep '^UID_M' /etc/login.defs` |
| System UID range | RHEL 10: 201 to 999; Ubuntu: 100 to 999 | `grep SYS_UID /etc/login.defs` |
| Unprivileged overflow user | `nobody`, UID 65534 | `id nobody` |
| Account defaults | `/etc/login.defs` and `useradd -D` | `useradd -D` |
| Home directory template | `/etc/skel` | `ls -la /etc/skel` |
| Shell that refuses logins | `/usr/sbin/nologin` | `su - <service-user>` |
| Lookup through NSS | `getent passwd <name or UID>` | `getent passwd 0` |
| Consistency check | `pwck -r` (read-only) | `pwck -r` |
<!-- --8<-- [end:facts] -->

---

## The /etc/passwd Record

Each line is one account with seven colon-separated fields. The second field holds `x` because the hash moved to `/etc/shadow`, which only root can read.

```bash
getent passwd root laborant nobody
```

Output:

```text
root:x:0:0:Super User:/root:/bin/bash
laborant:x:1001:1001::/home/laborant:/bin/bash
nobody:x:65534:65534:Kernel Overflow User:/:/usr/sbin/nologin
```

| # | Field | Example | Meaning |
|---|---|---|---|
| 1 | Login name | `laborant` | Name shown by `ls -l` and `ps` |
| 2 | Password | `x` | Placeholder; the hash lives in `/etc/shadow` |
| 3 | UID | `1001` | The identity the kernel checks |
| 4 | GID | `1001` | Primary group |
| 5 | GECOS | empty | Full name or comment |
| 6 | Home | `/home/laborant` | Working directory after login |
| 7 | Shell | `/bin/bash` | Program started at login |

---

## UID Ranges and Account Types

The kernel treats UID 0 as special and nothing else. The split between system and regular accounts is a convention in `/etc/login.defs` that `useradd` follows when it picks the next free UID.

=== "RHEL / Rocky"

    ```bash
    grep -E '^(UID_MIN|UID_MAX|SYS_UID_MIN|SYS_UID_MAX|CREATE_HOME)' /etc/login.defs
    ```

    Output:

    ```text
    UID_MIN                  1000
    UID_MAX                 60000
    SYS_UID_MIN               201
    SYS_UID_MAX               999
    CREATE_HOME	yes
    ```

=== "Ubuntu / Debian"

    ```bash
    grep -E '^#?\s*(SYS_UID_MIN|SYS_UID_MAX|CREATE_HOME)' /etc/login.defs
    ```

    Output:

    ```text
    #SYS_UID_MIN		  100
    #SYS_UID_MAX		  999
    ```

    The system range lines are commented out, so the built-in defaults (100 to 999) apply. `CREATE_HOME` is absent, which changes what `useradd` does (next section).

---

## Creating Accounts

`useradd` is the low-level tool on both families, but its defaults differ. On Ubuntu, `adduser` is a separate Perl script that applies the friendlier defaults; on RHEL, `adduser` is only a symlink to `useradd`.

=== "RHEL / Rocky"

    ```bash
    useradd -D
    ls -l /usr/sbin/adduser
    sudo useradd amor
    getent passwd amor
    ls -ld /home/amor
    ```

    Output:

    ```text
    # ... (trimmed)
    SHELL=/bin/bash
    SKEL=/etc/skel
    # ... (trimmed)
    lrwxrwxrwx 1 root root 7 Feb 23  2026 /usr/sbin/adduser -> useradd
    amor:x:1002:1002::/home/amor:/bin/bash
    drwx------ 2 amor amor 4096 Sep 15 12:18 /home/amor
    ```

=== "Ubuntu / Debian"

    ```bash
    useradd -D
    sudo useradd amor
    getent passwd amor
    ls -ld /home/amor
    ```

    Output:

    ```text
    # ... (trimmed)
    SHELL=/bin/sh
    SKEL=/etc/skel
    # ... (trimmed)
    amor:x:1002:1002::/home/amor:/bin/sh
    ls: cannot access '/home/amor': No such file or directory
    ```

    ```bash
    sudo adduser --disabled-password --gecos '' ibtisam
    ls -la /home/ibtisam
    ```

    Output:

    ```text
    info: Adding user `ibtisam' ...
    info: Selecting UID/GID from range 1000 to 59999 ...
    info: Adding new group `ibtisam' (1003) ...
    info: Adding new user `ibtisam' (1003) with group `ibtisam (1003)' ...
    info: Creating home directory `/home/ibtisam' ...
    info: Copying files from `/etc/skel' ...
    info: Adding new user `ibtisam' to supplemental / extra groups `users' ...
    info: Adding user `ibtisam' to group `users' ...
    total 20
    drwxr-x--- 2 ibtisam ibtisam 4096 Sep 15 12:18 .
    drwxr-xr-x 5 root    root    4096 Sep 15 12:18 ..
    -rw-r--r-- 1 ibtisam ibtisam  220 Sep 15 12:18 .bash_logout
    -rw-r--r-- 1 ibtisam ibtisam 3771 Sep 15 12:18 .bashrc
    -rw-r--r-- 1 ibtisam ibtisam  807 Sep 15 12:18 .profile
    ```

!!! warning "On Ubuntu, useradd without -m creates no home and assigns /bin/sh"
    `/bin/sh` on Ubuntu is `dash`, so the account gets no history, no tab completion and no `.bashrc`. Scripts that must work on both families pass the options explicitly: `useradd -m -s /bin/bash <name>`.

| Option | Effect |
|---|---|
| `-m` / `-M` | Create / do not create the home directory |
| `-d <dir>` | Home directory path |
| `-s <shell>` | Login shell |
| `-u <uid>` | Fixed UID (needed when UIDs must match across hosts, for example NFS) |
| `-g <group>` / `-G <g1,g2>` | Primary group / supplementary groups |
| `-r` | System account: UID from the system range, no aging |

---

## Service Accounts

Daemons run under dedicated accounts so a compromise is limited to what that UID owns. The standard shape is a system UID, no usable shell, and a home that is the application directory.

```bash
sudo useradd -r -s /usr/sbin/nologin -d /srv/app -M app
getent passwd app
sudo su - app
sudo su - app -s /bin/bash -c id
```

Output:

```text
app:x:997:997::/srv/app:/usr/sbin/nologin
su: warning: cannot change directory to /srv/app: No such file or directory
This account is currently not available.
su: warning: cannot change directory to /srv/app: No such file or directory
uid=997(app) gid=997(app) groups=997(app)
```

`-M` skips the home directory, so `/srv/app` has to be created and owned separately. System UIDs are handed out from the top of the range down (997 on Rocky, 999 on Ubuntu), which keeps them away from regular users.

`useradd -m` and `adduser` copy `/etc/skel` into the new home (the Ubuntu `adduser` output above shows the copy). Files placed there reach every future account, never existing ones. Home permissions differ by default: RHEL creates `drwx------` (700), Ubuntu `drwxr-x---` (750).

---

## Modifying Accounts

`usermod` edits one field at a time and validates less than expected.

```bash
sudo useradd -u 1500 -c "Ibtisam" -s /bin/bash -m ibtisam
sudo usermod -s /bin/zsh ibtisam
sudo usermod -l ibt ibtisam
getent passwd ibt
sudo usermod -d /home/ibt -m ibt
getent passwd ibt
ls -ld /home/ibt
```

Output:

```text
usermod: Warning: missing or non-executable shell '/bin/zsh'
ibt:x:1500:1500:Ibtisam:/home/ibtisam:/bin/zsh
ibt:x:1500:1500:Ibtisam:/home/ibt:/bin/zsh
drwx------ 2 ibt ibtisam 4096 Sep 15 12:18 /home/ibt
```

!!! warning "usermod -l renames the login only"
    The home directory keeps its old path until `usermod -d <new> -m` moves it, and the private group keeps its old name (`ibtisam` above) until `groupmod -n` renames it. The shell change also succeeded even though `/bin/zsh` does not exist, which locks the user out at the next login.

| Task | Command |
|---|---|
| Change shell | `usermod -s /bin/bash <user>` |
| Rename login | `usermod -l <new> <old>` (then `groupmod -n` and `usermod -d -m`) |
| Move home | `usermod -d /home/<new> -m <user>` |
| Lock / re-enable password | `usermod -L <user>` / `usermod -U <user>` |

---

## Deleting Accounts

`userdel` refuses while the user has processes, and without `-r` it leaves the home directory behind. The files keep the numeric UID, which the next account may or may not receive.

```bash
sudo userdel amor
sudo pkill -u amor
sudo userdel amor
ls -ld /home/amor
sudo find / -xdev -nouser 2>/dev/null
sudo useradd amor
id amor
ls -ld /home/amor
sudo userdel -r amor
```

Output:

```text
userdel: user amor is currently used by process 1244
drwx------ 2 1002 1002 4096 Sep 15 12:18 /home/amor
/home/amor
# ... (trimmed)
/var/spool/mail/amor
/tmp/amor-report.txt
useradd: warning: the home directory /home/amor already exists.
useradd: Not copying any file from skel directory into it.
Creating mailbox file: File exists
uid=1501(amor) gid=1501(amor) groups=1501(amor)
drwx------ 2 1002 1002 4096 Sep 15 12:18 /home/amor
userdel: /var/spool/mail/amor not owned by amor, not removing
userdel: /home/amor not owned by amor, not removing
```

The first `userdel` failed on a running `sleep` owned by `amor`; the second succeeded after `pkill`. The re-created `amor` received UID 1501 (one above the highest in use), not the old 1002, so the new account cannot write to its own home.

!!! danger "userdel -r removes the home directory and mail spool"
    Files the user owned elsewhere (`/tmp`, `/srv`, shared directories) stay behind as orphans. Archive the home first when the data may matter: `tar -czf /root/<user>-home.tgz /home/<user>`.

---

## Looking Up Accounts

`getent` asks NSS, the same path the system uses, so it also returns accounts from LDAP or SSSD. Reading `/etc/passwd` directly only shows local accounts.

```bash
awk -F: '$3 == 0 {print $1}' /etc/passwd
sudo pwck -r
```

Output:

```text
root
user 'ibt': program '/bin/zsh' does not exist
pwck: no changes
```

`pwck -r` caught the missing shell that `usermod -s` accepted earlier.

---

## Common Errors

### `useradd: user 'amor' already exists`

**Cause:** the login name is already in `/etc/passwd` (or in LDAP, if NSS includes it).

**Fix:** check with `getent passwd amor`; modify the existing account with `usermod` instead of re-creating it.

### `userdel: user amor is currently used by process 1244`

**Cause:** a process still runs under the UID.

**Fix:** inspect with `ps -u amor`, stop it (`pkill -u amor`), then run `userdel` again.

### `userdel: /home/amor not owned by amor, not removing`

**Cause:** the home belongs to a previous account's UID.

**Fix:** decide the data's fate, then `chown -R amor:amor /home/amor` or remove it manually.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Why does the password field in /etc/passwd contain only an x?"
    **Say first:** `/etc/passwd` must be world-readable so any process can map UIDs to names, so the hashes moved to `/etc/shadow`, which only root can read.

    **Proof:** `ls -l /etc/passwd /etc/shadow` shows modes 644 and 000.

    **Follow-up:** How does a normal user change their own password if they cannot read `/etc/shadow`? (See sudo and su: SUID `passwd`.)

??? question "L1: What actually separates a system account from a regular account?"
    **Say first:** only the UID range convention in `/etc/login.defs`; the kernel treats every UID except 0 the same way.

    **Proof:** `useradd -r` picks a UID below 1000 and skips password aging; `grep SYS_UID /etc/login.defs` shows the range.

    **Follow-up:** What makes an account unable to log in, if not its UID?
<!-- --8<-- [end:l1] -->

??? question "L2: Create an account for an application that cannot log in and whose home is /srv/app."
    **Say first:** a system UID, `nologin` as the shell, and the application directory as home.

    **Proof:**

    ```bash
    sudo useradd -r -s /usr/sbin/nologin -d /srv/app -m app
    sudo -u app id
    ```

    **Follow-up:** How would you run a one-off command as `app` for debugging?

??? question "L2: Rename the user ibtisam to ibt, including the home directory."
    **Say first:** `usermod -l` renames the login only, so the home and the private group need their own steps.

    **Proof:**

    ```bash
    sudo usermod -l ibt ibtisam
    sudo usermod -d /home/ibt -m ibt
    sudo groupmod -n ibt ibtisam
    ```

    **Follow-up:** Which running processes still show the old name, and why?

??? question "L3: A user was deleted and re-created; now they cannot write to their home directory."
    **Say first:** check the numeric owner of the home against the new UID before anything else.

    **Proof:** `ls -ldn /home/<user>` shows the old UID; `id <user>` shows the new one. `useradd` picks the next UID above the highest in use, not the freed one.

    **Follow-up:** How do you find every other file the old UID still owns? (`find / -xdev -uid <old>`)

??? question "L3: A user's login closes immediately after the password is accepted."
    **Say first:** look at the login shell field before looking at PAM.

    **Proof:** `getent passwd <user>` shows the shell; `pwck -r` reports a shell that does not exist; `nologin` prints "This account is currently not available."

    **Follow-up:** Why did `usermod -s` allow a missing shell in the first place?

??? question "L4: ls -l prints owner names, but inodes store only UIDs. Where do the names come from?"
    **Say first:** `ls` calls `getpwuid()` for each UID, which goes through NSS (`/etc/nsswitch.conf`) to files, SSSD or LDAP.

    **Proof:** after `userdel`, `ls -l` shows the bare number `1002`, because the lookup fails and there is no name to print.

    **Don't say:** "the username is stored in the file."

---

## Related

- [Groups](groups.md): primary and supplementary groups, `usermod -aG`
- [Passwords and Aging](passwords-and-aging.md): `/etc/shadow`, locking, expiry
- [Sudo and Su](sudo-and-su.md): privileged access for these accounts
- [Centralized Identity](centralized-identity.md): accounts that come from LDAP or SSSD instead of `/etc/passwd`

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
