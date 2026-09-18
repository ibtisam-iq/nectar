# Cgroups

Control groups (cgroups) are the kernel feature that limits, accounts for, and isolates the resource use of a group of processes. Cgroups are the resource-control half of a container, and the same mechanism enforces `docker run --memory`, systemd unit limits, and Kubernetes pod requests.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Version | v2 is the unified hierarchy; v1 had a tree per controller | `stat -fc %T /sys/fs/cgroup` |
| Mount point | A single tree at `/sys/fs/cgroup` | `mount | grep cgroup2` |
| Controllers | cpu, memory, io, pids, cpuset, hugetlb | `cat /sys/fs/cgroup/cgroup.controllers` |
| Enable in children | Write to `cgroup.subtree_control` of the parent | `echo +memory > .../cgroup.subtree_control` |
| Add a process | Write its PID to `cgroup.procs` | `echo $$ > .../cgroup.procs` |
| CPU limit | `cpu.max` = quota period, in microseconds | `echo "20000 100000" > cpu.max` |
| CPU throttling | `cpu.stat` counts throttled periods | `grep throttled .../cpu.stat` |
| Memory limit | `memory.max` is a hard cap; exceeding it triggers cgroup OOM | `cat .../memory.max` |
| OOM record | `memory.events` counts `oom` and `oom_kill` | `cat .../memory.events` |
| Process limit | `pids.max` caps the number of tasks | `cat .../pids.max` |
| systemd slices | systemd is the cgroup manager; units are scopes and slices | `systemd-cgls` |
| Exit 137 | 128 + SIGKILL(9): the OOM killer killed the process | `dmesg`, container exit code |
<!-- --8<-- [end:facts] -->

---

## The v2 Unified Hierarchy

Cgroup v2 presents one tree at `/sys/fs/cgroup`, where each directory is a cgroup and the available controllers are listed in `cgroup.controllers`. A controller acts on a child cgroup only after it is enabled in the parent's `cgroup.subtree_control`.

```bash
stat -fc %T /sys/fs/cgroup           # cgroup2fs confirms v2
cat /sys/fs/cgroup/cgroup.controllers
```

Output:

```text
cgroup2fs
cpuset cpu io memory hugetlb pids
```

Each cgroup exposes control files for the enabled controllers, such as `cpu.max` and `memory.max`, and accounting files, such as `memory.current` and `cpu.stat`. A process joins a cgroup by writing its PID to that cgroup's `cgroup.procs`.

!!! note "v2 replaced v1's separate hierarchies"
    In cgroup v1 each controller had its own tree, so a process could sit in different cgroups per controller. v2 uses one hierarchy for all controllers, which is why modern container runtimes and systemd standardise on it.

---

## Limiting CPU

`cpu.max` holds two numbers, a quota and a period in microseconds: the cgroup may run for `quota` out of every `period`. Setting `20000 100000` allows 20 ms of CPU per 100 ms, which is 0.2 of one CPU, and the kernel throttles the group once it exhausts the quota in a period.

```bash
cd /sys/fs/cgroup && sudo mkdir -p demo
echo "+cpu" | sudo tee demo/../cgroup.subtree_control >/dev/null
echo "20000 100000" | sudo tee demo/cpu.max >/dev/null   # 0.2 CPU
stress-ng --cpu 1 --timeout 4s & echo $! | sudo tee demo/cgroup.procs >/dev/null
sleep 4.5; grep -E 'nr_periods|nr_throttled|throttled_usec' demo/cpu.stat
```

Output:

```text
nr_periods 44
nr_throttled 42
throttled_usec 3301949
```

Of 44 scheduling periods, 42 were throttled and the group spent 3.3 seconds waiting for quota. A container hitting its CPU limit shows exactly this: the process is runnable but held off the CPU, so latency rises while CPU utilization looks capped.

!!! tip "High throttling means the CPU limit is the bottleneck"
    A service that is slow with `nr_throttled` climbing is being held back by its own `cpu.max`, not by a lack of CPU on the host. Raise the limit or lower the concurrency; adding host CPUs will not help.

---

## Limiting Memory and the OOM Killer

`memory.max` is a hard cap on a cgroup. When usage would exceed it and nothing can be reclaimed, the kernel's OOM killer kills a process in the group, which surfaces as exit code 137.

```bash
cd /sys/fs/cgroup && sudo mkdir -p oomdemo
echo 80M | sudo tee oomdemo/memory.max >/dev/null
echo 0   | sudo tee oomdemo/memory.swap.max >/dev/null
sudo bash -c 'echo $BASHPID > oomdemo/cgroup.procs; exec python3 -c "
a=bytearray()
while True: a += bytearray(10*1024*1024)"'
echo "exit code: $?"
grep -E '^oom' oomdemo/memory.events
```

Output:

```text
exit code: 137
oom 1
oom_kill 1
oom_group_kill 0
```

The process was killed at the 80 MB cap, `memory.events` recorded one `oom_kill`, and the shell saw exit 137. The kernel log names the victim and the constraint.

```bash
sudo dmesg | grep -i 'Memory cgroup out of memory' | tail -1
```

Output:

```text
Memory cgroup out of memory: Killed process 1968 (python3) total-vm:94796kB, anon-rss:81328kB, file-rss:4924kB, shmem-rss:0kB, UID:0 pgtables:224kB oom_score_adj:0
```

The line reads `Memory cgroup out of memory`, meaning the cap was the group's `memory.max`, not the host running out of RAM. A container that dies with exit 137 and no application error is almost always this, covered in [High Memory and OOM](../interview/scenarios/high-memory-oom.md).

---

## Limiting Processes

`pids.max` caps how many tasks a cgroup may hold, which stops a fork bomb in one container from exhausting the host's process table. Once the count reaches the cap, `fork` fails with `EAGAIN`.

```bash
cd /sys/fs/cgroup && sudo mkdir -p pidsdemo
echo 5 | sudo tee pidsdemo/pids.max >/dev/null
echo $$ | sudo tee pidsdemo/cgroup.procs >/dev/null
for i in $(seq 8); do sleep 5 & done
grep . pidsdemo/pids.events
```

Output:

```text
bash: fork: retry: Resource temporarily unavailable
bash: fork: retry: Resource temporarily unavailable
max 3
```

The shell could not fork past the limit, and `pids.events` records `max 3`, the number of times a fork was denied. This is the same `EAGAIN` a global `RLIMIT_NPROC` produces, covered in [Limits and File Descriptors](../17-performance-and-troubleshooting/limits-and-file-descriptors.md).

---

## systemd Manages the Tree

On a systemd host, systemd owns the cgroup hierarchy and every service runs in its own cgroup, so unit limits such as `MemoryMax=` and `CPUQuota=` are written straight into these files. `systemd-cgls` shows the tree as slices and scopes.

```bash
systemd-cgls --no-pager | head -8
```

Output:

```text
CGroup /:
-.slice
├─user.slice
│ └─user-1001.slice
│   ├─session-c8.scope
│   └─user@1001.service …
├─init.scope
```

Because systemd is the single manager, writing cgroup files by hand under a systemd-managed path can be undone by systemd. The supported path is a unit directive or `systemd-run --scope -p MemoryMax=...`.

---

## Common Errors

### container exits with code 137 and no application error

**Cause:** the OOM killer killed the container's main process because it hit `memory.max`.

**Fix:** confirm with `dmesg | grep -i 'out of memory'`; raise the memory limit if the usage is legitimate, or fix the leak.

### `echo: write error: No such file or directory` writing to a controller file

**Cause:** the controller is not enabled in the parent's `cgroup.subtree_control`, so `cpu.max` or `memory.max` does not exist in the child.

**Fix:** `echo +memory +cpu > <parent>/cgroup.subtree_control` before creating and configuring the child cgroup.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What do cgroups do, and how do they differ from namespaces?"
    **Say first:** cgroups limit and account for a group of processes' resource use (CPU, memory, pids, I/O); namespaces isolate what those processes can see.

    **Proof:** `cpu.max` and `memory.max` cap usage; `/proc/self/ns/` shows the isolation, covered in Namespaces.

    **Follow-up:** which one enforces `docker run --memory`? (a cgroup, via `memory.max`.)

??? question "L1: What is cgroup v2, and how does it differ from v1?"
    **Say first:** v2 is a single unified hierarchy for all controllers; v1 had a separate tree per controller.

    **Proof:** `stat -fc %T /sys/fs/cgroup` returns `cgroup2fs`; controllers are enabled per subtree with `cgroup.subtree_control`.

    **Follow-up:** why did runtimes move to v2? (one consistent hierarchy, better memory and OOM handling.)
<!-- --8<-- [end:l1] -->

??? question "L2: Cap a command at half a CPU using a cgroup."
    **Say first:** set `cpu.max` to a quota that is half the period.

    **Proof:**

    ```bash
    systemd-run --scope -p CPUQuota=50% stress-ng --cpu 1
    ```

    **Follow-up:** how do you tell the cap is the bottleneck? (`cpu.stat` shows `nr_throttled` rising.)

??? question "L2: A service is slow and cpu.stat shows nr_throttled climbing. What is happening?"
    **Say first:** the service is hitting its CPU quota and being throttled, so it is runnable but held off the CPU.

    **Proof:** compare `nr_throttled` to `nr_periods` in `cpu.stat`; raise `CPUQuota` or reduce concurrency.

    **Follow-up:** would adding host CPUs help? (no, the limit is the group's own quota.)

??? question "L3: A container keeps dying with exit code 137. Diagnose it."
    **Say first:** exit 137 is 128 plus SIGKILL, and for a container it almost always means the cgroup OOM killer fired at `memory.max`.

    **Proof:** `dmesg | grep -i 'Memory cgroup out of memory'` names the process and cap; `memory.events` shows `oom_kill` incrementing.

    **Follow-up:** how do you decide between raising the limit and fixing a leak? (watch RSS over time; a steady climb is a leak, a spike at load is undersizing.)

??? question "L4: How does the kernel enforce a memory limit, and what happens at the cap?"
    **Say first:** the memory controller charges each page a cgroup faults in against `memory.current`, and when a charge would exceed `memory.max` the kernel first tries to reclaim pages, then invokes the OOM killer on the group.

    **Proof:** `memory.current` tracks usage; `memory.events` counts `max` (hit the limit) and `oom_kill`; the OOM line in `dmesg` names the constraint.

    **Don't say:** that the process gets a catchable error; it receives SIGKILL and cannot clean up.

??? question "L4: Why should cgroup files not be edited by hand on a systemd host?"
    **Say first:** systemd is the single cgroup manager and owns the hierarchy, so it can overwrite or move a cgroup you edited directly, undoing the change.

    **Proof:** use `systemd-run --scope -p MemoryMax=...` or a unit directive; `systemd-cgls` shows systemd's slices and scopes.

    **Don't say:** that manual writes under a systemd-managed slice are stable.

---

## Related

- [Namespaces](namespaces.md): the isolation half of a container
- [Containers vs VMs](containers-vs-vms.md): how limits and isolation combine into a container
- [Limits and File Descriptors](../17-performance-and-troubleshooting/limits-and-file-descriptors.md): `EAGAIN` and process limits
- [Memory](../17-performance-and-troubleshooting/memory.md): the OOM killer and exit 137 at the host level
- [systemctl](../08-systemd-and-services/systemctl.md): units, scopes and slices
- [Round 4 Internals](../interview/round-4-internals.md): memory limits, OOM and exit 137

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
