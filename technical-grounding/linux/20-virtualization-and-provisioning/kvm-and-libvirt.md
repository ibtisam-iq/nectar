# KVM and libvirt

KVM is the Linux kernel's hardware virtualization, QEMU emulates the virtual hardware, and libvirt is the management layer that `virsh` and `virt-install` drive. Together they run virtual machines on a Linux host.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| KVM | Kernel module using CPU virtualization (VT-x, AMD-V) | `lsmod | grep kvm` |
| CPU support | `vmx` (Intel) or `svm` (AMD) flag, and `/dev/kvm` | `grep -E 'vmx|svm' /proc/cpuinfo` |
| QEMU | Emulates the virtual hardware for the guest | `qemu-system-x86_64 --version` |
| libvirt | Management API and daemon over KVM/QEMU | `systemctl status libvirtd` |
| virsh | CLI to libvirt: list, start, define domains | `virsh list --all` |
| Host check | Validates KVM readiness | `virt-host-validate` |
| Default network | NAT network `default`, 192.168.122.0/24 | `virsh net-list` |
| Snapshot | Point-in-time state of a domain | `virsh snapshot-create-as` |
<!-- --8<-- [end:facts] -->

---

## The Stack

KVM turns the kernel into a hypervisor using the CPU's virtualization extensions, QEMU provides the emulated devices, and libvirt manages the domain through a stable API. `virt-host-validate` checks whether the host can run accelerated VMs.

```bash
virsh --version
sudo virt-host-validate qemu | head -2
```

Output:

```text
11.10.0
  QEMU: Checking for hardware virtualization : FAIL (Host not compatible with KVM; HW virtualization CPU features not found. Only emulated CPUs are available; performance will be significantly limited)
```

This capture host is itself a lightweight VM without nested virtualization, so KVM fails and only slow emulation is possible. A bare-metal host with `vmx`/`svm` and `/dev/kvm` passes.

!!! note "No /dev/kvm means emulation only"
    Without hardware virtualization, QEMU emulates the CPU in software, which is far slower. Production VMs need `/dev/kvm`, which requires the CPU flag and, on a VM host, nested virtualization enabled.

---

## Managing Domains

`virsh` lists, starts and defines domains (libvirt's name for a VM), and `virt-install` creates one from an install source. A domain is defined by XML that libvirt stores, editable with `virsh edit`.

```bash
virsh list --all
virt-install --name web --memory 2048 --vcpus 2 \
  --disk size=20 --os-variant rocky10 --cdrom /iso/Rocky-10.iso
virsh snapshot-create-as web pre-change    # save a rollback point
```

The `default` network is NAT on `192.168.122.0/24`; a bridged network instead puts guests on the physical LAN, covered in [Bridges, Bonds and VLANs](../13-networking/bridges-bonds-vlans.md).

!!! tip "Snapshots are a rollback, not a backup"
    `virsh snapshot-revert` returns a VM to a saved state, but long-lived snapshots grow and slow the disk, and they live on the same host. Keep a real backup separately.

---

## Common Errors

### `virt-host-validate` reports hardware virtualization FAIL

**Cause:** the CPU lacks `vmx`/`svm`, or nested virtualization is off, so `/dev/kvm` is unavailable.

**Fix:** enable virtualization in firmware, or nested virtualization on the parent hypervisor; otherwise only slow emulation runs.

### `error: failed to connect to the hypervisor`

**Cause:** `libvirtd` is not running, or the user is not in the `libvirt` group.

**Fix:** start `libvirtd` and add the user to `libvirt`, then reconnect.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are KVM, QEMU and libvirt, and how do they relate?"
    **Say first:** KVM is the kernel's hardware virtualization, QEMU emulates the virtual hardware, and libvirt is the management layer tools like `virsh` use.

    **Proof:** `lsmod | grep kvm`; `qemu-system-x86_64 --version`; `virsh list`.

    **Follow-up:** what does a VM have that a container does not? (its own guest kernel.)

??? question "L1: How do you tell if a host can run accelerated VMs?"
    **Say first:** check for the CPU virtualization flag and `/dev/kvm`, or run `virt-host-validate`.

    **Proof:** `grep -E 'vmx|svm' /proc/cpuinfo`; `ls /dev/kvm`; `virt-host-validate qemu`.

    **Follow-up:** what happens without `/dev/kvm`? (QEMU emulates in software, much slower.)
<!-- --8<-- [end:l1] -->

??? question "L2: Create and start a new VM from an ISO."
    **Say first:** define it with `virt-install`, then manage it with `virsh`.

    **Proof:**

    ```bash
    virt-install --name web --memory 2048 --vcpus 2 --disk size=20 --cdrom /iso/os.iso
    ```

    **Follow-up:** where is the VM's definition stored? (libvirt XML, edited with `virsh edit`.)

??? question "L2: A VM must be reachable on the physical LAN, not behind NAT. What network do you use?"
    **Say first:** a bridged network instead of the default NAT network.

    **Proof:** attach the guest to a host bridge; the default `192.168.122.0/24` is NAT-only.

    **Follow-up:** what does the default libvirt network give? (NAT outbound on 192.168.122.0/24.)

??? question "L3: virsh cannot connect to the hypervisor on a fresh install. How do you diagnose it?"
    **Say first:** check that `libvirtd` is running and the user can reach the socket.

    **Proof:** `systemctl status libvirtd`; add the user to `libvirt`; retry `virsh list`; `virt-host-validate` for KVM support.

    **Follow-up:** what would confirm acceleration is available? (`virt-host-validate qemu` passing.)

??? question "L2: Roll a VM back to a known-good state."
    **Say first:** take a snapshot beforehand and revert to it.

    **Proof:** `virsh snapshot-create-as web pre-change`; `virsh snapshot-revert web pre-change`.

    **Follow-up:** why are snapshots not a backup? (they grow, slow the disk, and live on the same host.)

---

## Related

- [Containers vs VMs](../19-containers/containers-vs-vms.md): the container side of the comparison
- [VM Images and Cloning](vm-images-and-cloning.md): disk formats and templating VMs
- [Cloud-init and Kickstart](cloud-init-and-kickstart.md): automating guest install and first boot
- [Bridges, Bonds and VLANs](../13-networking/bridges-bonds-vlans.md): bridged VM networking

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The host has no `/dev/kvm`, so `virsh` and `virt-install` domain commands are shown without output; they run on a host with hardware virtualization.
