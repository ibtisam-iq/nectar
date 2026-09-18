# Overlayfs and Chroot

`chroot` changes what a process sees as its root directory, and OverlayFS stacks a read-only base under a writable layer. Together they explain container images: a read-only stack of layers with a thin writable layer on top, presented as one root filesystem.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| chroot | Changes `/` for a process and its children | `chroot <dir> <cmd>` |
| chroot limit | Not a security boundary on its own; root can escape | `man 2 chroot` |
| pivot_root | The real container root switch; replaces the mount root | `man 8 pivot_root` |
| OverlayFS | Union filesystem: lower (read-only) under upper (writable) | `mount -t overlay` |
| lowerdir | One or more read-only layers (image layers) | mount option |
| upperdir | The single writable layer (container changes) | mount option |
| workdir | Empty scratch dir OverlayFS needs on the upper's filesystem | mount option |
| merged | The combined view processes actually use | the mountpoint |
| Copy-up | Writing a lower file copies it into the upper first | edit a merged file |
| Image layers | Each image layer is a lowerdir; the container adds an upperdir | `podman inspect` |
| Whiteout | A deleted lower file is masked by a whiteout in the upper | `ls -l upperdir` |
<!-- --8<-- [end:facts] -->

---

## chroot Changes the Root

`chroot <dir> <command>` runs the command with `<dir>` as its `/`, so the process sees only what is inside that directory tree. The directory must contain the binary and its libraries, which is why a chroot needs a populated root filesystem.

```bash
# newroot holds a full busybox filesystem exported from an image
chroot newroot /bin/sh -c 'pwd; ls /bin | head -3; cat /etc/os-release || echo none'
```

Output:

```text
pwd is: /
[
[[
acpid
no-host-os-release-here
```

Inside the chroot, `/` is the new root, `/bin` holds the busybox applets, and the host's `/etc/os-release` is not visible. This is the oldest form of filesystem isolation, and it is the idea a container image builds on.

!!! warning "chroot is not a security sandbox"
    A process with root and `CAP_SYS_ADMIN` can escape a plain `chroot`, and it shares the host's process, network and user namespaces. Containers use `pivot_root` inside a mount namespace, plus cgroups and dropped capabilities, for real isolation.

---

## OverlayFS Stacks Layers

OverlayFS presents a `lowerdir` (read-only) and an `upperdir` (writable) as a single `merged` view. Reads come from the upper if present, otherwise the lower; writes always go to the upper. It needs an empty `workdir` on the same filesystem as the upper for atomic operations.

```bash
mkdir -p ov/lower ov/upper ov/work ov/merged
echo "from base image" > ov/lower/app.conf
sudo mount -t overlay overlay \
  -o lowerdir=ov/lower,upperdir=ov/upper,workdir=ov/work ov/merged
ls ov/merged
```

Output:

```text
app.conf
keep.txt
from base image
```

The merged directory shows the lower's files even though `upper` started empty. A container's root filesystem is exactly this: the image's layers as lowerdirs, and a fresh upperdir for the container's own changes.

---

## Copy-Up on Write

Writing to a file that exists only in the lower layer does not change the lower. OverlayFS copies the file up into the upper layer first, then applies the write there, so the read-only base stays intact and can be shared by many containers.

```bash
echo "changed by container" > ov/merged/app.conf
cat ov/lower/app.conf         # the base is untouched
cat ov/upper/app.conf         # the new copy lives in the upper layer
```

Output:

```text
from base image
changed by container
```

The lower still reads `from base image`, while the upper now holds `changed by container`. This copy-up is why the first write to a large file in a container is slower, and why container changes vanish when the writable layer is discarded on removal.

!!! note "The writable layer is per-container and ephemeral"
    Every container gets its own upperdir, so two containers from one image share the lower layers but not their changes. Removing the container deletes the upperdir, which is why data that must survive goes in a volume, not the container filesystem.

---

## Common Errors

### `mount: overlay: special device overlay does not exist` or fails with `EINVAL`

**Cause:** the `workdir` is missing, not empty, or on a different filesystem from the `upperdir`, which OverlayFS requires.

**Fix:** use an empty `workdir` on the same filesystem as `upperdir`, and pass all of `lowerdir`, `upperdir`, `workdir`.

### `chroot: failed to run command '/bin/sh': No such file or directory`

**Cause:** the target root has no shell, or the shell's shared libraries are missing inside the chroot.

**Fix:** populate the root with the binary and its libraries (`ldd` lists them), or export a container image with `podman export`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between chroot and a container's filesystem isolation?"
    **Say first:** `chroot` only changes the root directory a process sees; a container adds a mount namespace, `pivot_root`, an overlay filesystem, cgroups and dropped capabilities.

    **Proof:** `chroot` shares the host's namespaces; a container has its own, shown by `/proc/PID/ns/`.

    **Follow-up:** why is chroot not a security boundary? (a privileged process can escape it.)

??? question "L1: What are the layers in an OverlayFS mount?"
    **Say first:** one or more read-only lowerdirs, a single writable upperdir, a workdir for scratch, and the merged view processes use.

    **Proof:** `mount -t overlay -o lowerdir=...,upperdir=...,workdir=...`; reads prefer the upper, writes go to the upper.

    **Follow-up:** which layer holds a container's changes? (the upperdir.)
<!-- --8<-- [end:l1] -->

??? question "L2: Show that writing to a merged file does not change the base layer."
    **Say first:** the write triggers a copy-up into the upper, leaving the lower untouched.

    **Proof:**

    ```bash
    echo new > merged/f; cat lower/f; cat upper/f
    ```

    **Follow-up:** why is the first write to a large file slow? (the whole file is copied up before the write.)

??? question "L3: A container's data disappeared after it was recreated. Explain why and prevent it."
    **Say first:** container changes live in the ephemeral upperdir, which is deleted with the container, so anything not in a volume is lost.

    **Proof:** the writable layer is per-container; `podman volume` or a bind mount persists data outside it.

    **Follow-up:** where should a database's files go? (a named volume or bind mount, never the container layer.)

??? question "L4: How does an image with shared layers save space across many containers?"
    **Say first:** the image's layers are read-only lowerdirs shared by every container from that image, and each container adds only its own thin upperdir, so the base is stored once.

    **Proof:** copy-up means a container only stores files it changes; unchanged files are read from the shared lower.

    **Don't say:** that each container gets a full copy of the image.

??? question "L2: Delete a file that exists only in the lower layer of an overlay. What happens?"
    **Say first:** the lower file is not removed; the upper layer records a whiteout that masks it in the merged view.

    **Proof:** `ls -l upperdir` shows a character-device whiteout entry for the deleted name.

    **Follow-up:** where did the original file go? (still in the read-only lower, only hidden.)

---

## Related

- [Namespaces](namespaces.md): the mount namespace that carries this filesystem view
- [Containers vs VMs](containers-vs-vms.md): how the overlay root and namespaces form a container
- [Filesystems](../12-storage/filesystems.md): the underlying filesystems overlay sits on
- [Podman and Quadlet](podman-and-quadlet.md): images, layers and volumes in practice

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The chroot root was populated with `podman export`.
