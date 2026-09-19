# Other Install Methods

Plenty of DevOps software arrives outside the distribution: single binaries from GitHub releases, source tarballs, language package managers. Each method needs a deliberate location, a verification step and a way to remove it later, because the system package manager does not track it.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Release binaries | Single files in `/usr/local/bin` (`install -m 0755` after a checksum check); bundles in `/opt/<app>` | `command -v kubectl` |
| Source builds | `./configure && make && sudo make install`, default prefix `/usr/local` | `./configure --help` |
| Untracked files | Nothing in `/usr/local` belongs to a package | `dpkg -S`, `rpm -qf` |
| Alternatives | One command name, several implementations: `update-alternatives` (Debian), `alternatives` (RHEL); `--display`, `--config`, `--set` | `update-alternatives --query editor` |
| Python on Ubuntu 24.04 | System `pip install` refused (PEP 668, `EXTERNALLY-MANAGED`); use a venv or `pipx` | `ls /usr/lib/python3*/EXTERNALLY-MANAGED` |
| Python on Rocky 10.2 | No `EXTERNALLY-MANAGED` marker; `pip install --user` works, root `pip` warns | `pip3 --version` |
| Unpack an RPM without installing | `rpm2cpio` output piped into `cpio -idm`; `dpkg-deb -x` for a `.deb` | `find . -type f` |
<!-- --8<-- [end:facts] -->

---

## Release Binaries

```bash
curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/v1.34.1/bin/linux/amd64/kubectl"
curl -fsSLo /tmp/kubectl.sha256 "https://dl.k8s.io/release/v1.34.1/bin/linux/amd64/kubectl.sha256"
echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
kubectl version --client | head -1
command -v kubectl
```

Output:

```text
/tmp/kubectl: OK
Client Version: v1.34.1
/usr/local/bin/kubectl
```

---

## Building from Source

```bash
curl -fsSLO https://ftp.gnu.org/gnu/hello/hello-2.12.1.tar.gz
tar -xf hello-2.12.1.tar.gz && cd hello-2.12.1
./configure && make -j4 && sudo make install
command -v hello; hello
dpkg -S /usr/local/bin/hello
```

Output:

```text
# ... (trimmed)
/usr/local/bin/hello
Hello, world!
dpkg-query: no path found matching pattern /usr/local/bin/hello
```

!!! warning "Never install from source with the /usr prefix"
    No package owns the result, so updates and removal are manual, and `sudo make uninstall` works only while the configured source tree is kept. Never use `--prefix=/usr`, which overwrites files the package manager owns.

---

## Language Package Managers

On Ubuntu 24.04:

```bash
pip install requests
python3 -m venv /tmp/venv && /tmp/venv/bin/pip install -q requests && /tmp/venv/bin/python -c 'import requests; print(requests.__version__)'
```

Output:

```text
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
# ... (trimmed)
2.34.2
```

!!! warning "sudo pip install breaks package-managed directories"
    Other language tools follow the same rule: project-local `node_modules` for `npm`, `pipx` for Python command-line tools, and `~/go/bin` or `~/.cargo/bin` for `go install` and `cargo install`. `sudo pip install` mixes files into the directories `dnf` or `apt` manage, and a later package update can break either side.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Where should a manually downloaded binary go, and why?"
    **Say first:** `/usr/local/bin` (or `/opt/<app>` for a bundle), because the package manager never writes there.

    **Proof:** `echo $PATH` lists `/usr/local/bin` before `/usr/bin`; `rpm -qf /usr/local/bin/kubectl` finds no owner.

    **Follow-up:** How do you keep track of what was installed that way?
<!-- --8<-- [end:l1] -->

??? question "L2: Install a release binary safely."
    **Say first:** download, verify the checksum, install with explicit mode and owner.

    **Proof:** `sha256sum --check`, then `sudo install -o root -g root -m 0755 tool /usr/local/bin/tool`

    **Follow-up:** What does a checksum from the same site not protect against?

??? question "L2: Look inside an RPM without installing it."
    **Say first:** convert it to a cpio archive and unpack it in a scratch directory.

    **Proof:** `rpm2cpio tree-2.1.0-8.el10.x86_64.rpm | cpio -idm` creates `./usr/bin/tree`.

    **Follow-up:** What is the Debian equivalent? (`dpkg-deb -x`.)

??? question "L2: Switch the system default editor on Ubuntu without a prompt."
    **Say first:** set the alternative directly.

    **Proof:** `sudo update-alternatives --set editor /usr/bin/vim.basic`

    **Follow-up:** Which RHEL command does the same? (`alternatives --set`.)

??? question "L3: pip install fails with externally-managed-environment on a new Ubuntu server."
    **Say first:** Ubuntu 24.04 protects the system Python (PEP 668); use a virtual environment.

    **Proof:** `/usr/lib/python3.12/EXTERNALLY-MANAGED` exists; `python3 -m venv .venv && .venv/bin/pip install ...` works.

    **Follow-up:** Why is `--break-system-packages` the wrong fix?

??? question "L3: After a source build, the old version of a tool still runs."
    **Say first:** check which path the shell resolves and whether it cached the old one.

    **Proof:** `type -a tool` shows both `/usr/local/bin/tool` and `/usr/bin/tool`; `hash -r` clears the cached path.

    **Follow-up:** Which should be removed, and how?

---

## Related

- [Command Resolution](../01-shell-and-cli/command-resolution.md): `PATH` order and the hash table
- [File Operations](../02-files-and-filesystem/file-operations.md): `install` and `curl -f`

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
