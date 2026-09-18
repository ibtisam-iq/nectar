# Mock Interviews

Three full 45-minute sessions that mix screening, hands-on, troubleshooting and internals the way a real loop does. Run each end to end against the clock, then read the linked topic for anything that was slow.

---

## How to Use These

Set a 45-minute timer and answer out loud, one line first, then the proof. Each question notes what the interviewer is scoring and links to where the full answer lives, so a weak spot maps straight to a topic. Do not read the links until after the timer.

The three mocks escalate: the first is a junior screen, the second a production-engineer troubleshooting loop, the third a senior internals round.

---

## Mock A: Junior DevOps Screen (45 min)

A breadth-first screen that starts light and probes depth on a few answers.

1. **(L1, 3 min)** What is the difference between a process and a thread, and what is PID 1? See [Process Fundamentals](../07-processes/process-fundamentals.md).
2. **(L1, 3 min)** Explain the fields of `ls -l` and the difference between a hard and a soft link. See [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md).
3. **(L2, 5 min)** Add a user to a group so it takes effect, and explain why a current shell does not see it. See [Groups](../04-users-and-access/groups.md).
4. **(L2, 5 min)** A service is `enabled` but not running after boot: walk `systemctl` to diagnose it. See [systemctl](../08-systemd-and-services/systemctl.md).
5. **(L2, 5 min)** In a `df` where writes fail but there is free space, what do you check next? See [Disk Full](scenarios/disk-full.md).
6. **(L3, 8 min)** "The website is down", no other detail: talk through your first five minutes. See [Service Unreachable](scenarios/service-unreachable.md).
7. **(L3, 8 min)** A cron job "does not run" but works by hand: find out why. See [Cron Job Not Running](scenarios/cron-job-not-running.md).
8. **(L4, 6 min)** What happens, step by step, when you type `ls` and press enter (fork/exec, PATH, syscalls)? See [Command Resolution](../01-shell-and-cli/command-resolution.md).

!!! tip "What a screen actually tests"
    The screen is looking for someone who clarifies before acting and knows the basics cold. A confident, ordered `systemctl status` plus `journalctl -u` beats naming an advanced tool you cannot drive.

---

## Mock B: Production Engineer Troubleshooting (45 min)

Symptom-driven, with the interviewer withholding detail until you ask.

1. **(L1, 3 min)** What does load average count, and how do you read it against core count? See [CPU and Load](../17-performance-and-troubleshooting/cpu-and-load.md).
2. **(L2, 6 min)** Read a `top` with CPU 100% user and two hot processes: what is and is not the problem? See [Round 2: Hands-On](round-2-hands-on.md).
3. **(L3, 8 min)** "Load is 40 but the CPUs are idle": diagnose it, knowing load counts `D`-state tasks. See [High Load, Low CPU](scenarios/high-load-low-cpu.md).
4. **(L3, 8 min)** A container keeps dying with exit 137: find the cause and decide the fix. See [High Memory and OOM](scenarios/high-memory-oom.md).
5. **(L2, 5 min)** A service logs `Too many open files`: confirm the layer and raise the right limit. See [Limits and File Descriptors](../17-performance-and-troubleshooting/limits-and-file-descriptors.md).
6. **(L3, 8 min)** Works on `localhost` but not from another host: walk the layers. See [Service Unreachable](scenarios/service-unreachable.md).
7. **(L4, 7 min)** Why can a process on a hung NFS mount not be killed, even with `SIGKILL`? See [NFS](../18-network-storage/nfs.md).

!!! tip "Withheld detail is part of the test"
    A production round often starts vague on purpose. Asking "one host or the fleet?", "when did it start?", and "what changed?" scores as highly as the fix itself.

---

## Mock C: Senior Internals (45 min)

Depth-first, trading breadth for mechanism and trade-offs.

1. **(L2, 5 min)** Prove that a running container is an ordinary process on the host. See [Containers vs VMs](../19-containers/containers-vs-vms.md).
2. **(L4, 8 min)** How does a rootless container run as root inside with no real root on the host (the user namespace and `uid_map`)? See [Namespaces](../19-containers/namespaces.md).
3. **(L4, 8 min)** A program `malloc`s 2 GB, it succeeds, then it is killed: explain overcommit, demand paging and the OOM killer. See [Virtual Memory](../17-performance-and-troubleshooting/virtual-memory.md).
4. **(L4, 7 min)** How does the kernel enforce a cgroup memory limit, and what exactly happens at the cap? See [Cgroups](../19-containers/cgroups.md).
5. **(L4, 7 min)** What is the difference between a kernel oops and a panic, and when does one become the other? See [Kernel Panic](../16-boot-and-recovery/kernel-panic.md).
6. **(L4, 6 min)** Why must `/etc/shadow` be relabelled after resetting the root password in a chroot on SELinux? See [Recovery](../16-boot-and-recovery/recovery.md).
7. **(L3, 4 min)** How would you decide between a container and a VM for a hostile multi-tenant workload? See [Containers vs VMs](../19-containers/containers-vs-vms.md).

!!! tip "Senior rounds reward the trade-off, not the recital"
    Naming the mechanism is table stakes; the signal is stating the cost. "A container is cheaper but shares the host kernel, so a kernel exploit crosses the boundary" is the answer they want.

---

## Related

- [Round 1: Screening](round-1-screening.md): the L1 bank
- [Round 2: Hands-On](round-2-hands-on.md): the L2 tasks and output drills
- [Round 3: Troubleshooting](round-3-troubleshooting.md): the L3 scenario index
- [Round 4: Internals](round-4-internals.md): the L4 bank
- [Interview Overview](README.md): how the rounds fit together
