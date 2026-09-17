# Labs

Hands-on tasks for each module, written as exercises with collapsed solutions. Work through a lab on a disposable machine, then check the result with the verification commands before opening the solution.

---

## Environments

| Environment | Use for | Notes |
|---|---|---|
| iximiuz Labs `rockylinux` playground | RHEL-family tasks | Rocky Linux 10.2; no SELinux tooling |
| iximiuz Labs `ubuntu-24-04` playground | Debian-family tasks | Ubuntu 24.04 LTS |
| iximiuz Labs `flexbox` | Multi-host tasks (NFS, routing, firewalls) | Up to five VMs on one or more networks; the Networking lab uses three VMs on two networks |
| Local VM (VirtualBox or UTM) | Boot, GRUB, SELinux, nested virtualization | Full control over the boot process |
| Loop devices on any VM | Partitioning, LVM, RAID, quotas | No extra disks needed |

Start playgrounds from the browser or with `labctl`:

```bash
labctl playground start rockylinux
labctl playground start ubuntu-24-04
```

---

## Local VM Checks

A local VM that fails to start is usually missing hardware virtualization or conflicts with another hypervisor.

| Symptom | Check |
|---|---|
| "VT-x is disabled in the BIOS" | Enable Intel VT-x or AMD-V in the firmware settings |
| Kernel panic or freeze at VM start on Windows | Disable Memory Integrity (Core Isolation) or run `bcdedit /set hypervisorlaunchtype off`, then reboot |
| VM is slow or panics on one vCPU | Assign at least 2 vCPUs |

---

## Lab Index

| Lab | Modules |
|---|---|
| [Users and Permissions](users-and-permissions-lab.md) | 04 Users and Access, 05 Permissions |
| [Processes and Services](processes-and-services-lab.md) | 07 Processes, 08 Systemd and Services |
| [Storage and LVM](storage-and-lvm-lab.md) | 12 Storage |
| [Networking](networking-lab.md) | 13 Networking |
