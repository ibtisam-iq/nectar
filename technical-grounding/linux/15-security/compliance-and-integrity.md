# Compliance and Integrity

Integrity checks compare files with a known-good record (the package database or an AIDE baseline), and compliance scanners compare settings with a benchmark such as CIS. Both answer an auditor's question with evidence, and both help after an incident to find what changed.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Package verify | `rpm -Va` and `dpkg --verify`: `S` size, `5` digest, `M` mode, `U` user, `T` mtime, `P` capabilities; `c` marks config files; `debsums -s` on Debian | `sudo rpm -Va` |
| AIDE | `aide --init` builds a baseline, `aide --check` compares (nonzero exit on differences), `aide --update` accepts changes; keep the database off the host; `rkhunter` and `chkrootkit` are signature-based and prove little when clean | `sudo aide --check` |
| OpenSCAP | `oscap xccdf eval --profile ID --report FILE DATASTREAM` with content from `scap-security-guide` | `oscap info --profiles FILE` |
| Backporting | RHEL and Ubuntu fix CVEs in the shipped version, so the upstream version says nothing; `dnf updateinfo list --security`, Ubuntu `unattended-upgrades` | `rpm -q --changelog PKG` |
<!-- --8<-- [end:facts] -->

---

## Package Verification

`rpm -Va` on `web` (Rocky Linux 10.2) lists every file that differs from the package database:

```bash
sudo rpm -Va | head -6
```

Output:

```text
.M.......  c /etc/hosts
.M.......    /
.M.......    /boot
S.5....T.  c /etc/dnf/dnf.conf
........P    /usr/bin/arping
........P    /usr/bin/clockdiff
```

Changed config files (`c`) are expected on a configured server; `/etc/dnf/dnf.conf` and, further down the list, `sshd_config` differ because the playground image changed them. A changed binary (a `5` flag and no `c`) is a finding. On `client` (Ubuntu), `sudo dpkg --verify` listed only three removed `update-motd.d` files, and `sudo debsums -s` printed nothing.

Package verification also shows that backported fixes keep old version numbers: `openssh-server-9.9p1-25.el10_2.rocky.0.1` lists fixes such as `CVE-2026-60002` in `rpm -q --changelog openssh-server`, and `sudo dnf -q updateinfo summary` reported 8 open security notices (1 Important). A scanner that compares only upstream versions reports such fixed CVEs as open.

!!! warning "Package verification trusts the package database"
    An attacker with root can change the RPM or dpkg database as well as the file. Verify against packages from the repository (`rpm -Kv`, a rebuilt host) when the host itself is suspected.

---

## AIDE

The baseline took 12 seconds on `web`. After it, a sudoers file changed and a small executable script was saved as `/usr/sbin/sshd-helper` (not shown):

```bash
sudo aide --init
sudo cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
echo '# reviewed 2026-09' | sudo tee -a /etc/sudoers.d/deploy-nginx >/dev/null
sudo aide --check | head -40; echo "exit=${PIPESTATUS[0]}"
```

Output:

```text
# ... (trimmed: aide --init output)
Start timestamp: 2026-09-17 16:47:19 +0000 (AIDE 0.19.2)
AIDE found differences between database and filesystem!!

Summary:
  Total number of entries:	30683
  Added entries:		1
  Removed entries:		0
  Changed entries:		1
# ... (trimmed)
f+++++++++++++++++: /usr/sbin/sshd-helper
# ... (trimmed)
f > ...   ..H.... : /etc/sudoers.d/deploy-nginx
# ... (trimmed)
File: /etc/sudoers.d/deploy-nginx
 Size      : 60                               | 79
# ... (trimmed: hash lines)
exit=5
```

---

## OpenSCAP and CIS Profiles

`scap-security-guide` ships benchmark content for each distribution, with CIS, ANSSI, HIPAA and other profiles. `oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-rl10-ds.xml` listed, among others, `xccdf_org.ssgproject.content_profile_cis_server_l1:CIS Red Hat Enterprise Linux 10 Benchmark for Level 1 - Server`.

`sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_server_l1 --rule ... --report /tmp/cis-report.html ...` wrote a 277 KB HTML report, but every selected rule (SSH root login, `MaxAuthTries`, AIDE, firewalld, SELinux) returned `notapplicable`. The same happened on the Fedora 44 playground with `ssg-fedora-ds.xml`: the platform checks did not accept these microVM images, so no pass or fail result was captured.

!!! note "Read notapplicable before reading pass"
    A scan where rules do not apply exits 0 and looks clean. On a standard RHEL VM the same command prints `pass` or `fail` per rule, and `--remediate` or the generated Ansible playbook applies fixes.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: A scanner says OpenSSH 9.9p1 on RHEL is vulnerable to a new CVE. Is it?"
    **Say first:** not necessarily; RHEL backports fixes, so check the package changelog or errata, not the upstream version.

    **Proof:** `rpm -q --changelog openssh-server | grep CVE-...`; `dnf updateinfo list --security`.

    **Follow-up:** Where does Ubuntu publish the same information?
<!-- --8<-- [end:l1] -->

??? question "L2: Check whether any packaged files were modified on a server."
    **Say first:** verify all packages against the package database.

    **Proof:** `sudo rpm -Va`, `sudo dpkg --verify`, `sudo debsums -s`; binaries with `5` in the flags are the concern.

    **Follow-up:** Why is this weak evidence on a host where root is compromised?

??? question "L2: Detect changes to /etc and system binaries every day."
    **Say first:** an AIDE baseline and a daily `aide --check`, with the database stored where the host cannot change it.

    **Proof:** `aide --check` listed the added `/usr/sbin/sshd-helper` and the changed sudoers file, exit status 5.

    **Follow-up:** How do you handle legitimate changes?

??? question "L2: Produce a CIS compliance report for a RHEL server."
    **Say first:** run `oscap` with the CIS profile from `scap-security-guide` and save the HTML report.

    **Proof:** `sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_server_l1 --report cis.html /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml`

    **Follow-up:** What does a `notapplicable` result mean for the report?

??? question "L2: Delete a file with secrets so it cannot be recovered."
    **Say first:** `shred -u` overwrites before removing, but SSDs and copy-on-write filesystems can keep old blocks.

    **Proof:** `shred -u secrets.env`; for real protection, encrypt the disk (LUKS) and destroy the key.

    **Follow-up:** Why does this not help for a secret already committed to Git?

??? question "L3: After an incident, how do you find which system files an attacker changed?"
    **Say first:** compare against records the attacker could not alter: an off-host AIDE database, packages from the repository, and backups.

    **Proof:** `aide --check` with the external database; `rpm -Va` on a trusted boot medium; file times with `find -newer`.

    **Follow-up:** Why is rebuilding the host usually better than cleaning it?

---

## Related

- [Hardening Checklist](hardening-checklist.md) and [Suspected Compromise](../interview/scenarios/suspected-compromise.md): prevention and investigation

Captured on Rocky Linux 10.2 (AIDE 0.19.2, openscap-scanner 1.4.4, scap-security-guide 0.1.82), Fedora 44 (where noted) and Ubuntu 24.04.4 on iximiuz Labs microVMs, kernel 6.1.167, 2026-09.
