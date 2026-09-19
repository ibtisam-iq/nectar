# Containers by Hand

Build a container from its parts, with no container runtime: isolate the process tree and mounts with namespaces, give it its own root filesystem with OverlayFS, connect it to the host with a veth pair, and cap its resources with a cgroup. The goal is to prove that a container is a process plus namespaces plus a cgroup.

---

## Setup

Use a single Rocky Linux or Ubuntu playground with root. Confirm cgroup v2 and the namespace tools:

```bash
stat -fc %T /sys/fs/cgroup            # expect cgroup2fs
cat /sys/fs/cgroup/cgroup.controllers # expect cpu memory pids ...
command -v unshare nsenter ip
```

Work as root (`sudo -i`) throughout, and clean up each namespace and cgroup at the end. No container runtime is used until the final comparison step.

!!! warning "These commands change the host's namespaces and network"
    Creating veth pairs and cgroups touches real host state. Delete each namespace, link and cgroup when done, and do this on a throwaway VM, not a shared host.

---

## 1. Isolate the Process Tree

Give a shell its own PID and mount namespaces, so it becomes PID 1 and sees only its own processes.

??? tip "Solution"
    ```bash
    unshare --pid --fork --mount-proc bash
    # inside:
    echo "my pid: $$"        # 1
    sleep 60 &
    ps -e -o pid,ppid,comm   # only this shell, sleep, ps
    ```

    The shell is PID 1, its children are PID 2 upward, and no host processes are visible. `--mount-proc` remounts `/proc` so `ps` reflects the new PID namespace. Exit the shell to leave the namespace.

---

## 2. Give It Its Own Root Filesystem

Build a root filesystem as an overlay of a read-only base and a writable layer, then enter it with `chroot`.

??? tip "Solution"
    ```bash
    cd /tmp && mkdir -p c/lower c/upper c/work c/merged
    # populate the lower with a base userland
    CID=$(podman create busybox); podman export $CID | tar -x -C c/lower; podman rm $CID
    mount -t overlay overlay \
      -o lowerdir=c/lower,upperdir=c/upper,workdir=c/work c/merged
    chroot c/merged /bin/sh -c 'echo root is: $(pwd); ls /bin | head -3'
    ```

    `chroot` makes `c/merged` the root, so the shell sees only the overlay. A write inside copies the file up into `c/upper`, leaving the read-only `c/lower` untouched, which is how image layers stay shareable. Real runtimes use `pivot_root` inside a mount namespace instead of `chroot`.

---

## 3. Isolate and Connect the Network

Create a network namespace, then join it to the host with a veth pair so it can reach the host.

??? tip "Solution"
    ```bash
    ip netns add sandbox
    ip link add veth0 type veth peer name veth1
    ip link set veth1 netns sandbox
    ip addr add 10.200.0.1/24 dev veth0; ip link set veth0 up
    ip netns exec sandbox ip addr add 10.200.0.2/24 dev veth1
    ip netns exec sandbox ip link set veth1 up
    ip netns exec sandbox ip link set lo up
    ip netns exec sandbox ping -c1 10.200.0.1
    ```

    Output:

    ```text
    1 packets transmitted, 1 received, 0% packet loss
    ```

    The namespace starts with only a down loopback; the veth pair is the cable, one end in each namespace. A real runtime adds the host end to a bridge and enables NAT for outbound access.

---

## 4. Cap Its Resources

Put a workload in a cgroup and limit its memory, CPU and process count. Enable the controllers on the parent first.

??? tip "Solution"
    ```bash
    cd /sys/fs/cgroup
    echo "+cpu +memory +pids" > cgroup.subtree_control
    mkdir -p handbuilt
    echo "20000 100000" > handbuilt/cpu.max     # 0.2 CPU
    echo "64M"          > handbuilt/memory.max
    echo "20"           > handbuilt/pids.max
    echo $$ > handbuilt/cgroup.procs            # move this shell in
    cat handbuilt/cpu.stat | grep throttled     # after some CPU load
    ```

    A CPU-bound process now shows `nr_throttled` climbing in `cpu.stat`; a process that exceeds `memory.max` is OOM-killed with exit 137; a fork past `pids.max` fails with `Resource temporarily unavailable`. Move the shell out (`echo $$ > /sys/fs/cgroup/cgroup.procs`) before removing the cgroup.

---

## 5. Enter It from Outside

From the host, enter the running "container" the way `docker exec` does, using the target process's host PID.

??? tip "Solution"
    ```bash
    # in one shell: unshare --uts --fork sh -c 'hostname sandbox; sleep 300'
    PID=$(pgrep -f 'sleep 300')
    nsenter -t $PID -u hostname       # enters the UTS namespace
    ```

    Output:

    ```text
    sandbox
    ```

    `nsenter` joins the target's namespaces using the host's binaries, so it works even on a container with no shell of its own.

---

## 6. Compare to a Real Container

Run the same workload with Podman and confirm it is doing exactly what you built by hand.

??? tip "Solution"
    ```bash
    podman run -d --name real --memory 64m --pids-limit 20 busybox sleep 300
    HPID=$(podman inspect -f '{{.State.Pid}}' real)
    ps -p $HPID -o pid,comm            # the container's process, on the host
    ls -l /proc/$HPID/ns/              # its own pid/net/mnt/uts namespaces
    cat /proc/$HPID/cgroup             # its cgroup with the limits you set by hand
    podman rm -f real
    ```

    Podman created the same three things: a process with its own namespaces, an overlay root, and a cgroup with `memory.max` and `pids.max`. The runtime automates the steps of this lab and adds image management, networking and lifecycle.

---

## Cleanup

```bash
umount /tmp/c/merged 2>/dev/null; rm -rf /tmp/c
ip netns del sandbox 2>/dev/null; ip link del veth0 2>/dev/null
echo $$ > /sys/fs/cgroup/cgroup.procs; rmdir /sys/fs/cgroup/handbuilt 2>/dev/null
```

---

## Related

- [Namespaces](../19-containers/namespaces.md): the isolation primitives used here
- [Cgroups](../19-containers/cgroups.md): the resource limits applied in step 4
- [Overlayfs and Chroot](../19-containers/overlayfs-and-chroot.md): the root filesystem in step 2
- [Containers vs VMs](../19-containers/containers-vs-vms.md): why this proves a container is a process
- [Podman and Quadlet](../19-containers/podman-and-quadlet.md): the runtime that automates these steps

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
