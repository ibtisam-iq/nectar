# PAM

Pluggable Authentication Modules decide how `login`, `sshd`, `su` and `sudo` authenticate users, check accounts, change passwords and open sessions. Lockouts, password rules and resource limits are PAM modules, not features of each program.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Per-service stacks | `/etc/pam.d/<service>` | `ls /etc/pam.d` |
| Module types | `auth`, `account`, `password`, `session` | `cat /etc/pam.d/su` |
| Control flags | `required`, `requisite`, `sufficient`, `optional`, `include`, `substack` | `man 5 pam.conf` |
| RHEL stack manager | `authselect` (do not edit `system-auth` by hand) | `authselect current` |
| Ubuntu stack manager | `pam-auth-update` (profiles in `/usr/share/pam-configs`) | `ls /usr/share/pam-configs` |
| Failed-login lockout | `pam_faillock`, default `deny=3` | `sudo faillock --user <user>` |
| Password quality | `pam_pwquality`, `/etc/security/pwquality.conf` | `grep pwquality /etc/pam.d/*` |
<!-- --8<-- [end:facts] -->

---

## Reading a Stack

```bash
grep -Ev '^#|^$' /etc/pam.d/su
```

Output:

```text
auth		required	pam_env.so
auth		sufficient	pam_rootok.so
auth		substack	system-auth
auth		include		postlogin
# ... (trimmed: account, password and session lines)
```

!!! note "Root switches users without a password"
    `pam_rootok.so` is `sufficient`, so root switches users without a password; everyone else falls through to `system-auth`.

| Flag | On success | On failure |
|---|---|---|
| `required` | Continue | Fail, but run the rest of the stack |
| `requisite` | Continue | Fail immediately |
| `sufficient` | Succeed immediately (if nothing required failed) | Ignore, continue |
| `optional` | Ignored unless it is the only module | Ignored |

---

## Enabling Account Lockout

On RHEL, authselect inserts `pam_faillock` around `pam_unix`:

```bash
sudo authselect enable-feature with-faillock
grep -E '^auth' /etc/pam.d/system-auth
```

Output:

```text
auth        required                                     pam_env.so
auth        required                                     pam_faildelay.so delay=2000000
auth        required                                     pam_faillock.so preauth silent
auth        sufficient                                   pam_unix.so nullok
auth        required                                     pam_faillock.so authfail
auth        required                                     pam_deny.so
```

!!! warning "Ubuntu 24.04 has no pam-auth-update profile for faillock"
    Ubuntu 24.04 installs `faillock` but ships no `pam-auth-update` profile for it (`/usr/share/pam-configs` holds only `capability`, `mkhomedir`, `systemd` and `unix`), so lockout means editing `/etc/pam.d/common-auth`.

After four wrong passwords for `amor`, the correct password is rejected until the counter is reset:

```bash
sudo faillock --user amor
sudo faillock --user amor --reset
```

Output:

```text
amor:
When                Type  Source                                           Valid
2026-09-15 12:21:31 SVC   su-l                                                 V
2026-09-15 12:21:35 SVC   su-l                                                 V
2026-09-15 12:21:38 SVC   su-l                                                 V
```

The fourth attempt is not recorded because `preauth` rejected it before the password was checked.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are the four PAM module types?"
    **Say first:** `auth` proves identity, `account` checks whether access is allowed now, `password` changes credentials, `session` sets up and tears down the login.

    **Proof:** the first column of any file in `/etc/pam.d/`.

    **Follow-up:** Which type enforces an expired account?
<!-- --8<-- [end:l1] -->

??? question "L2: Lock accounts after three failed logins on RHEL."
    **Say first:** enable the `with-faillock` feature through authselect instead of editing the files.

    **Proof:** `sudo authselect enable-feature with-faillock`, then `sudo faillock --user <user>` after failed attempts.

    **Follow-up:** Where are the thresholds set? (`/etc/security/faillock.conf`.)

??? question "L2: Where do you change the per-user open-file limit that PAM applies at login?"
    **Say first:** `pam_limits` reads `/etc/security/limits.conf` and `/etc/security/limits.d/`.

    **Proof:** `grep pam_limits /etc/pam.d/*` shows which services load it.

    **Follow-up:** Why does a systemd service ignore these limits?

??? question "L3: A user types the correct password and still gets 'Authentication failure'."
    **Say first:** check lockout counters before the password.

    **Proof:** `sudo faillock --user <user>` lists recent failures; the journal shows the PAM module that failed.

    **Follow-up:** How do you find the source of the failed attempts?

??? question "L3: After a manual edit of /etc/pam.d/system-auth, the change disappeared."
    **Say first:** authselect regenerates those files, so manual edits are overwritten.

    **Proof:** `authselect current`; the file header states that it is managed by authselect.

    **Follow-up:** How do you add a custom module the supported way? (A custom authselect profile.)

??? question "L4: What is the difference between required and requisite?"
    **Say first:** both make the stack fail, but `requisite` returns at once while `required` runs the remaining modules, which hides which step failed from an attacker.

    **Proof:** the control flag table in `man 5 pam.conf`.

    **Don't say:** "they are synonyms."

---

## Related

- [Passwords and Aging](passwords-and-aging.md): expiry rules that `account` modules enforce
- [Sudo and Su](sudo-and-su.md): services that call these stacks

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
