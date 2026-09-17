# rpm and dnf

`rpm` manages individual packages and queries the installed database; `dnf` resolves dependencies, talks to repositories and keeps a transaction history. RHEL 10 and Rocky 10 ship DNF 4 (`dnf-4.20`), and most daily work is a handful of queries.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Is it installed | `rpm -q <pkg>` | `rpm -q bash` |
| Package details | `rpm -qi` | `rpm -qi openssh-server` |
| Files, configs, docs | `rpm -ql`, `-qc`, `-qd` | `rpm -qc openssh-server` |
| Which package owns a file | `rpm -qf <path>` | `rpm -qf /usr/bin/ls` |
| Which package would provide a file | `dnf provides '*/<name>'` | `dnf provides /usr/bin/dig` |
| Verify installed files | `rpm -V` (size, mode, digest, owner, mtime flags) | `sudo rpm -V openssh-server` |
| Check a downloaded package | `rpm -K` (signatures), `rpm -qpl` (files) | `rpm -K pkg.rpm` |
| Install, remove, update | `dnf install`, `dnf remove`, `dnf upgrade` | `dnf history` |
| Undo a transaction | `dnf history undo <id>` or `last` | `dnf history list` |
| Updates available | `dnf check-update` exits 100 | `echo $?` |
| Security errata | `dnf updateinfo`, `dnf upgrade --security` | `dnf updateinfo summary` |
| Pin a version | `dnf versionlock add <pkg>` (plugin) or `exclude=` in `dnf.conf` | `dnf versionlock list` |
| Parallel kernels | `installonly_limit=3` keeps three | `grep installonly /etc/dnf/dnf.conf` |
| Scriptlets and other queries | `rpm -q --scripts`, `--whatrequires`; `rpm -qp...` on a package file | `rpm -q --scripts <pkg>` |
| Backported fixes | Changelog lists CVEs fixed in an old upstream version | `rpm -q --changelog <pkg>` |
<!-- --8<-- [end:facts] -->

---

## Querying the rpm Database

```bash
rpm -q bash openssl-libs nosuchpkg
rpm -qa | wc -l
rpm -qi openssh-server | head -6
```

Output:

```text
bash-5.2.26-6.el10.x86_64
openssl-libs-3.5.5-6.el10_2.x86_64
package nosuchpkg is not installed
513
Name        : openssh-server
Version     : 9.9p1
Release     : 25.el10_2.rocky.0.1
Architecture: x86_64
Install Date: Sat Aug 29 17:55:34 2026
Group       : Unspecified
```

```bash
rpm -qc openssh-server
rpm -qf /etc/ssh/sshd_config /usr/bin/ls
rpm -q --requires openssh-server | sort -u | head -6
```

Output:

```text
/etc/pam.d/sshd
/etc/ssh/sshd_config
/etc/ssh/sshd_config.d/40-redhat-crypto-policies.conf
/etc/ssh/sshd_config.d/50-redhat.conf
/etc/sysconfig/sshd
openssh-server-9.9p1-25.el10_2.rocky.0.1.x86_64
coreutils-single-9.5-8.el10_2.x86_64
/bin/sh
/usr/bin/bash
/usr/sbin/useradd
config(openssh-server) = 9.9p1-25.el10_2.rocky.0.1
crypto-policies >= 20220824-1
libaudit.so.1()(64bit)
```

---

## Verifying Installed Files

`rpm -V` compares files with the package database and prints only differences:

```bash
sudo chmod 644 /usr/bin/passwd
sudo rpm -V openssh-server shadow-utils
sudo chmod 4755 /usr/bin/passwd
```

Output:

```text
S.5....T.  c /etc/ssh/sshd_config
.M.......    /usr/bin/passwd
```

The letters mark what differs: `S` size, `M` mode, `5` digest, `U` and `G` owner and group, `T` modification time, and `c` flags a configuration file.

A changed configuration file is normal; a changed binary (`5` without `c`) is a finding. `rpm -Va` checks every package and is a quick integrity check after a suspected compromise, though an attacker with root can also alter the database.

!!! warning "Run rpm -V as root"
    As a normal user, files the user cannot read are reported as `missing ... (Permission denied)`, which looks alarming and means nothing.

---

## Installing and Removing with dnf

```bash
dnf --version | head -1
dnf -q info nginx | grep -E '^(Name|Version|Release|Repository|Summary)'
dnf -q provides /usr/bin/dig | head -3
sudo dnf -y install nginx
rpm -q nginx
```

Output:

```text
4.20.0
Name         : nginx
Version      : 1.26.3
Release      : 6.el10_2.7
Repository   : appstream
Summary      : A high performance web server and reverse proxy server
bind-utils-32:9.18.33-15.el10_2.1.x86_64 : Utilities for querying DNS name servers
Repo        : appstream
Matched from:
# ... (trimmed)
nginx-1.26.3-6.el10_2.7.x86_64
```

Other everyday forms: `dnf install ./pkg.rpm` (local file with dependencies), `dnf reinstall <pkg>` (restores deleted files), `dnf autoremove`, `dnf download <pkg>`, `dnf group list` and `dnf clean all`.

---

## Transaction History

```bash
sudo dnf history list | head -5
sudo dnf -y history undo last
rpm -q nginx
sudo dnf history info last | sed -n '1p;12,20p'
```

Output:

```text
ID     | Command line             | Date and time    | Action(s)      | Altered
-------------------------------------------------------------------------------
    11 | -y install nginx         | 2026-09-16 14:41 | Install        |    4 EE
    10 | install -y jq acl attr e | 2026-09-16 14:20 | I, U           |  181 EE
     9 | install -y cronie tldr   | 2026-09-16 13:33 | Install        |    7 EE
# ... (trimmed)
package nginx is not installed
Transaction ID : 12
Packages Altered:
    Removed logrotate-3.22.0-5.el10.x86_64              @@System
    Removed nginx-2:1.26.3-6.el10_2.7.x86_64            @@System
    Removed nginx-core-2:1.26.3-6.el10_2.7.x86_64       @@System
    Removed nginx-filesystem-2:1.26.3-6.el10_2.7.noarch @@System
```

!!! note "history undo also removes pulled-in dependencies"
    The undo also removed `logrotate`, which transaction 11 had pulled in as a dependency. Noting the history ID before a risky upgrade gives an exact rollback target, as long as the repositories still carry the old versions.

---

## Updates, Security and Pinning

```bash
dnf -q check-update | head -5
echo "rc=${PIPESTATUS[0]}"
dnf -q updateinfo summary
rpm -q --changelog openssl-libs | grep -m3 -E 'CVE-'
grep -E '^(installonly_limit|gpgcheck|exclude)' /etc/dnf/dnf.conf
```

Output:

```text

dbus-broker.x86_64                     36-5.el10_2                     baseos   
expat.x86_64                           2.7.3-1.el10_2.3                baseos   
glib2.x86_64                           2.80.4-12.el10_2.22             baseos   
openssl-fips-provider.x86_64           1:3.5.8-1.el10_2                baseos   
rc=100
Updates Information Summary: available
    4 Security notice(s)
        1 Important Security notice(s)
        3 Moderate Security notice(s)
Fix CVE-2026-7383, CVE-2026-9076, CVE-2026-34180, CVE-2026-34181,
CVE-2026-34183, CVE-2026-42764, CVE-2026-42766, CVE-2026-42767, CVE-2026-42768,
CVE-2026-42769, CVE-2026-42770, CVE-2026-45445, CVE-2026-45446, CVE-2026-45447,
gpgcheck=1
installonly_limit=3
```

`dnf check-update` returns 100 when updates exist, 0 when there are none and 1 on error, which suits monitoring scripts. The changelog shows CVEs fixed in OpenSSL 3.5.5 without changing its upstream version.

---

## Common Errors

```bash
sudo dnf -y install nosuchpackage
```

Output:

```text
Last metadata expiration check: 1:17:54 ago on Wed Sep 16 13:24:01 2026.
No match for argument: nosuchpackage
Error: Unable to find a match: nosuchpackage
```

### `Error: Unable to find a match: nosuchpackage`

**Cause:** no enabled repository has that name: a typo, a package in a disabled repository (EPEL, CRB), or a name that differs from the command (`dig` is in `bind-utils`).

**Fix:** `dnf search`, `dnf provides '*/<command>'`, `dnf repolist --all`.

With a repository file that points to an unreachable host:

```bash
sudo dnf -y install tree 2>&1 | grep -E 'Error|Curl|broken'
```

Output:

```text
Errors during downloading metadata for repository 'broken':
  - Curl error (6): Could not resolve hostname for https://repo.invalid/el10/repodata/repomd.xml [Could not resolve host: repo.invalid]
Error: Failed to download metadata for repo 'broken': Cannot download repomd.xml: Cannot download repodata/repomd.xml: All mirrors were tried
```

### `Error: Failed to download metadata for repo 'broken'`

**Cause:** one enabled repository is unreachable (DNS, proxy, firewall, wrong URL), and `dnf` stops for all repositories.

**Fix:** `curl -I <baseurl>`; fix or disable the repository (`sudo dnf config-manager --set-disabled broken`), or add `skip_if_unavailable=True` to that repository.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between rpm and dnf?"
    **Say first:** `rpm` installs and queries individual package files without resolving dependencies; `dnf` resolves dependencies from repositories and records transactions.

    **Proof:** `rpm -ivh pkg.rpm` fails on missing dependencies; `dnf install ./pkg.rpm` fetches them.

    **Follow-up:** When is `rpm` still the right tool? (Queries and verification.)
<!-- --8<-- [end:l1] -->

??? question "L2: Find which package installed /etc/ssh/sshd_config and list its other config files."
    **Say first:** query by file, then by package.

    **Proof:** `rpm -qf /etc/ssh/sshd_config; rpm -qc openssh-server`

    **Follow-up:** How do you find a package for a command that is not installed?

??? question "L2: Roll back yesterday's package update."
    **Say first:** find the transaction and undo it.

    **Proof:** `sudo dnf history list; sudo dnf history undo <id>`

    **Follow-up:** What can prevent the undo from working?

??? question "L2: Keep the kernel from being updated while other packages update."
    **Say first:** lock or exclude it.

    **Proof:** `sudo dnf versionlock add kernel-core`, or `sudo dnf upgrade --exclude='kernel*'`

    **Follow-up:** Why is a permanent kernel lock a risk?

??? question "L3: A scanner reports a CVE in openssl, but dnf says there is nothing to update."
    **Say first:** check whether the installed build already contains the fix.

    **Proof:** `rpm -q --changelog openssl-libs | grep CVE-<id>` and `dnf updateinfo info --cve CVE-<id>`.

    **Follow-up:** How do you explain the finding to the security team?

??? question "L3: dnf install fails with Unable to find a match for a package the documentation names."
    **Say first:** check repositories and the real package name.

    **Proof:** `dnf provides '*/htpasswd'` shows `httpd-tools`; `dnf repolist --all` shows EPEL or CRB disabled.

    **Follow-up:** How do you enable CRB on Rocky 10? (`dnf config-manager --set-enabled crb`.)

---

## Related

- [Packaging Concepts](packaging-concepts.md): package names, versions and signatures
- [Repositories](repositories.md): `.repo` files, EPEL and local repositories
- [dpkg and apt](dpkg-and-apt.md): the Debian equivalents

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
