# Packaging Concepts

A package is an archive of files plus metadata: name, version, architecture, dependencies, scripts and a signature. Package managers use that metadata to install software consistently, resolve what else is needed, and prove that the files came from the vendor.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| RPM file name | `name-version-release.arch.rpm` (NEVRA with an optional epoch) | `rpm -qp --qf '%{NEVRA}' f.rpm` |
| DEB file name | `name_version-revision_arch.deb` | `dpkg -I f.deb` |
| Epoch | Integer that overrides version comparison (`2:1.26.3`) | `rpm -q --qf '%{EPOCH}'` |
| Release or revision | Packaging build number; `el10_2` and `ubuntu13.18` mark the distribution | `rpm -q bash` |
| Architectures | `x86_64`/`amd64`, `aarch64`/`arm64`, `noarch`/`all` | `uname -m` |
| Low-level vs high-level | `rpm`, `dpkg` handle files; `dnf`, `apt` add repositories and dependency resolution | `dnf history` |
| Dependencies | Declared as package names, files or library sonames (`libc.so.6()(64bit)`) | `rpm -q --requires` |
| Scriptlets | Pre and post install and remove scripts run as root | `rpm -q --scripts` |
| Signatures | Packages or repository metadata are signed with GPG keys; managers refuse unsigned or unknown-key content | `rpm -K f.rpm` |
| Trusted keys | RPM: `gpg-pubkey` pseudo-packages; APT: keyring files referenced by `Signed-By` | `rpm -q gpg-pubkey` |
| Configuration files | Tracked specially; upgrades keep local changes (`.rpmnew`, dpkg prompt) | `rpm -qc`, `dpkg -s` |
| Source packages | `.src.rpm` and `.dsc` build binary packages | `rpm -qi` (Source RPM) |
<!-- --8<-- [end:facts] -->

---

## Package Names and Versions

=== "RHEL / Rocky"

    ```bash
    dnf -q repoquery --qf '%{name} | %{epoch} | %{version} | %{release} | %{arch}\n' --latest-limit 1 nginx bind-utils
    rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n'
    ```

    Output:

    ```text
    bind-utils | 32 | 9.18.33 | 15.el10_2.10 | x86_64

    nginx | 2 | 1.26.3 | 6.el10_2.7 | x86_64

    gpg-pubkey-6fedfc85-682ae1a9	Release Engineering (Rocky Linux 10) <releng@rockylinux.org> public key
    gpg-pubkey-e37ed158-65785fa9	Fedora (epel10) <epel@fedoraproject.org> public key
    ```

    Full names such as `nginx-2:1.26.3-6.el10_2.7.x86_64` show the epoch after the name.

=== "Ubuntu / Debian"

    ```bash
    dpkg-query -W -f='${Package} ${Version}\n' 'openssh*'
    dpkg -I tree_*.deb | grep -E 'Package|Version|Depends'
    ```

    Output:

    ```text
    openssh-client 1:9.6p1-3ubuntu13.18
    openssh-server 1:9.6p1-3ubuntu13.18
    openssh-sftp-server 1:9.6p1-3ubuntu13.18
    openssh-sk-helper 
     Package: tree
     Version: 2.1.1-2ubuntu3.24.04.2
     Depends: libc6 (>= 2.38)
    ```

    The file is named `tree_2.1.1-2ubuntu3.24.04.2_amd64.deb`; in `1:9.6p1-3ubuntu13.18`, `1` is the epoch.

| Part | RPM example | DEB example |
|---|---|---|
| Name | `nginx` | `openssh-server` |
| Epoch | `2` | `1` |
| Upstream version | `1.26.3` | `9.6p1` |
| Release or revision | `6.el10_2.7` | `3ubuntu13.18` |
| Architecture | `x86_64` | `amd64` |

!!! note "Epochs win every comparison"
    A package with epoch `2` is newer than any version with epoch `1` or none, regardless of the version numbers. Vendors add an epoch when upstream renumbering would otherwise make an upgrade look like a downgrade.

---

## Dependencies

Dependencies can name a package, a file or a shared library, which lets the manager pick whichever package provides it:

```bash
rpm -q --requires openssh-server | sort -u | head -6
```

Output:

```text
/bin/sh
/usr/bin/bash
/usr/sbin/useradd
config(openssh-server) = 9.9p1-25.el10_2.rocky.0.1
crypto-policies >= 20220824-1
libaudit.so.1()(64bit)
```

| Relationship | RPM tag | DEB field |
|---|---|---|
| Needs | `Requires` | `Depends`, `Pre-Depends` |
| Offers | `Provides` | `Provides` |
| Cannot coexist | `Conflicts` | `Conflicts`, `Breaks` |
| Replaces an older package | `Obsoletes` | `Replaces` |
| Optional | `Recommends`, `Suggests` | `Recommends`, `Suggests` |

`apt` installs `Recommends` by default (`--no-install-recommends` turns it off); `dnf` installs weak dependencies unless `install_weak_deps=False` is set.

---

## Signatures

A package built without a signature passes a digest check but has no signature, and `dnf` refuses it from a repository with `gpgcheck=1`:

```bash
rpmbuild -bb SPECS/hello-notes.spec
rpm -qpi RPMS/noarch/hello-notes-1.0-1.el10.noarch.rpm | grep -E '^(Name|Version|Release|Signature)'
rpm -K RPMS/noarch/hello-notes-1.0-1.el10.noarch.rpm
rpm -K tree-2.1.0-8.el10.x86_64.rpm
sudo dnf -y --disablerepo='*' --enablerepo=localrepo install hello-notes
```

Output:

```text
# ... (trimmed)
Name        : hello-notes
Version     : 1.0
Release     : 1.el10
Signature   : (none)
RPMS/noarch/hello-notes-1.0-1.el10.noarch.rpm: digests OK
tree-2.1.0-8.el10.x86_64.rpm: digests signatures OK
# ... (trimmed)
Package hello-notes-1.0-1.el10.noarch.rpm is not signed
Error: GPG check FAILED
```

`--nogpgcheck` installs it anyway, which is acceptable only for packages built locally.

!!! danger "Do not disable signature checks to make an install work"
    `gpgcheck=0`, `--nogpgcheck`, `[trusted=yes]` or `--allow-unauthenticated` remove the only proof that a package came from the expected publisher. Import the publisher's key instead, and verify its fingerprint from a second source.

---

## Scriptlets and Configuration Files

Install scripts run as root with no sandbox, so installing a package means trusting its publisher as much as giving it a root shell. `rpm -q --scripts <pkg>` and `dpkg-deb -e <file>.deb` show them before installation.

When a package update ships a new default for a configuration file that was edited locally:

| Situation | RPM | DEB |
|---|---|---|
| Local file unchanged | Replaced | Replaced |
| Local file changed, `%config(noreplace)` | Kept; new default saved as `.rpmnew` | Prompt, or `--force-confold` keeps the local file |
| Local file changed, `%config` | Replaced; old copy saved as `.rpmsave` | |

After upgrades, `find /etc -name '*.rpmnew'` or `find /etc -name '*.dpkg-dist'` lists defaults that need review.

---

## Common Errors

### `Package hello-notes-1.0-1.el10.noarch.rpm is not signed`

**Cause:** the repository enforces `gpgcheck=1` and the package has no signature.

**Fix:** sign it (`rpm --addsign` with a key imported on the clients), or serve internal packages from a repository whose policy is documented.

### `NO_PUBKEY 7EA0A9C3F273FCD8`

**Cause:** APT has no key for a repository's signature, usually because the keyring file named in `Signed-By` is missing.

**Fix:** download the publisher's key into `/etc/apt/keyrings/` and reference it in the source; see [Repositories](repositories.md).

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between rpm or dpkg and dnf or apt?"
    **Say first:** `rpm` and `dpkg` install and query package files; `dnf` and `apt` add repositories, dependency resolution and transaction handling on top.

    **Proof:** `rpm -ivh` on a package with missing dependencies fails; `dnf install ./pkg.rpm` fetches them.

    **Follow-up:** Which database does each pair use?

??? question "L1: Why are packages signed?"
    **Say first:** the signature proves the files came from the publisher and were not altered in a mirror or in transit.

    **Proof:** `rpm -K pkg.rpm` reports `digests signatures OK`; `dnf` refuses an unsigned package with `GPG check FAILED`.

    **Follow-up:** Where does the package manager get the publisher's public key?
<!-- --8<-- [end:l1] -->

??? question "L2: Read the parts of nginx-2:1.26.3-6.el10_2.7.x86_64."
    **Say first:** name, epoch, upstream version, release, architecture.

    **Proof:** `dnf repoquery --qf '%{name} %{epoch} %{version} %{release} %{arch}' nginx`

    **Follow-up:** What does `el10_2` tell you?

??? question "L2: Check what a package will run as root before installing it."
    **Say first:** inspect its scriptlets.

    **Proof:** `rpm -qp --scripts pkg.rpm`, or `dpkg-deb -e pkg.deb /tmp/ctrl && cat /tmp/ctrl/postinst`

    **Follow-up:** Why is installing a random `.deb` from the internet risky even if it looks harmless?

??? question "L2: Find configuration files that an upgrade did not replace."
    **Say first:** search for the saved defaults.

    **Proof:** `sudo find /etc -name '*.rpmnew' -o -name '*.rpmsave'`

    **Follow-up:** How do you review the difference? (`diff -u file file.rpmnew`.)

??? question "L3: After an upgrade, a service still uses old settings, but the package claims a new default."
    **Say first:** the locally modified configuration file was kept and the new default was saved beside it.

    **Proof:** `ls /etc/app/app.conf.rpmnew` exists; `rpm -V app` shows the config as modified.

    **Follow-up:** How do you merge the new default safely?

??? question "L3: A team suggests setting gpgcheck=0 because a vendor repository fails to install."
    **Say first:** find out why verification fails before touching the check.

    **Proof:** the error names a missing or changed key; the vendor rotated its key, and `rpm --import <new-key-url>` after checking the fingerprint fixes it.

    **Follow-up:** What does a key rotation look like on APT?

---

## Related

- [rpm and dnf](rpm-and-dnf.md): RPM queries and transactions
- [dpkg and apt](dpkg-and-apt.md): Debian queries and transactions
- [Repositories](repositories.md): repository files and keys
- [Shared Libraries](shared-libraries.md): library dependencies at runtime

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
