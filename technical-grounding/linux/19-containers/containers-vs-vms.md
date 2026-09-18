# Containers vs VMs

A container is a process on the host kernel, isolated with namespaces and limited with cgroups; a virtual machine is a full guest kernel and OS running on emulated hardware. The difference decides startup time, density, isolation strength, and how you debug them.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Container | A host process with its own namespaces and cgroups | `ps` on the host finds it |
| VM | A guest kernel on virtual hardware, via a hypervisor | `virsh list` |
| Kernel | Containers share the host kernel; VMs run their own | `uname -r` inside each |
| Isolation | Namespaces plus cgroups vs hardware virtualization | `/proc/PID/ns/` |
| Startup | Container in milliseconds; VM boots a kernel | `time podman run` |
| Density | Many containers per host; fewer VMs | memory per instance |
| Boundary strength | A VM's boundary is stronger (own kernel) | threat model |
| Image | Container image is layered files; VM image is a full disk | `podman inspect` |
| Container PID 1 | The entrypoint process; must reap and handle signals | `ps` inside |
| No init by default | A bare entrypoint does not reap zombies | `--init` adds one |
| Guest OS | A container has no kernel of its own to boot | no `init` boot logs |
<!-- --8<-- [end:facts] -->

---

## A Container Is a Process

A running container is an ordinary process on the host, visible in `ps`, that happens to have its own namespaces and cgroup. There is no guest kernel and no boot: the runtime forks the entrypoint, places it in new namespaces, and applies limits.

```bash
podman run -d --name demo busybox sleep 300
ps -eo pid,user,args | grep '[s]leep 300'          # find it on the host
podman inspect demo --format 'host PID: {{.State.Pid}}'
```

Output:

```text
   2680 laborant sleep 300
host PID: 2680
```

The container's `sleep` is host PID 2680, owned by the user who ran it. `podman inspect` reports the same PID, confirming the container process and the host process are one and the same.

```bash
sudo ls /proc/2680/ns/ | grep -E 'pid|net|mnt|uts'
```

Output:

```text
mnt -> mnt:[4026532511]
net -> net:[4026532408]
pid -> pid:[4026532514]
uts -> uts:[4026532512]
```

Its namespace inodes differ from the host's `4026531xxx` values, so it has its own process tree, network and mount view while running on the host kernel. That combination, a host process plus fresh namespaces plus a cgroup, is the whole of a container.

!!! note "The container has no kernel of its own"
    `uname -r` inside a container reports the host kernel version, because there is only one kernel. This is why a container cannot load a different kernel module or run a different OS kernel, while a VM can.

---

## The Difference from a VM

A virtual machine runs a full guest kernel on virtual hardware provided by a hypervisor, so it boots like a physical machine and is isolated at the hardware boundary. That stronger boundary costs memory and startup time, covered in [KVM and libvirt](../20-virtualization-and-provisioning/kvm-and-libvirt.md).

| | Container | Virtual machine |
|---|---|---|
| **Kernel** | Shares the host kernel | Own guest kernel |
| **Isolation** | Namespaces plus cgroups | Hardware virtualization |
| **Startup** | Milliseconds, no boot | Seconds, boots a kernel |
| **Overhead** | Process-level, MBs | Full OS, hundreds of MBs |
| **Density** | Hundreds per host | Tens per host |
| **Boundary** | Weaker: a shared kernel | Stronger: separate kernel |
| **Best for** | Packaging and scaling apps | Different OS, strong isolation |

The trade is isolation strength against efficiency. A multi-tenant boundary where a kernel exploit must not cross favours a VM; packaging and scaling one team's services favours containers.

!!! warning "A shared kernel is the container isolation limit"
    Because containers share the host kernel, a kernel vulnerability can affect every container on the host. For hostile multi-tenant workloads, a VM boundary or a sandbox such as gVisor or Kata containers is used instead of plain containers.

---

## PID 1 Duties in a Container

The container's entrypoint runs as PID 1 of its PID namespace, which inherits init's responsibilities: reaping zombie children and forwarding signals. A shell or application that ignores these leaves zombies and does not stop cleanly on `docker stop`.

```bash
# with --init, a small init runs as PID 1 and reaps children
podman run --rm --init busybox sh -c 'ps -o pid,ppid,comm'
```

Output:

```text
    PID   PPID  COMMAND
      1      0  podman-init
      2      1  ps
```

`podman-init` is PID 1 and the command runs as its child, so orphaned processes are reaped by a real init instead of accumulating. Without `--init`, the entrypoint itself is PID 1 and must handle reaping and `SIGTERM`, or the container hangs on shutdown.

!!! tip "Use an init when the entrypoint is not signal-aware"
    A process that does not forward `SIGTERM` will be killed with `SIGKILL` after the stop timeout, losing its chance to shut down cleanly. `--init` (or tini, or an entrypoint that execs the app) fixes both reaping and signal handling.

---

## Common Errors

### `docker stop` takes ten seconds then kills the container

**Cause:** PID 1 in the container does not forward `SIGTERM` to the real application, so the runtime waits out the timeout and sends `SIGKILL`.

**Fix:** `exec` the application in the entrypoint so it becomes PID 1, or run with `--init`.

### a container cannot load a kernel module or set a sysctl

**Cause:** containers share the host kernel and run without the capabilities to modify it, so kernel-level changes are blocked.

**Fix:** set the sysctl or load the module on the host, or use a VM if the workload needs its own kernel.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a container and a virtual machine?"
    **Say first:** a container is a host process isolated with namespaces and cgroups, sharing the host kernel; a VM runs its own guest kernel on virtual hardware.

    **Proof:** `ps` on the host finds a container's process; `uname -r` inside a container reports the host kernel.

    **Follow-up:** which gives a stronger isolation boundary? (a VM, because it has its own kernel.)

??? question "L1: Why does a container start so much faster than a VM?"
    **Say first:** a container only forks a process into new namespaces, while a VM boots a full guest kernel and OS.

    **Proof:** `podman run` returns in milliseconds; a VM boot runs an init sequence.

    **Follow-up:** what does a container give up for that speed? (a shared kernel, so a weaker boundary.)
<!-- --8<-- [end:l1] -->

??? question "L2: Prove that a running container is a process on the host."
    **Say first:** find its PID on the host and confirm it matches what the runtime reports.

    **Proof:**

    ```bash
    podman inspect -f '{{.State.Pid}}' demo
    ps -p <that pid> -o pid,args
    ```

    **Follow-up:** what makes it a container and not a plain process? (its own namespaces and cgroup.)

??? question "L2: A container ignores docker stop and is killed after a delay. Fix it."
    **Say first:** its PID 1 does not handle `SIGTERM`, so make the app PID 1 or add an init.

    **Proof:** `exec` the app in the entrypoint, or run with `--init`; confirm `ps` shows the app or `podman-init` as PID 1.

    **Follow-up:** what else does a proper PID 1 do? (reaps zombie children.)

??? question "L3: A workload needs a different kernel version than the host. Container or VM?"
    **Say first:** a VM, because containers share the host kernel and cannot run a different one.

    **Proof:** `uname -r` inside a container matches the host; only a VM boots its own kernel.

    **Follow-up:** what about a workload that needs a custom kernel module? (load it on the host, or use a VM.)

??? question "L4: Why can a kernel vulnerability affect every container on a host but not every VM?"
    **Say first:** all containers share the one host kernel, so a kernel-level escape reaches the host and its neighbours; VMs each run a separate kernel behind a hardware boundary.

    **Proof:** containers isolate with namespaces in the same kernel; VMs isolate with virtualized hardware and their own kernels.

    **Don't say:** that containers and VMs offer the same isolation strength.

---

## Related

- [Namespaces](namespaces.md): the isolation that makes a process a container
- [Cgroups](cgroups.md): the resource limits a container runs under
- [Podman and Quadlet](podman-and-quadlet.md): running containers in practice
- [KVM and libvirt](../20-virtualization-and-provisioning/kvm-and-libvirt.md): the VM side of the comparison
- [Process Lifecycle](../07-processes/process-lifecycle.md): PID 1, reaping and signals
- [Round 4 Internals](../interview/round-4-internals.md): container internals and isolation

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
