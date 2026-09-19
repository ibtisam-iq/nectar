# Namespaces

A namespace is a kernel feature that gives a group of processes their own isolated view of one global resource, such as the process tree or the network. Namespaces are the isolation half of a container, and understanding them turns "a container is magic" into "a container is a process with its own namespaces".

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Count | Eight types: mnt, pid, net, uts, ipc, user, cgroup, time | `ls /proc/self/ns/` |
| mnt | Isolates the mount table (each container's own filesystem view) | `unshare --mount` |
| pid | Isolates process ids; the first process becomes PID 1 | `unshare --pid --fork` |
| net | Isolates interfaces, routes, ports, firewall | `unshare --net` |
| uts | Isolates hostname and domain name | `unshare --uts` |
| ipc | Isolates System V IPC and POSIX message queues | `unshare --ipc` |
| user | Isolates uid/gid; maps container root to an unprivileged host uid | `unshare --user` |
| cgroup | Isolates the cgroup root the process sees | `unshare --cgroup` |
| Identity | A namespace is an inode number under `/proc/PID/ns/` | `ls -l /proc/self/ns/net` |
| List them | Show namespaces and the processes in each | `lsns` |
| Create | Start a process in new namespaces | `unshare` |
| Join | Enter the namespaces of a running process | `nsenter -t PID` |
| Syscalls | `clone`, `unshare`, `setns` create and join namespaces | `man 7 namespaces` |
<!-- --8<-- [end:facts] -->

---

## The Eight Namespaces

Each process belongs to one namespace of every type, exposed as a symlink under `/proc/PID/ns/`. The target of each link is `type:[inode]`, and that inode number is the namespace's identity: two processes in the same namespace point at the same inode.

```bash
ls -l /proc/self/ns/
```

Output:

```text
lrwxrwxrwx 1 laborant laborant 0 cgroup -> cgroup:[4026531835]
lrwxrwxrwx 1 laborant laborant 0 ipc -> ipc:[4026531839]
lrwxrwxrwx 1 laborant laborant 0 mnt -> mnt:[4026531841]
lrwxrwxrwx 1 laborant laborant 0 net -> net:[4026531840]
lrwxrwxrwx 1 laborant laborant 0 pid -> pid:[4026531836]
lrwxrwxrwx 1 laborant laborant 0 time -> time:[4026531834]
lrwxrwxrwx 1 laborant laborant 0 user -> user:[4026531837]
lrwxrwxrwx 1 laborant laborant 0 uts -> uts:[4026531838]
```

The inodes in the `4026531xxx` range are the host's initial namespaces, shared by every normal process. A container gets fresh inodes for the types it isolates, and keeps the host's for the rest.

!!! note "A namespace is an inode, not a process"
    A namespace exists as long as a process is in it or a file descriptor or bind mount pins it. Comparing the inode numbers behind two processes' `/proc/PID/ns/net` links is how you tell whether they share a network namespace.

---

## Listing Namespaces

`lsns` reads `/proc` and groups processes by namespace, showing the type, the number of processes, and the lowest-PID process in each. On a plain host most processes share the initial namespaces started by PID 1.

```bash
sudo lsns | head -8
```

Output:

```text
        NS TYPE   NPROCS   PID USER    COMMAND
4026531834 time      105     1 root    /sbin/init
4026531835 cgroup    105     1 root    /sbin/init
4026531836 pid       105     1 root    /sbin/init
4026531837 user      105     1 root    /sbin/init
4026531838 uts        94     1 root    /sbin/init
4026531839 ipc       105     1 root    /sbin/init
4026531840 net       103     1 root    /sbin/init
4026531841 mnt        86     1 root    /sbin/init
```

Every type traces back to `/sbin/init` (PID 1), which is the shared root. When a container runs, new rows appear with a different `NS` inode and the container's own process count.

---

## Creating a Namespace with unshare

`unshare` runs a command in new namespaces of the types requested. A new UTS namespace, for example, gives the process its own hostname, so a change inside it does not affect the host.

```bash
sudo unshare --uts sh -c 'hostname container01; echo inside: $(hostname)'
echo outside: $(hostname)
```

Output:

```text
inside: container01
outside: web
```

The hostname `container01` exists only inside the namespace. This is the same mechanism `podman run --hostname` uses.

---

## The PID Namespace

A new PID namespace renumbers processes from 1, so the first process in it becomes PID 1 and sees only its own descendants. `--fork` makes `unshare` fork the command (PID 1 must be a child, not `unshare` itself), and `--mount-proc` remounts `/proc` so `ps` reflects the new namespace.

```bash
sudo unshare --pid --fork --mount-proc bash -c \
  'sleep 30 & echo "shell pid: $$"; ps -e -o pid,ppid,comm'
```

Output:

```text
shell pid: 1
    PID    PPID COMMAND
      1       0 bash
      2       1 sleep
      3       1 ps
```

Inside, `bash` is PID 1 with `sleep` and `ps` as its children, and its `PPID` is 0 because its real parent lives outside the namespace and is not visible. This is why the process inside a container that shows as PID 1 is an ordinary host process with a different PID on the host.

!!! warning "PID 1 in a namespace inherits init's duties"
    The PID 1 of a namespace must reap orphaned children and handle signals, or zombies accumulate and `docker stop` hangs. A shell as PID 1 does neither well, which is why runtimes offer a small init such as `--init`, covered in [Containers vs VMs](containers-vs-vms.md).

---

## The Network Namespace

A new network namespace starts with only a loopback interface, and that interface is down. It has no route to anything until a virtual link is added, which is how a container starts fully isolated on the network.

```bash
sudo unshare --net ip -br link      # inside the new namespace
ip -br link | head -2                # the host, for comparison
```

Output:

```text
lo               DOWN           00:00:00:00:00:00 <LOOPBACK>
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
eth0             UP             de:bc:47:xx:xx:xx <BROADCAST,MULTICAST,UP,LOWER_UP>
```

The isolated namespace sees only `lo`, and it is `DOWN`, so nothing works until it is brought up and connected. Container networking connects this namespace to the host with a `veth` pair, one end in each namespace, described in [Overlayfs and Chroot](overlayfs-and-chroot.md) and the networking module.

---

## Joining a Namespace with nsenter

`nsenter` runs a command inside the namespaces of an already running process, selected by PID. This is how a debugger drops into a container's network or mount namespace without the container's own tools.

```bash
sudo nsenter -t <PID> -u hostname   # -u = enter that process's UTS namespace
```

Output:

```text
sandbox
```

The command ran in the target's UTS namespace and saw its hostname, `sandbox`, not the host's. `nsenter -t <PID> -n ss -tlnp` is the common form for inspecting a container's listening sockets from the host.

!!! tip "nsenter is the way into a container that has no shell"
    A distroless or scratch container has no `sh` for `docker exec`. `nsenter -t <host-pid> -a` enters all of its namespaces using the host's binaries, so you can inspect it with tools the image does not contain.

---

## Common Errors

### `unshare: unshare failed: Operation not permitted`

**Cause:** creating most namespaces needs `CAP_SYS_ADMIN`, so an unprivileged user cannot unshare a PID or mount namespace directly.

**Fix:** run under `sudo`, or first create a user namespace (`unshare --user --map-root-user`), which grants capabilities inside it.

### `nsenter: cannot open /proc/<pid>/ns/net: No such file or directory`

**Cause:** the target PID exited, or the wrong PID was used (the container's in-namespace PID instead of its host PID).

**Fix:** use the host PID from `podman inspect --format '{{.State.Pid}}'` or `ps`, and confirm the process is still running.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a namespace, and what does it isolate?"
    **Say first:** a namespace gives a set of processes their own isolated instance of a global kernel resource, such as the process tree, network stack, or mount table.

    **Proof:** `ls /proc/self/ns/` lists the eight types; `lsns` shows which processes share each one.

    **Follow-up:** which namespace makes rootless containers possible? (the user namespace, by mapping container root to an unprivileged host uid.)

??? question "L1: What is the difference between a namespace and a cgroup?"
    **Say first:** a namespace controls what a process can see; a cgroup controls how much it can use.

    **Proof:** namespaces isolate the PID, net and mount views; cgroups cap CPU, memory and pids, covered in Cgroups.

    **Follow-up:** which one does `docker run --memory` use? (a cgroup.)
<!-- --8<-- [end:l1] -->

??? question "L2: Create a process that has its own hostname without affecting the host."
    **Say first:** run it in a new UTS namespace.

    **Proof:**

    ```bash
    sudo unshare --uts sh -c 'hostname box; hostname'
    ```

    **Follow-up:** how do you also give it its own process tree? (add `--pid --fork --mount-proc`.)

??? question "L2: Inspect a running container's listening ports from the host."
    **Say first:** enter its network namespace with `nsenter` using the container's host PID.

    **Proof:** `sudo nsenter -t $(podman inspect -f '{{.State.Pid}}' web) -n ss -tlnp`.

    **Follow-up:** why not use the container's own `ss`? (a minimal image may not contain it; `nsenter` uses the host's binaries.)

??? question "L3: A container process shows as PID 1 inside but the host cannot find PID 1 for it. Explain."
    **Say first:** PID namespaces renumber from 1, so the same process has one PID inside its namespace and a different, higher PID on the host.

    **Proof:** `ps` inside shows PID 1; `podman inspect -f '{{.State.Pid}}'` gives the host PID; both refer to one process.

    **Follow-up:** what does `kill 1` inside the container do? (signals the container's PID 1, which stops the container, not the host.)

??? question "L4: How does a rootless container let 'root' inside map to a normal user outside?"
    **Say first:** a user namespace maps uid 0 inside to the caller's unprivileged uid on the host, and a range of further ids to the caller's subuid allocation, so root inside owns nothing privileged outside.

    **Proof:** `/proc/PID/uid_map` shows the mapping; `/etc/subuid` holds the range, covered in [Podman and Quadlet](podman-and-quadlet.md).

    **Don't say:** that rootless containers run as real root; the container root is confined to the mapped range.

??? question "L4: What keeps a namespace alive after the process that created it exits?"
    **Say first:** a namespace persists while any process is a member, or while a file descriptor or bind mount pins it, and is destroyed when the last reference goes away.

    **Proof:** `ip netns add` bind-mounts the net namespace under `/var/run/netns` so it survives with no process in it.

    **Don't say:** that a namespace always disappears the instant its creator exits.

---

## Related

- [Cgroups](cgroups.md): the resource-limit half of a container
- [Overlayfs and Chroot](overlayfs-and-chroot.md): the filesystem view a mount namespace carries
- [Containers vs VMs](containers-vs-vms.md): why a container is a process, and PID 1 duties
- [Podman and Quadlet](podman-and-quadlet.md): rootless containers and the user namespace
- [Process Fundamentals](../07-processes/process-fundamentals.md): PID, PPID and the process tree
- [Round 4 Internals](../interview/round-4-internals.md): namespaces, PID 1 and rootless mapping

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The host MAC address is scrubbed.
