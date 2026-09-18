# Cloud-init and Kickstart

Cloud-init configures a VM on first boot from metadata a cloud supplies, and Kickstart automates a full unattended install. Both turn a generic image into a configured host with no manual steps.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| cloud-init | Configures a cloud image on first boot | `cloud-init status` |
| user-data | The `#cloud-config` YAML: users, packages, commands | `cloud-init schema` |
| First-boot only | Runs once per instance, keyed by instance-id | `/var/lib/cloud/instance` |
| Validate | Check a cloud-config before use | `cloud-init schema --config-file` |
| Re-run | Reset state so next boot is a first boot | `cloud-init clean` |
| Kickstart | Automates a full RHEL install (Anaconda) | `inst.ks=URL` boot arg |
| bootc | Image-mode RHEL: boot from an OCI image, transactional | `bootc status` |
<!-- --8<-- [end:facts] -->

---

## Cloud-init user-data

A `#cloud-config` file declares the users, packages, files and commands to apply on first boot. The cloud passes it as user-data, and cloud-init runs it once, keyed by the instance-id.

```yaml
#cloud-config
users:
  - name: deploy
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-ed25519 AAAA...key deploy@laptop
packages:
  - nginx
runcmd:
  - systemctl enable --now nginx
```

Validating before use catches errors that would otherwise fail quietly on a booting instance.

```bash
sudo cloud-init schema --config-file user-data     # then a malformed file
sudo cloud-init schema --config-file bad.yaml
```

Output:

```text
Valid schema user-data
Error: Invalid schema: user-data
Invalid user-data bad.yaml
```

!!! tip "Validate cloud-config before an instance boots with it"
    A cloud-config error usually fails silently during boot, leaving an instance half-configured. `cloud-init schema --config-file` catches type and key errors up front.

!!! note "cloud-init runs once per instance"
    First-boot modules are keyed by the instance-id under `/var/lib/cloud/`. To re-test on the same VM, `cloud-init clean` resets the state so the next boot is treated as a first boot.

---

## Kickstart and Image Mode

Kickstart automates the RHEL installer (Anaconda) with a `ks.cfg` describing partitioning, packages, users and post-install scripts, read from an `inst.ks=` boot argument for a fully unattended install.

```bash
# ks.cfg is passed to the installer, e.g. inst.ks=http://server/ks.cfg
ksvalidator ks.cfg                 # check syntax before an install
```

Kickstart installs the OS, while cloud-init configures an already-installed cloud image, so they cover different stages. RHEL image mode (`bootc`) is a newer path that boots from an OCI container image and updates transactionally.

---

## Common Errors

### cloud-init did not apply the config on a cloned VM

**Cause:** the instance-id was unchanged, so cloud-init saw the instance as already configured and skipped first-boot modules.

**Fix:** run `cloud-init clean` on the template before cloning, or reset the machine-id and instance state.

### a `runcmd` step silently does nothing

**Cause:** a YAML type or indentation error left the directive malformed, and cloud-init skipped it without a hard failure.

**Fix:** validate with `cloud-init schema --config-file`, and check `/var/log/cloud-init.log`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does cloud-init do, and when does it run?"
    **Say first:** it configures a cloud image on first boot from metadata the platform supplies, running once per instance.

    **Proof:** `cloud-init status`; state under `/var/lib/cloud/instance`.

    **Follow-up:** where does it read the config from? (user-data via a data source such as the cloud API or a NoCloud ISO.)

??? question "L1: What is the difference between Kickstart and cloud-init?"
    **Say first:** Kickstart automates a full OS install with Anaconda; cloud-init configures an already-installed cloud image on first boot.

    **Proof:** Kickstart uses `ks.cfg` and `inst.ks=`; cloud-init uses `#cloud-config` user-data.

    **Follow-up:** which do public cloud images use? (cloud-init.)
<!-- --8<-- [end:l1] -->

??? question "L2: Validate a cloud-config file before booting an instance with it."
    **Say first:** run the schema check.

    **Proof:** `sudo cloud-init schema --config-file user-data`.

    **Follow-up:** where do you look if a valid config still misbehaves? (`/var/log/cloud-init.log`.)

??? question "L3: A cloned VM ignored its cloud-config. Diagnose it."
    **Say first:** cloud-init keys first-boot on the instance-id, so a clone that kept the template's state sees itself as already configured and skips.

    **Proof:** check `/var/lib/cloud/instance`; run `cloud-init clean` on the template before cloning.

    **Follow-up:** what else must be reset on a clone? (machine-id and SSH host keys.)

??? question "L2: What is RHEL image mode, and how does it differ from a Kickstart install?"
    **Say first:** image mode (`bootc`) boots from an OCI container image and updates transactionally, rather than installing and patching packages individually.

    **Proof:** `bootc status` on an image-mode host; the OS is defined by a container image.

    **Follow-up:** what advantage does transactional update give? (atomic upgrade and rollback of the whole OS.)

??? question "L2: Re-test a cloud-config on the same VM."
    **Say first:** reset the state so the next boot is a first boot.

    **Proof:** `sudo cloud-init clean`, then reboot and re-check `cloud-init status`.

    **Follow-up:** why does it not re-run otherwise? (first-boot modules run once per instance-id.)

---

## Related

- [VM Images and Cloning](vm-images-and-cloning.md): the identifiers to reset before cloud-init runs
- [KVM and libvirt](kvm-and-libvirt.md): the platform provisioning targets
- [Users and Access](../04-users-and-access/users.md): the users cloud-config creates
- [SSH Client](../14-ssh-and-remote-access/ssh-client.md): the authorized keys cloud-init installs

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. Kickstart and `bootc` steps run on a full install and are shown without output.
