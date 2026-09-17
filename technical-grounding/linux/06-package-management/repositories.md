# Repositories

A repository is a web or file location with packages and signed metadata. Adding one means adding its source definition and trusting its signing key, and a broken repository behaves differently on each family.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| RHEL definitions | `/etc/yum.repos.d/*.repo` (`baseurl` or `mirrorlist`, `gpgcheck`, `gpgkey`); a local repository is a `createrepo_c` directory with `baseurl=file:///<dir>` | `dnf repolist --all` |
| Ubuntu definitions | `/etc/apt/sources.list.d/*.sources` (deb822: `Types`, `URIs`, `Suites`, `Components`, `Signed-By`; default on 24.04) or `*.list` | `cat /etc/apt/sources.list.d/ubuntu.sources` |
| Keys | RPM imports into its database; APT uses keyring files in `/etc/apt/keyrings/` via `Signed-By` | `rpm -q gpg-pubkey` |
| Extra RHEL repositories | CRB (build dependencies) and EPEL (community packages), enabled with `dnf config-manager --set-enabled <id>`; Red Hat repositories need `subscription-manager register` (not on Rocky) | `dnf repolist` |
| Unreachable repository | `dnf` stops with `Failed to download metadata`; `apt update` warns and continues | `dnf makecache` |
<!-- --8<-- [end:facts] -->

---

## Repository Definitions

```bash
sed -n '/^\[baseos\]/,/^$/p' /etc/yum.repos.d/rocky.repo
```

Output:

```text
[baseos]
name=Rocky Linux $releasever - BaseOS
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-10
```

---

## Adding a Vendor Repository

=== "RHEL / Rocky"

    ```bash
    sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
    dnf -q repoquery --latest-limit 1 docker-ce
    ```

    Output:

    ```text
    Adding repo from: https://download.docker.com/linux/rhel/docker-ce.repo
    docker-ce-3:29.8.1-1.el10.x86_64
    ```

    !!! note "dnf imports the repository key on first install"
        `dnf` imports the key named by `gpgkey=` on the first install.

=== "Ubuntu / Debian"

    ```bash
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list
    sudo apt-get update
    apt-cache policy docker-ce | head -3
    ```

    Output:

    ```text
    # ... (trimmed)
    docker-ce:
      Installed: (none)
      Candidate: 5:29.8.1-1~ubuntu.24.04~noble
    ```

---

## Common Errors

### `NO_PUBKEY 7EA0A9C3F273FCD8`

**Cause:** the keyring named in `signed-by` is missing or holds another key; APT prints `W: GPG error`, keeps the old index and continues.

**Fix:** download the key again into `/etc/apt/keyrings/`, check its fingerprint, and run `apt update`.

!!! warning "A key in trusted.gpg.d is trusted for every repository"
    Keys kept in `/etc/apt/keyrings/` and named by `signed-by` apply only to their own repository.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How does a package manager know a repository is genuine?"
    **Say first:** the metadata or packages are signed, and the manager checks them against keys the administrator imported.

    **Proof:** `rpm -q gpg-pubkey`; `Signed-By:` in `ubuntu.sources`.

    **Follow-up:** Why is `signed-by` safer than a global trusted keyring?
<!-- --8<-- [end:l1] -->

??? question "L2: Enable EPEL and CRB on Rocky 10."
    **Say first:** install the release package and enable CRB.

    **Proof:** `sudo dnf install epel-release && sudo dnf config-manager --set-enabled crb`

    **Follow-up:** Why do many EPEL packages need CRB?

??? question "L2: Create a local repository from downloaded RPMs for an offline host."
    **Say first:** copy the files, generate metadata, point a `.repo` file at the directory.

    **Proof:** `sudo createrepo_c /srv/localrepo`, then `baseurl=file:///srv/localrepo` with `gpgcheck=1`.

    **Follow-up:** How do you serve it to other hosts? (Any web server, `baseurl=http://...`.)

??? question "L2: Install packages from the RHEL installation ISO without network access."
    **Say first:** mount the ISO and define `BaseOS` and `AppStream` as file repositories.

    **Proof:** `sudo mount -o loop rhel.iso /mnt/iso`; `.repo` entries with `baseurl=file:///mnt/iso/BaseOS` and `.../AppStream`, `gpgkey=file:///mnt/iso/RPM-GPG-KEY-redhat-release`.

    **Follow-up:** How do you make the mount survive a reboot? (An `/etc/fstab` entry.)

??? question "L3: apt update prints warnings for one repository, and an install from it then fails."
    **Say first:** read the warning: a missing key or an unreachable host leaves that repository's index stale or empty.

    **Proof:** `NO_PUBKEY` names the key ID; `apt-cache policy <pkg>` shows no candidate from that source.

    **Follow-up:** Why does the same problem stop every `dnf` command on RHEL?

??? question "L3: Every dnf command fails after a vendor repository was added."
    **Say first:** one unreachable repository stops `dnf` for all of them.

    **Proof:** `Error: Failed to download metadata for repo '<id>'`; `sudo dnf config-manager --set-disabled <id>` restores the others.

    **Follow-up:** Which repository option makes `dnf` skip it instead? (`skip_if_unavailable=True`.)

---

## Related

- [Packaging Concepts](packaging-concepts.md): signatures; [rpm and dnf](rpm-and-dnf.md) and [dpkg and apt](dpkg-and-apt.md): using the repositories

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
