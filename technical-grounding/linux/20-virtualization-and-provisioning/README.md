# Virtualization and Provisioning

Running virtual machines with KVM and libvirt, and provisioning them at scale with images, cloud-init and Kickstart. Low interview weight, but core to LFCS and to how hosts are actually built in a cloud.

---

## Revision Card

| Fact | Value |
|---|---|
| Stack | KVM (kernel) + QEMU (hardware) + libvirt (management) |
| KVM needs | `vmx`/`svm` CPU flag and `/dev/kvm` |
| Host check | `virt-host-validate qemu` |
| Disk formats | qcow2 (thin, snapshots) vs raw (flat, fast) |
| Clone must reset | machine-id and SSH host keys |
| Template cleanup | `virt-sysprep` |
| cloud-init | Configures a cloud image on first boot, once per instance |
| Kickstart | Automates a full RHEL install (Anaconda) |
| Image mode | `bootc`: boot from an OCI image, transactional updates |

| Task | Command |
|---|---|
| Validate KVM support | `virt-host-validate qemu` |
| List VMs | `virsh list --all` |
| Create a VM | `virt-install --name x --memory 2048 --disk size=20 ...` |
| Create a disk | `qemu-img create -f qcow2 vm.qcow2 20G` |
| Inspect a disk | `qemu-img info vm.qcow2` |
| Clean a template | `virt-sysprep -a template.qcow2` |
| Reset machine-id | `truncate -s 0 /etc/machine-id` |
| Regenerate host keys | `rm /etc/ssh/ssh_host_*; ssh-keygen -A` |
| Validate cloud-config | `cloud-init schema --config-file user-data` |
| Re-run cloud-init | `cloud-init clean; reboot` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [KVM and libvirt](kvm-and-libvirt.md) | The KVM/QEMU/libvirt stack, `virsh`, `virt-install`, networking | Advanced | Low |
| [VM Images and Cloning](vm-images-and-cloning.md) | qcow2 vs raw, `qemu-img`, resetting identifiers, `virt-sysprep` | Advanced | Low |
| [Cloud-init and Kickstart](cloud-init-and-kickstart.md) | First-boot config, user-data, Kickstart, image mode | Core | Low |

---

## Scenarios and Labs

- This module feeds the provisioning side of the practice labs, built in a later phase.
