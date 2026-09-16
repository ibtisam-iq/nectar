# dpkg and apt

`dpkg` installs and queries individual `.deb` packages; `apt` resolves dependencies from repositories on Debian and Ubuntu. The split mirrors `rpm` and `dnf`, with Debian-specific details such as configuration purging and package holds.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Installed packages | `dpkg -l` (`ii` = installed) | `dpkg -l bash` |
| Status and dependencies | `dpkg -s <pkg>` | `dpkg -s openssh-server` |
| Files of a package | `dpkg -L <pkg>` | `dpkg -L openssh-server` |
| Owner of a file | `dpkg -S <path>` | `dpkg -S /usr/sbin/sshd` |
| Package for a file not installed | `apt-file search` (package `apt-file`) | `apt-file search -x '/usr/bin/dig$'` |
| Refresh indexes | `apt update`; install and upgrade never refresh by themselves | `apt update` |
| Remove vs purge | `remove` keeps configuration files (`rc`); `purge` deletes them | `dpkg -l <pkg>` |
| Unused dependencies | `apt autoremove` | `apt autoremove --dry-run` |
| Candidate version and origin | `apt-cache policy <pkg>` | `apt-cache policy nginx` |
| Hold a version | `apt-mark hold <pkg>` | `apt-mark showhold` |
| Verify files | `dpkg --verify`, `debsums -c` (`-e` for config files) | `sudo debsums -ce openssh-client` |
| History | `/var/log/apt/history.log`, `/var/log/dpkg.log` | `tail /var/log/apt/history.log` |
| Scripts | Use `apt-get`; `apt` warns that its CLI is not stable and waits on locks | `apt-get -y install` |
<!-- --8<-- [end:facts] -->

---

## Querying the dpkg Database

```bash
dpkg -l bash nosuchpkg
dpkg -l | grep -c '^ii'
dpkg-query -W -f='${Package} ${Version}\n' 'openssh*'
dpkg -s openssh-server | grep -E '^(Package|Status|Version)'
dpkg -s openssh-server | grep -A3 '^Conffiles'
dpkg -S /usr/sbin/sshd /etc/ssh/ssh_config
```

Output:

```text
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version         Architecture Description
+++-==============-===============-============-=================================
ii  bash           5.2.21-2ubuntu4 amd64        GNU Bourne Again SHell
dpkg-query: no packages found matching nosuchpkg
485
openssh-client 1:9.6p1-3ubuntu13.18
openssh-server 1:9.6p1-3ubuntu13.18
openssh-sftp-server 1:9.6p1-3ubuntu13.18
openssh-sk-helper 
Package: openssh-server
Status: install ok installed
Version: 1:9.6p1-3ubuntu13.18
Conffiles:
 /etc/default/ssh 500e3cf069fe9a7b9936108eb9d9c035
 /etc/init.d/ssh 3649a6fe8c18ad1d5245fd91737de507
 /etc/pam.d/sshd 8b4c7a12b031424b2a9946881da59812
openssh-server: /usr/sbin/sshd
openssh-client: /etc/ssh/ssh_config
```

`openssh-sk-helper` has no version: `dpkg-query -W` lists packages the database knows about, including ones that are not installed.

| `dpkg -l` code | Meaning |
|---|---|
| `ii` | Installed |
| `rc` | Removed, configuration files remain |
| `un` | Not installed |
| `hi` | Installed and held |
| `iU`, `iF` | Unpacked or half-configured: an interrupted install |

The version `1:9.6p1-3ubuntu13.18` reads as epoch `1`, upstream version `9.6p1`, Debian revision `3ubuntu13.18`.

---

## Verifying Installed Files

```bash
echo "# local change" | sudo tee -a /etc/ssh/ssh_config >/dev/null
sudo chmod 700 /usr/bin/scp
dpkg --verify openssh-client
sudo debsums -c openssh-client; echo "rc=$?"
sudo debsums -ce openssh-client
```

Output:

```text
??5?????? c /etc/ssh/ssh_config
?????????   /usr/bin/scp
rc=0
/etc/ssh/ssh_config
```

`dpkg --verify` checks only the MD5 digest (`5`); the `?` marks for `scp` mean the unprivileged caller could not read the file, not that it changed. `debsums -c` skips configuration files unless `-e` is given.

---

## Installing, Removing and Purging

```bash
apt-cache policy nginx | head -4
apt show nginx 2>/dev/null | grep -E '^(Package|Version|Section|Origin|Depends)'
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
dpkg -l nginx | tail -1
sudo apt-get remove -y nginx
dpkg -l nginx nginx-common | tail -2
sudo apt-get purge -y nginx-common
sudo apt-get autoremove -y
```

Output:

```text
nginx:
  Installed: (none)
  Candidate: 1.24.0-2ubuntu7.18
  Version table:
Package: nginx
Version: 1.24.0-2ubuntu7.18
Section: web
Origin: Ubuntu
Original-Maintainer: Debian Nginx Maintainers <pkg-nginx-maintainers@alioth-lists.debian.net>
Depends: libc6 (>= 2.34), libcrypt1 (>= 1:4.1.0), libpcre2-8-0 (>= 10.22), libssl3t64 (>= 3.0.0), zlib1g (>= 1:1.1.4), iproute2, nginx-common (= 1.24.0-2ubuntu7.18)
# ... (trimmed)
invoke-rc.d: policy-rc.d denied execution of start.
# ... (trimmed)
ii  nginx          1.24.0-2ubuntu7.18 amd64        small, powerful, scalable web/proxy server
# ... (trimmed)
un  nginx          <none>             <none>       (no description available)
ii  nginx-common   1.24.0-2ubuntu7.18 all          small, powerful, scalable web/proxy server - common files
# ... (trimmed)
0 upgraded, 0 newly installed, 0 to remove and 51 not upgraded.
```

Removing `nginx` left `nginx-common` and its configuration in place. `policy-rc.d` on this playground blocks services from starting during package installation; on a normal Ubuntu server, installing `nginx` starts it immediately.

!!! warning "Debian packages start services on install"
    Ubuntu enables and starts most daemons when they are installed, before any configuration is reviewed. RHEL installs them disabled. Configure or mask a service before installing it on an exposed host.

| Task | Command |
|---|---|
| Install a local `.deb` with dependencies | `sudo apt install ./pkg.deb` |
| Reinstall | `sudo apt install --reinstall <pkg>` |
| Upgrade installed packages | `sudo apt update && sudo apt upgrade` |
| Upgrade, allowing new or removed dependencies | `sudo apt full-upgrade` |
| Simulate | `apt-get -s install <pkg>` |
| Download and inspect a `.deb` | `apt-get download <pkg>`, `dpkg -c`, `dpkg -I` |
| Fix an interrupted install | `sudo dpkg --configure -a`, then `sudo apt -f install` |

---

## Holds, Updates and History

```bash
sudo apt-mark hold bash
apt-mark showhold
sudo apt-mark unhold bash
apt list --upgradable 2>/dev/null | head -4
tail -5 /var/log/apt/history.log
```

Output:

```text
bash set on hold.
bash
Canceled hold on bash.
Listing...
base-files/noble-updates 13ubuntu10.5 amd64 [upgradable from: 13ubuntu10.4]
bind9-dnsutils/noble-updates,noble-security 1:9.18.39-0ubuntu0.24.04.7 amd64 [upgradable from: 1:9.18.39-0ubuntu0.24.04.6]
bind9-host/noble-updates,noble-security 1:9.18.39-0ubuntu0.24.04.7 amd64 [upgradable from: 1:9.18.39-0ubuntu0.24.04.6]
Start-Date: 2026-09-16  14:42:59
Commandline: apt-get purge -y nginx-common
Requested-By: laborant (1001)
Purge: nginx-common:amd64 (1.24.0-2ubuntu7.18)
End-Date: 2026-09-16  14:43:00
```

`apt` has no undo; the history log shows what changed, and a specific version is reinstalled with `apt install <pkg>=<version>`. Unattended security updates come from the `unattended-upgrades` package.

---

## Common Errors

```bash
sudo apt-get install -y nosuchpackage
```

Output:

```text
Reading state information...
E: Unable to locate package nosuchpackage
```

### `E: Unable to locate package nosuchpackage`

**Cause:** the package lists are stale (`apt update` never ran on a fresh image), the name is wrong, or the component (`universe`) or repository is missing.

**Fix:** `sudo apt update`, then `apt-cache search <name>` or `apt-file search`.

While another process holds the dpkg lock (here a Python process standing in for `unattended-upgrades`), `apt-get` fails at once and `apt` waits:

```bash
sudo apt-get install -y sl
sudo apt install -y sl
```

Output:

```text
E: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process 5162 (python3)
E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), is another process using it?
Waiting for cache lock: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process 5162 (python3)...
```

### `E: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process 5162 (python3)`

**Cause:** another package operation is running, often `unattended-upgrades` right after boot.

**Fix:** check the named process and wait; `apt-get -o DPkg::Lock::Timeout=300` waits in scripts. Never delete the lock files while a process holds them.

### `E: dpkg was interrupted, you must manually run 'sudo dpkg --configure -a' to correct the problem.`

**Cause:** a previous install stopped halfway and left entries in `/var/lib/dpkg/updates/`.

**Fix:** `sudo dpkg --configure -a`, then `sudo apt -f install`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between apt remove and apt purge?"
    **Say first:** `remove` deletes the program but keeps its configuration files; `purge` deletes both.

    **Proof:** after `remove`, `dpkg -l` shows `rc` or leaves the `-common` package with its config.

    **Follow-up:** How do you list every package in the `rc` state? (`dpkg -l | grep '^rc'`.)

??? question "L1: Why does apt install say Unable to locate package on a fresh cloud image?"
    **Say first:** the package index is empty or stale until `apt update` runs.

    **Proof:** `sudo apt update && sudo apt install nginx` succeeds.

    **Follow-up:** Why do Dockerfiles combine `apt-get update` and `install` in one `RUN`?
<!-- --8<-- [end:l1] -->

??? question "L2: Find which package provides a command that is not installed."
    **Say first:** search the file index.

    **Proof:** `sudo apt install apt-file && sudo apt-file update && apt-file search -x '/usr/bin/dig$'`

    **Follow-up:** What is the RHEL equivalent?

??? question "L2: Keep Docker at its current version during system upgrades."
    **Say first:** hold the packages.

    **Proof:** `sudo apt-mark hold docker-ce docker-ce-cli containerd.io; apt-mark showhold`

    **Follow-up:** What risk does a long-term hold create?

??? question "L2: Show where a package would be installed from and which versions exist."
    **Say first:** `apt-cache policy` lists candidates with priorities and repositories.

    **Proof:** `apt-cache policy nginx`

    **Follow-up:** How do you install a specific version? (`apt install nginx=<version>`.)

??? question "L3: apt fails with Could not get lock right after a server boots."
    **Say first:** check which process holds the lock before touching anything.

    **Proof:** `sudo lsof /var/lib/dpkg/lock-frontend` or `ps -ef | grep unattended` shows `unattended-upgrades` running.

    **Follow-up:** How do provisioning scripts wait for it safely? (`systemd-run --wait` or loop on `fuser`.)

??? question "L3: After an interrupted upgrade, every apt command fails."
    **Say first:** finish the half-configured packages first.

    **Proof:** `dpkg -l | grep -E '^i[UF]'` lists them; `sudo dpkg --configure -a` then `sudo apt -f install`.

    **Follow-up:** Where do you find what the interrupted upgrade was doing? (`/var/log/apt/term.log`.)

---

## Related

- [rpm and dnf](rpm-and-dnf.md): the RHEL equivalents
- [Packaging Concepts](packaging-concepts.md): versions and signatures
- [Repositories](repositories.md): sources and keyrings

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
