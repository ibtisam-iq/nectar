# Distributions

A distribution packages the Linux kernel with a userland, a package manager, defaults and a support lifecycle. Server work mostly happens on two families, Red Hat and Debian, so commands on this site are shown for both.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Red Hat family | RHEL, Rocky, AlmaLinux, CentOS Stream, Fedora, Amazon Linux | `grep ID_LIKE /etc/os-release` |
| Debian family | Debian, Ubuntu, Linux Mint | `grep ID_LIKE /etc/os-release` |
| Package formats | `.rpm` with `dnf`; `.deb` with `apt` | `rpm --version`, `dpkg --version` |
| CentOS Stream | Upstream of RHEL since 2021, not a rebuild | `cat /etc/redhat-release` |
| RHEL rebuilds | Rocky Linux and AlmaLinux | `grep ^ID= /etc/os-release` |
| Ubuntu LTS | Every two years in April (`YY.04`), 5 years standard support | `lsb_release -a` |
| RHEL support | 10 years per major release | `grep SUPPORT_END /etc/os-release` |
| Container minimal images | Alpine (musl, BusyBox), distroless, UBI | `cat /etc/os-release` in the image |
| Architecture names | `x86_64` = `amd64`; `aarch64` = `arm64` | `uname -m`, `dpkg --print-architecture` |
<!-- --8<-- [end:facts] -->

---

## Families

| Family | Distributions | Package tools | Typical use |
|---|---|---|---|
| Red Hat | RHEL, Rocky, AlmaLinux, CentOS Stream, Fedora, Amazon Linux | `rpm`, `dnf` | Enterprise servers, RHCSA |
| Debian | Debian, Ubuntu, Mint | `dpkg`, `apt` | Cloud images, CI runners, desktops |
| SUSE | SLES, openSUSE | `rpm`, `zypper` | SAP and European enterprises |
| Arch | Arch Linux, Manjaro | `pacman` | Rolling desktops |
| Independent | Alpine | `apk` | Small container images |

The full list of active distributions is tracked at the [LWN distributions list](https://lwn.net/Distributions/).

---

## Release Models

| Model | Meaning | Example |
|---|---|---|
| Fixed release, long support | Versions frozen; fixes backported for years | RHEL, Rocky, Ubuntu LTS, Debian stable |
| Upstream preview | Continuous stream ahead of the next fixed release | CentOS Stream, Fedora |
| Rolling | No major versions; packages update continuously | Arch, openSUSE Tumbleweed |

!!! warning "CentOS Linux 7 and 8 are end of life"
    CentOS Linux 8 ended in December 2021 and CentOS 7 in June 2024. Servers still running them receive no fixes; Rocky Linux and AlmaLinux are the usual migration targets.

---

## Identifying a Distribution in Scripts

=== "RHEL / Rocky"

    ```bash
    grep -E '^(SUPPORT_END|ROCKY_SUPPORT_PRODUCT)=' /etc/os-release
    rpm --eval '%{rhel} %{_arch}'
    ```

    Output:

    ```text
    SUPPORT_END="2035-05-31"
    ROCKY_SUPPORT_PRODUCT="Rocky-Linux-10"
    10 x86_64
    ```

=== "Ubuntu / Debian"

    ```bash
    dpkg --print-architecture
    uname -m
    ```

    Output:

    ```text
    amd64
    x86_64
    ```

    !!! warning "Debian says amd64 where the kernel says x86_64"
        Debian packages name the architecture `amd64`; the kernel calls it `x86_64`. Download URLs for tools such as `kubectl` use one or the other, and mixing them is a common cause of `404` in install scripts.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between RHEL, CentOS Stream and Rocky Linux?"
    **Say first:** CentOS Stream is the development stream that the next RHEL minor release is cut from; RHEL is the supported product; Rocky and AlmaLinux rebuild RHEL for free.

    **Proof:** `cat /etc/redhat-release` on each.

    **Follow-up:** What changed for CentOS users in 2021?

??? question "L1: Why choose an LTS or enterprise release for servers?"
    **Say first:** fixed package versions with backported security fixes keep behavior stable for years, which matters more on servers than new features.

    **Proof:** `grep SUPPORT_END /etc/os-release` shows the end of support.

    **Follow-up:** What is the cost of that stability? (Older language runtimes and tools.)

??? question "L1: Why are many container images based on Alpine?"
    **Say first:** Alpine is a few megabytes because it uses musl and BusyBox, which shrinks pull time and attack surface.

    **Proof:** `docker images alpine` versus `ubuntu`.

    **Follow-up:** What breaks when moving a glibc-built binary into Alpine?
<!-- --8<-- [end:l1] -->

??? question "L2: A script must download the right binary for the machine. Which architecture name does it use?"
    **Say first:** read it from the system and map it to the vendor's naming.

    **Proof:**

    ```bash
    case "$(uname -m)" in x86_64) arch=amd64 ;; aarch64) arch=arm64 ;; esac
    echo "$arch"
    ```

    **Follow-up:** Where does Debian report the same value directly? (`dpkg --print-architecture`.)

??? question "L2: How do you find when a server's distribution stops receiving updates?"
    **Say first:** read `SUPPORT_END` or the vendor lifecycle page.

    **Proof:** `grep SUPPORT_END /etc/os-release`; `hostnamectl` prints "OS Support End" when the file sets that field.

    **Follow-up:** What is the plan for a host that is past that date?

??? question "L3: An install script works on Ubuntu but fails on Amazon Linux 2."
    **Say first:** check the family and package manager before the script's logic.

    **Proof:** `grep -E '^(ID|ID_LIKE)=' /etc/os-release` shows `ID_LIKE="centos rhel fedora"`, so `apt` calls fail.

    **Follow-up:** How should the script detect the family?

---

## Related

- [Kernel vs OS vs Distro](kernel-vs-os-vs-distro.md): what a distribution adds
- [System Information](system-information.md): reading `/etc/os-release`
- [Linux vs Windows](linux-vs-windows.md): why servers run Linux

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
