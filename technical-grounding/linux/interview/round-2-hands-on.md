# Round 2: Hands-On

The second round is at a keyboard: do a task under time pressure, or read a tool's output and say what is wrong. It scores whether you reach for the right command without hesitating and whether you can interpret real output, not recite theory.

---

## How This Round Works

The interviewer gives a short task ("add a user who can sudo but not log in with a password") or shows a captured screen ("here is `top`, what is wrong?"). Speak the plan in one line, run or read, then confirm the result.

The tasks below are grouped by module and answered with a worked solution. The output-reading drills show a real capture: decide what is wrong before opening the answer.

---

## Timed Tasks

### Users and Permissions

??? tip "Add a service account that cannot log in, then let one admin sudo to it"
    ```bash
    sudo useradd -r -s /usr/sbin/nologin appsvc      # no login shell
    sudo -u appsvc whoami 2>&1 || true               # confirm it cannot log in
    echo 'alice ALL=(appsvc) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/alice-appsvc
    sudo visudo -cf /etc/sudoers.d/alice-appsvc       # validate before trusting it
    ```

    A system account (`-r`) with a `nologin` shell cannot start a session, and the sudoers drop-in lets `alice` run commands as it. Always validate a sudoers file with `visudo -c`, covered in [Sudo and su](../04-users-and-access/sudo-and-su.md).

??? tip "Give a team read-write to a shared directory, with new files inheriting the group"
    ```bash
    sudo groupadd -f devs
    sudo install -d -g devs -m 2775 /srv/shared        # 2 = setgid
    sudo setfacl -d -m g:devs:rwx /srv/shared          # default ACL for new files
    getfacl /srv/shared | grep default
    ```

    The setgid bit makes new files take the directory's group, and the default ACL sets their permissions, covered in [Special Permissions](../05-permissions/special-permissions.md) and [ACL](../05-permissions/acl.md).

### Systemd and Storage

??? tip "Make a failing service restart automatically and start on boot"
    ```bash
    sudo systemctl edit myapp        # add: [Service] \n Restart=on-failure \n RestartSec=5
    sudo systemctl daemon-reload
    sudo systemctl enable --now myapp
    systemctl show myapp -p Restart -p RestartSec
    ```

    The drop-in adds the restart policy without editing the shipped unit, covered in [Unit Files](../08-systemd-and-services/unit-files.md).

??? tip "Add 2 GB of swap as a file and make it survive reboot"
    ```bash
    sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
    sudo mkswap /swapfile && sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    swapon --show
    ```

    The `/etc/fstab` line re-enables it on boot, covered in [Swap](../12-storage/swap.md).

### Networking and Containers

??? tip "Open port 8080 permanently in firewalld and confirm"
    ```bash
    sudo firewall-cmd --add-port=8080/tcp --permanent
    sudo firewall-cmd --reload
    sudo firewall-cmd --list-ports
    ```

    `--permanent` writes the rule; `--reload` applies it to the running firewall, covered in [Firewalld and UFW](../15-security/firewalld-and-ufw.md).

??? tip "Run a container with a memory limit and persistent data"
    ```bash
    podman volume create appdata
    podman run -d --name app --memory 256m -v appdata:/data myimage
    podman inspect app --format '{{.HostConfig.Memory}}'
    ```

    The volume outlives the container; `--memory` sets the cgroup `memory.max`, covered in [Podman and Quadlet](../19-containers/podman-and-quadlet.md).

---

## Output-Reading Drills

Read each capture and decide what is wrong before opening the answer.

### Drill 1: top

Output:

```text
top - 08:15:53 up 0 min,  0 user,  load average: 0.16, 0.03, 0.01
Tasks: 142 total,   3 running, 139 sleeping,   0 stopped,   0 zombie
%Cpu(s):100.0 us,  0.0 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :    975.4 total,    487.3 free,    453.0 used,    206.3 buff/cache
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   1380 laborant  20   0   66172   7036   4200 R 100.0   0.7   0:02.13 stress-+
   1381 laborant  20   0   66172   7036   4200 R 100.0   0.7   0:02.12 stress-+
```

??? tip "What's wrong?"
    CPU is fully saturated in user space (`100.0 us`, `0.0 wa`, `0.0 st`), and two `stress-ng` processes are each pinning a core. This is CPU-bound work, not I/O or memory: memory is healthy and there is no iowait. The fix is on the process, not the host, covered in [CPU and Load](../17-performance-and-troubleshooting/cpu-and-load.md).

### Drill 2: free

Output:

```text
               total        used        free      shared  buff/cache   available
Mem:           975Mi       965Mi        60Mi       3.5Mi        43Mi        10Mi
```

??? tip "What's wrong?"
    The host is out of usable memory: `available` is 10Mi, and `buff/cache` has already been squeezed to 43Mi, so there is nothing left to reclaim. The next allocation risks the OOM killer. Judge by `available`, not `free`, covered in [Memory](../17-performance-and-troubleshooting/memory.md).

### Drill 3: vmstat 1

Output:

```text
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 4  0      0 570660   3820 138804    0    0  3697 12372  341    2 12  3 84  2  0  0
 3  0      0 570660   3820 138936    0    0     0     0  504  148 100  0  0  0  0  0
 3  0      0 570660   3820 138936    0    0     0     0  512  161 100  0  0  0  0  0
```

??? tip "What's wrong?"
    The run queue `r` is 3 to 4 on a two-CPU host with `us` at 100 and `id` at 0, so more threads are runnable than there are cores: CPU saturation. Swap is idle (`si`/`so` 0), ruling out memory paging. More cores or less concurrency is the lever.

### Drill 4: df -h

Output:

```text
Filesystem      Size  Used Avail Use% Mounted on
tmpfs            20M   19M  1.0M  95% /mnt/small
/dev/root        20G  4.1G   15G  22% /
```

??? tip "What's wrong?"
    `/mnt/small` is 95% full with 1 MB free, so writes there will soon fail while the root filesystem is fine. If writes fail but `df` shows space, check `df -i` for inode exhaustion instead, covered in [Disk Usage](../12-storage/disk-usage.md) and [Disk Full](scenarios/disk-full.md).

### Drill 5: iostat -xz

Output:

```text
Device     r/s   rkB/s  r_await   w/s    wkB/s  w_await  aqu-sz  %util
vda     231.12 2284.38     0.49 1203.30 23021.31    2.64    3.29   7.57
```

??? tip "What's wrong?"
    Nothing on the disk: despite 23 MB/s of writes, `%util` is 7.57 and `w_await` is 2.64 ms, so the device is keeping up with room to spare. A slow application here is not disk-bound; look at CPU, locks or the network. A saturated disk instead shows `%util` near 100 with a high `aqu-sz` and `await`, covered in [Disk I/O](../17-performance-and-troubleshooting/disk-io.md).

### Drill 6: ss -tulpn

Output:

```text
Netid State  Recv-Q Send-Q Local Address:Port  Process
udp   UNCONN 0      0          127.0.0.1:323     users:(("chronyd",pid=840,fd=4))
udp   UNCONN 0      0            0.0.0.0:20048    users:(("rpc.mountd",pid=976,fd=4))
udp   UNCONN 0      0            0.0.0.0:111      users:(("rpcbind",pid=953,fd=6))
```

??? tip "What's reading this tell you?"
    The host is an NFS server: `rpc.mountd` and `rpcbind` are listening, and `chronyd` binds `323` on loopback only. A service reachable locally but not remotely often binds `127.0.0.1` instead of `0.0.0.0`; check the `Local Address` column, covered in [Ports and Sockets](../13-networking/ports-and-sockets.md) and [Service Unreachable](scenarios/service-unreachable.md).

### Drill 7: ps with a zombie

Output:

```text
   PID    PPID STAT COMMAND
   1592    1590 Z    python3
```

??? tip "What's wrong?"
    PID 1592 is a zombie (`Z`): it has exited but its parent (1590) has not reaped it with `wait`. A few zombies are harmless; many mean a buggy parent, and the fix is to signal or restart the parent, not the zombie. Killing a zombie does nothing because it is already dead, covered in [Process States](../07-processes/process-states.md).

---

## Related

- [Round 1: Screening](round-1-screening.md): the L1 questions that precede this round
- [Round 3: Troubleshooting](round-3-troubleshooting.md): unscripted symptoms and the scenario index
- [Methodology](../17-performance-and-troubleshooting/methodology.md): the 60-second checklist behind these reads
- [Process States](../07-processes/process-states.md): reading `R`, `S`, `D`, `Z`, `T`

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. Load, memory pressure and I/O were generated with `stress-ng` and `dd` for the drills.
