# Users and Permissions Lab

Build and break the identity layer of a server: accounts, groups, aging, sudo delegation and lockouts. Run it on a `rockylinux` playground; tasks that differ on Ubuntu say so.

---

## Setup

Open a root shell on a fresh playground and confirm the starting point:

```bash
sudo -i
getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {print $1, $3}'
```

---

## Users and Groups

### 1. Create the Team

Create the groups `devs` (GID 3000) and `ops` (GID 3001). Create users `amor` (UID 2001) and `ibtisam` (UID 2002) with home directories and `/bin/bash`; `amor` joins `devs`, `ibtisam` joins `devs` and `ops`.

??? tip "Solution"
    ```bash
    groupadd -g 3000 devs
    groupadd -g 3001 ops
    useradd -m -s /bin/bash -u 2001 -G devs amor
    useradd -m -s /bin/bash -u 2002 -G devs,ops ibtisam
    id amor; id ibtisam
    ```

### 2. Add a Group Without Losing the Others

Add `amor` to `ops`. Afterwards `amor` must still be in `devs`.

??? tip "Solution"
    ```bash
    usermod -aG ops amor
    id amor
    ```

    Running `usermod -G ops amor` instead removes `devs`; repeat it once to see the effect, then repair it.

### 3. Create a Service Account

Create `app` as a system account that cannot log in, with home `/srv/app` owned by `app`.

??? tip "Solution"
    ```bash
    useradd -r -s /usr/sbin/nologin -d /srv/app -m app
    ls -ld /srv/app
    su - app          # expect: This account is currently not available.
    sudo -u app id
    ```

### 4. Delegate Membership

Make `ibtisam` an administrator of `devs`, then as `ibtisam` add `app` to `devs`.

??? tip "Solution"
    ```bash
    gpasswd -A ibtisam devs
    su - ibtisam -c 'gpasswd -a app devs'
    grep devs /etc/gshadow
    ```

---

## Passwords and Aging

### 5. Apply a Password Policy

Set passwords for both users. Require a change every 60 days, allow a change at most once a day, warn 10 days ahead, and force `amor` to choose a new password at the next login.

??? tip "Solution"
    ```bash
    echo 'amor:Lab-Passw0rd' | chpasswd
    echo 'ibtisam:Lab-Passw0rd' | chpasswd
    chage -M 60 -m 1 -W 10 amor
    chage -M 60 -m 1 -W 10 ibtisam
    chage -d 0 amor
    chage -l amor
    ```

### 6. Contractor Account

Create `contractor` with an account expiry at the end of this year, then verify the date.

??? tip "Solution"
    ```bash
    useradd -m -s /bin/bash -e 2026-12-31 contractor
    chage -l contractor | grep 'Account expires'
    ```

---

## Sudo

### 7. Delegate One Command

Allow `ibtisam` to run `systemctl restart sshd` as root without a password, and nothing else. Validate the rule before installing it.

??? tip "Solution"
    ```bash
    echo 'ibtisam ALL=(root) NOPASSWD: /usr/bin/systemctl restart sshd' > /tmp/ibtisam
    visudo -cf /tmp/ibtisam
    install -m 0440 -o root -g root /tmp/ibtisam /etc/sudoers.d/ibtisam
    sudo -l -U ibtisam
    su - ibtisam -c 'sudo -n /usr/bin/systemctl restart sshd && echo allowed'
    su - ibtisam -c 'sudo -n /usr/bin/systemctl status sshd'   # expect: a password is required
    ```

### 8. Make an Admin

Give `amor` full sudo rights through the admin group of the distribution.

??? tip "Solution"
    === "RHEL / Rocky"

        ```bash
        usermod -aG wheel amor
        ```

    === "Ubuntu / Debian"

        ```bash
        usermod -aG sudo amor
        ```

    Verify with `sudo -l -U amor`. An open session of `amor` needs a new login before the group applies.

---

## Break and Fix

### 9. Lock Out and Recover

Enable account lockout, fail the password for `ibtisam` three times, confirm the correct password is rejected, then recover the account.

??? tip "Solution"
    ```bash
    authselect enable-feature with-faillock
    for i in 1 2 3; do su - laborant -c 'echo wrong | su - ibtisam -c true'; done
    faillock --user ibtisam
    su - laborant -c 'echo Lab-Passw0rd | su - ibtisam -c id'   # still fails
    faillock --user ibtisam --reset
    ```

### 10. Delete and Clean Up

Delete `contractor` but keep a copy of the home directory in `/root`. Then find any file on the system that no longer has an owner.

??? tip "Solution"
    ```bash
    tar -czf /root/contractor-home.tgz /home/contractor
    userdel -r contractor
    find / -xdev -nouser 2>/dev/null
    ```

---

## Verification

```bash
id amor ibtisam app
getent group devs ops
chage -l amor | head -2
sudo -l -U ibtisam
visudo -c
```

Permission tasks (ACLs, SGID collaboration directories, special bits) are added to this lab with the Permissions module.

---

## Related

- [Users and Access module](../04-users-and-access/README.md): topics behind every task
- [Cannot Log In or Use Sudo](../interview/scenarios/cannot-login-or-sudo.md): the same failures as an interview drill
