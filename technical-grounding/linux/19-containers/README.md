# Containers

The kernel features that make a container, and how Podman uses them. This module is the bridge from Linux fundamentals to the [Docker](../../../containers-orchestration/docker/README.md) and Kubernetes material, showing that a container is a process with namespaces, cgroups and an overlay root.

---

## Revision Card

| Fact | Value |
|---|---|
| A container is | A host process with its own namespaces and a cgroup |
| Namespaces | Eight types: mnt, pid, net, uts, ipc, user, cgroup, time |
| Isolation vs limits | Namespaces isolate the view; cgroups cap the resources |
| cgroup v2 | One unified tree at `/sys/fs/cgroup` |
| Exit 137 | 128 + SIGKILL: the OOM killer hit `memory.max` |
| Image layers | Read-only overlay lowerdirs; the container adds a writable upperdir |
| Copy-up | Writing a lower file copies it into the upper first |
| Rootless | A user namespace maps container root to the user's uid and subuid range |
| Quadlet | `.container` units run containers as systemd services |
| Shared kernel | Containers share the host kernel; a VM has its own |

| Task | Command |
|---|---|
| List namespaces | `lsns`, `ls /proc/self/ns/` |
| New namespace | `unshare --pid --fork --mount-proc bash` |
| Enter a namespace | `nsenter -t PID -a` |
| Enabled controllers | `cat /sys/fs/cgroup/cgroup.controllers` |
| Cap memory in a scope | `systemd-run --scope -p MemoryMax=100M cmd` |
| Cap CPU in a scope | `systemd-run --scope -p CPUQuota=50% cmd` |
| Find a container's host PID | `podman inspect -f '{{.State.Pid}}' NAME` |
| Rootless uid map | `cat /proc/PID/uid_map` |
| Run a container | `podman run -d -p 8080:80 IMAGE` |
| Container as a service | Quadlet `.container` in `/etc/containers/systemd/` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Namespaces](namespaces.md) | The eight namespace types, `unshare`, `nsenter`, PID 1, `lsns` | Core | High |
| [Cgroups](cgroups.md) | v2 hierarchy, `cpu.max` throttling, `memory.max` and OOM, `pids.max`, systemd | Core | High |
| [Overlayfs and Chroot](overlayfs-and-chroot.md) | `chroot`, overlay layers, copy-up, image layers | Core | Med |
| [Containers vs VMs](containers-vs-vms.md) | A container is a process; shared kernel; PID 1 duties; `--init` | Core | High |
| [Podman and Quadlet](podman-and-quadlet.md) | Rootless, subuid mapping, volumes, `:Z`, Quadlet units | RHCSA | Med |

---

## Scenarios and Labs

- [High Memory and OOM](../interview/scenarios/high-memory-oom.md): a leak, the OOM killer, and container exit 137
- [Containers by Hand](../labs/containers-by-hand-lab.md): build a container with namespaces, cgroups and overlayfs, no runtime
