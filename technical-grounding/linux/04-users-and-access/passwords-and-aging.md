# Passwords and Aging

`/etc/shadow` holds each account's password hash and its aging policy, readable only by root. Locking, forced password changes and account expiry are all edits to this one file.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `/etc/shadow` fields | 9: name, hash, last change, min, max, warn, inactive, expire, reserved | `sudo getent shadow <user>` |
| Date fields | Days since 1970-01-01 | `sudo chage -l <user>` |
| Hash prefix `$y$` | yescrypt (default on RHEL 10 and Ubuntu 24.04) | `sudo grep <user> /etc/shadow` |
| Hash prefix `$6$` | SHA-512 crypt | `man 5 crypt` |
| Leading `!` on the hash | Password locked; the hash is kept | `sudo passwd -S <user>` |
| `passwd -S` status | `P` usable, `L` locked, `NP` no password | `sudo passwd -S <user>` |
| Force change at next login | `chage -d 0 <user>` | `sudo chage -l <user>` |
| Account expiry | `chage -E YYYY-MM-DD` (whole account) | `sudo chage -l <user>` |
| Password expiry | `chage -M <days>` (password only) | `sudo chage -l <user>` |
| Defaults for new accounts | `PASS_MAX_DAYS`, `PASS_MIN_DAYS`, `PASS_WARN_AGE` in `/etc/login.defs` | `grep ^PASS_ /etc/login.defs` |
| Portable scripted password | `chpasswd` (`passwd --stdin` is RHEL only) | `sudo chpasswd < <file>` |
<!-- --8<-- [end:facts] -->

---

## The /etc/shadow Record

The hash field below is shortened; the real value carries the algorithm, parameters, salt and hash separated by `$`.

```bash
sudo grep -E '^(root|amor|app):' /etc/shadow
```

Output:

```text
root:$y$j9T$<salt>$<hash>:20694:0:99999:7:::
app:!:20711::::::
amor:$y$j9T$<salt>$<hash>:20711:0:99999:7:::
```

| # | Field | `amor` value | Meaning |
|---|---|---|---|
| 1 | Name | `amor` | Matches `/etc/passwd` |
| 2 | Hash | `$y$...` | `!` or `*` means no password login |
| 3 | Last change | `20711` | 2026-09-15 as days since the epoch; `0` forces a change |
| 4 | Min | `0` | Days before the password may change again |
| 5 | Max | `99999` | Days until the password expires (99999 means never) |
| 6 | Warn | `7` | Warning days before expiry |
| 7 | Inactive | empty | Grace days after expiry before the account locks |
| 8 | Expire | empty | Account expiry date (days since the epoch) |
| 9 | Reserved | empty | Unused |

---

## Hash Algorithms

=== "RHEL / Rocky"

    ```bash
    grep ENCRYPT_METHOD /etc/login.defs
    grep -E '^password.*pam_unix' /etc/pam.d/system-auth
    ```

    Output:

    ```text
    ENCRYPT_METHOD YESCRYPT
    password    sufficient                                   pam_unix.so yescrypt shadow nullok use_authtok
    ```

=== "Ubuntu / Debian"

    ```bash
    grep -E '^ENCRYPT_METHOD' /etc/login.defs
    grep -E '^password.*pam_unix' /etc/pam.d/common-password
    ```

    Output:

    ```text
    ENCRYPT_METHOD SHA512
    password	[success=1 default=ignore]	pam_unix.so obscure yescrypt
    ```

!!! note "Why Ubuntu hashes are yescrypt although login.defs says SHA512"
    `passwd` and `chpasswd` go through PAM, and the `pam_unix.so yescrypt` option wins. `ENCRYPT_METHOD` only affects tools that hash without PAM.

---

## Status and Locking

`passwd -l` and `usermod -L` both prefix the hash with `!`, which makes password authentication fail while keeping the hash so `passwd -u` can restore it.

```bash
sudo passwd -S amor
sudo passwd -l amor
sudo passwd -S amor
sudo grep '^amor:' /etc/shadow | cut -d: -f2 | cut -c1-6
sudo passwd -u amor
sudo passwd -S amor
```

Output:

```text
amor P 2026-09-15 0 99999 7 -1
passwd: password changed.
amor L 2026-09-15 0 99999 7 -1
!$y$j9
passwd: password changed.
amor P 2026-09-15 0 99999 7 -1
```

!!! warning "A locked password does not block SSH keys"
    `!` only breaks password authentication. Key-based SSH still works, so fully disabling an account also needs an expiry (`chage -E 0 <user>`) or a `nologin` shell.

---

## Password Aging

`chage` edits fields 3 to 8. Values in `/etc/login.defs` apply only to accounts created after the change, so existing accounts need `chage`.

```bash
sudo chage -M 90 -m 1 -W 14 -I 7 amor
sudo chage -l amor
```

Output:

```text
Last password change					: Sep 15, 2026
Password expires					: Dec 14, 2026
Password inactive					: Dec 21, 2026
Account expires						: never
Minimum number of days between password change		: 1
Maximum number of days between password change		: 90
Number of days of warning before password expires	: 14
```

| Option | Field | Effect |
|---|---|---|
| `-d 0` | Last change | Forces a password change at the next login |
| `-m <days>` | Min | Stops immediate reuse after a forced change |
| `-M <days>` | Max | Password lifetime |
| `-W <days>` | Warn | Warning period before expiry |
| `-I <days>` | Inactive | Grace period before the account locks |
| `-E <date>` / `-E -1` | Expire | Account expiry / remove expiry |

---

## Forced Change and Account Expiry

```bash
sudo chage -d 0 amor
sudo chage -l amor | head -2
sudo chage -E 2026-09-01 amor
su - amor -c id
sudo chage -E -1 amor
```

Output:

```text
Last password change					: password must be changed
Password expires					: password must be changed
Password: Your account has expired; please contact your system administrator.
su: User account has expired
```

With only `chage -d 0` in place, the next login prompts `You are required to change your password immediately (administrator enforced).` before a shell starts.

---

## Setting Passwords in Scripts

=== "RHEL / Rocky"

    ```bash
    echo 'N3w-Passw0rd' | sudo passwd --stdin amor
    ```

=== "Ubuntu / Debian"

    ```bash
    echo 'x' | sudo passwd --stdin amor
    echo 'amor:N3w-Passw0rd' | sudo chpasswd
    sudo passwd -S amor
    ```

    Output:

    ```text
    passwd: unrecognized option '--stdin'
    # ... (trimmed)
    amor P 2026-09-15 0 99999 7 -1
    ```

`chpasswd` works on both families and reads `user:password` lines, which suits bulk changes.

!!! danger "Passwords on the command line end up in shell history and ps"
    Pipe from a file or a secrets tool, or use `sudo chpasswd < file` with the file removed afterwards.

---

## Common Errors

### `su: User account has expired`

**Cause:** field 8 (`chage -E`) is in the past.

**Fix:** `sudo chage -E -1 <user>` or set a future date.

### `You are required to change your password immediately (administrator enforced).`

**Cause:** field 3 is `0` (`chage -d 0`) or the password passed its maximum age.

**Fix:** expected on first login; the user sets a new password. In automation, set the password with `chpasswd` and a real last-change date.

### `passwd: unrecognized option '--stdin'`

**Cause:** `--stdin` exists only in the RHEL build of shadow-utils; the Debian and Ubuntu build does not carry it.

**Fix:** `echo '<user>:<password>' | sudo chpasswd`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between password expiry and account expiry?"
    **Say first:** password expiry (`-M`) forces a new password but keeps the account usable; account expiry (`-E`) disables the account on that date regardless of the password.

    **Proof:** `chage -l` lists them as separate lines: "Password expires" and "Account expires".

    **Follow-up:** Which one stops a contractor who logs in with an SSH key?

??? question "L1: What does a ! at the start of a shadow hash mean?"
    **Say first:** the password is locked; the original hash follows the `!`, so `passwd -u` restores it.

    **Proof:** `passwd -l amor` then `grep amor /etc/shadow` shows `!$y$...`; `passwd -S` reports `L`.

    **Follow-up:** Does the lock stop every way of logging in?
<!-- --8<-- [end:l1] -->

??? question "L2: Force a user to change their password at the next login."
    **Say first:** set the last-change date to zero.

    **Proof:**

    ```bash
    sudo chage -d 0 amor
    sudo chage -l amor | head -2
    ```

    **Follow-up:** How do you stop them from changing it straight back? (`chage -m 1` plus `pam_pwhistory`.)

??? question "L2: A new policy requires 90-day passwords for everyone. Apply it."
    **Say first:** `login.defs` covers new accounts only, so existing accounts need `chage`.

    **Proof:** edit `PASS_MAX_DAYS 90` in `/etc/login.defs`, then `for u in $(awk -F: '$3>=1000 && $3<60000 {print $1}' /etc/passwd); do sudo chage -M 90 "$u"; done`.

    **Follow-up:** How do you verify the result for every account? (`sudo chage -l <user>` or `passwd -S -a`.)

??? question "L3: An account was locked with passwd -l, but the user still logs in."
    **Say first:** check which authentication method succeeded before touching the password.

    **Proof:** `journalctl -u sshd` (`-u ssh` on Ubuntu) shows `Accepted publickey`; the lock only affects password authentication.

    **Follow-up:** Disable it completely: `sudo chage -E 0 <user>` and remove `~/.ssh/authorized_keys`.

??? question "L4: Why do modern systems use yescrypt instead of a fast hash like SHA-256?"
    **Say first:** password hashes must be slow and memory-hard so offline guessing is expensive; the salt stops precomputed tables.

    **Proof:** the `$y$j9T$` prefix encodes algorithm and cost parameters; the salt follows.

    **Don't say:** "the hash is encrypted and can be decrypted by root."

---

## Related

- [Users](users.md): account creation and the `/etc/passwd` record
- [PAM](pam.md): the stack that hashes, checks and locks passwords
- [Sudo and Su](sudo-and-su.md): how `passwd` edits a root-only file

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
