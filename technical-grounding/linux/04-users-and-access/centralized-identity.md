# Centralized Identity

In a fleet, accounts come from a directory (LDAP, FreeIPA, Active Directory) instead of each server's `/etc/passwd`. The Name Service Switch decides where lookups go, and SSSD caches directory users so logins keep working when the directory is briefly unreachable.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Lookup order | `/etc/nsswitch.conf` (`passwd:`, `group:`, `shadow:` lines) | `grep ^passwd: /etc/nsswitch.conf` |
| Query through NSS | `getent passwd <user>`; `getent -s files` limits the source | `getent -s files passwd root` |
| Directory client | SSSD (`sssd` service, `/etc/sssd/sssd.conf`, mode 600) | `systemctl status sssd` |
| Join a domain | `realm join <domain>` (realmd) | `realm list` |
| Kerberos ticket | `kinit <user>`, `klist` | `klist` |
| Create homes on first login | `pam_mkhomedir` (`oddjob-mkhomedir` on RHEL) | `grep mkhomedir /etc/pam.d/*` |
<!-- --8<-- [end:facts] -->

---

## Name Service Switch

Programs call `getpwnam()` and `getgrnam()`; glibc reads `nsswitch.conf` and asks each listed source in order. Adding `sss` to these lines is what makes directory users visible.

=== "RHEL / Rocky"

    ```bash
    grep -E '^(passwd|group|shadow|hosts):' /etc/nsswitch.conf
    ```

    Output:

    ```text
    passwd:     files systemd
    shadow:     files systemd
    group:      files [SUCCESS=merge] systemd
    hosts:      files  dns myhostname
    ```

=== "Ubuntu / Debian"

    ```bash
    grep -E '^(passwd|group|shadow|hosts):' /etc/nsswitch.conf
    ```

    Output:

    ```text
    passwd:         files systemd
    group:          files systemd
    shadow:         files systemd
    hosts:          files dns
    ```

!!! note "The systemd source serves users created at runtime"
    The `systemd` source serves dynamic users that services create at runtime (`DynamicUser=yes`). With SSSD configured, the lines read `passwd: files sss systemd`; `authselect select sssd` writes them on RHEL, and the `libnss-sss` package adds `sss` on Ubuntu.

---

## Joining a Domain

```bash
sudo realm discover example.com
sudo realm join --user=admin example.com
id alice@example.com
getent passwd alice@example.com
```

`realm join` installs and configures SSSD, Kerberos and the PAM and NSS entries in one step. A minimal SSSD configuration for an LDAP directory looks like this:

```ini
[sssd]
services = nss, pam
domains = example.com

[domain/example.com]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldaps://ldap.example.com
ldap_search_base = dc=example,dc=com
cache_credentials = true
```

!!! warning "SSSD refuses to start when sssd.conf is readable by others"
    The file must be owned by root with mode 600. After changes, `sudo sss_cache -E` clears cached entries so new group memberships show up.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does /etc/nsswitch.conf control?"
    **Say first:** the order of sources glibc queries for users, groups, hosts and other databases.

    **Proof:** `grep ^passwd: /etc/nsswitch.conf` shows `files` first on both families.

    **Follow-up:** Why does `getent` return a user that `grep /etc/passwd` does not?
<!-- --8<-- [end:l1] -->

??? question "L2: Confirm that a directory user resolves on a server."
    **Say first:** query through NSS, not the local file.

    **Proof:** `getent passwd alice@example.com` and `id alice@example.com`.

    **Follow-up:** Which command shows the local definition only? (`getent -s files passwd <user>`.)

??? question "L2: Directory users log in, but have no home directory."
    **Say first:** enable home creation at first login.

    **Proof:** `sudo authselect enable-feature with-mkhomedir` (RHEL) or `sudo pam-auth-update --enable mkhomedir` (Ubuntu).

    **Follow-up:** Why is this a PAM `session` module?

??? question "L3: A user was added to an AD group but the Linux server does not show the new group."
    **Say first:** suspect the SSSD cache before the directory.

    **Proof:** `sudo sss_cache -E`, then a new login and `id <user>`.

    **Follow-up:** What is the trade-off of a long cache timeout?

??? question "L3: All directory logins fail, but local accounts work."
    **Say first:** check SSSD and its path to the directory: service, DNS, time, TLS.

    **Proof:** `systemctl status sssd`, `realm list`, `timedatectl` (Kerberos fails with clock skew over five minutes).

    **Follow-up:** Why should at least one local admin account always exist?

??? question "L4: Why does a server keep a local root and admin account when all users come from LDAP?"
    **Say first:** `files` is first in `nsswitch.conf` so local accounts work when the directory, the network or SSSD is down; that is the recovery path.

    **Proof:** `getent -s files passwd root` resolves with no network.

    **Don't say:** "local accounts are a security risk and should be removed."

---

## Related

- [Users](users.md): local accounts and `getent`
- [PAM](pam.md): the stacks SSSD plugs into

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
