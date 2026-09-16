# Package Management

Installing, querying, verifying and removing software on both families, plus repositories, application bundles, shared libraries and software installed outside packages.

---

## Revision Card

| Fact | Value |
|---|---|
| RPM file name | `name-version-release.arch.rpm`; epoch overrides version comparison |
| DEB file name | `name_version-revision_arch.deb` |
| Low level vs high level | `rpm`, `dpkg` vs `dnf`, `apt` |
| RHEL 10 | DNF 4 (`dnf-4.20`) |
| Signatures | `gpgcheck=1`; unsigned packages fail with `GPG check FAILED` |
| APT keys | `/etc/apt/keyrings/`, scoped by `signed-by` |
| `apt remove` vs `purge` | Purge also deletes configuration files |
| Updates available | `dnf check-update` exits 100 |
| Broken repository | `dnf` stops; `apt update` warns and continues |
| Locked dpkg | `apt-get` fails at once; `apt` waits |
| Flatpak scope | System or user; the remote must exist in the same scope |
| Library search | `LD_LIBRARY_PATH`, `RUNPATH`, `ld.so.cache`, default directories |
| New library directory | Needs `ldconfig` |
| Ubuntu 24.04 Python | System `pip install` refused (PEP 668) |

| Task | RHEL / Rocky | Ubuntu / Debian |
|---|---|---|
| Owner of a file | `rpm -qf <path>` | `dpkg -S <path>` |
| Package providing a missing file | `dnf provides '*/<name>'` | `apt-file search <name>` |
| Files and configs | `rpm -ql`, `rpm -qc` | `dpkg -L`, `dpkg -s` |
| Verify files | `sudo rpm -V <pkg>` | `sudo debsums -ce <pkg>` |
| Undo or inspect history | `dnf history undo <id>` | `/var/log/apt/history.log` |
| Pin a version | `dnf versionlock add <pkg>` | `apt-mark hold <pkg>` |
| Enable a repository | `dnf config-manager --set-enabled <id>` | File in `/etc/apt/sources.list.d/` |
| Missing library | `ldd <binary>` | `ldd <binary>` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Packaging Concepts](packaging-concepts.md) | Names and versions, dependencies, signatures, scriptlets, config files | Core | Med |
| [rpm and dnf](rpm-and-dnf.md) | Queries, verification, install and history, security updates, pinning | Core | Med |
| [dpkg and apt](dpkg-and-apt.md) | Queries, verification, remove vs purge, holds, locks | Core | Med |
| [Repositories](repositories.md) | `.repo` and deb822 sources, vendor repositories and keys, local repositories | Core | Low |
| [Flatpak and Snap](flatpak-and-snap.md) | Remotes, scopes, runtimes, snaps and loop devices | RHCSA | Low |
| [Shared Libraries](shared-libraries.md) | Loader search, sonames, `ldconfig`, `RUNPATH`, `LD_PRELOAD`, glibc versions | Advanced | Med |
| [Other Install Methods](other-install-methods.md) | Release binaries, source builds, alternatives, language package managers | Core | Low |

---

## Scenarios and Labs

- [Binary Won't Execute](../interview/scenarios/binary-wont-execute.md): missing libraries, loaders and glibc versions
- [Round 4: Internals](../interview/round-4-internals.md): what happens between `execve` and `main`
