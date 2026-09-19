# sysctl

`sysctl` reads and writes the kernel parameters under `/proc/sys`, and `/etc/sysctl.d/` makes them persistent. Kubernetes, Elasticsearch, SonarQube and high-traffic web servers all require specific values, so setting one correctly, and knowing which file wins, is a common task.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Name mapping | `net.ipv4.ip_forward` is `/proc/sys/net/ipv4/ip_forward` | `cat /proc/sys/net/ipv4/ip_forward` |
| Read | `sysctl key`, `sysctl -a`, `sysctl -a --pattern <regex>` | `sysctl vm.swappiness` |
| Write now | `sysctl -w key=value` (root; lost at reboot) | `sysctl key` |
| Persistent | A file in `/etc/sysctl.d/` named `NN-name.conf`, then `sysctl --system` | `sysctl --system` |
| Load one file | `sysctl -p <file>`; `sysctl -p` alone reads `/etc/sysctl.conf` | `sysctl -p /etc/sysctl.d/90-app.conf` |
| Directories | `/etc/sysctl.d`, `/run/sysctl.d`, `/usr/lib/sysctl.d`; a file in `/etc` overrides one with the same name | `systemd-analyze cat-config sysctl.d/99-sysctl.conf` |
| Order | All files sorted by name; for the same key, the last file read wins | `sysctl --system` |
| `/etc/sysctl.conf` | Symlinked as `/etc/sysctl.d/99-sysctl.conf` on both families | `ls -l /etc/sysctl.d/99-sysctl.conf` |
| Boot | `systemd-sysctl.service` applies the files | `systemctl status systemd-sysctl` |
| Module keys | Keys appear only after their module loads (`net.sctp.*`, `net.bridge.*`) | `sysctl net.sctp.rto_min` |
| Namespaces | Most `net.*` keys are per network namespace; containers can have their own | `ip netns exec x sysctl net.ipv4.ip_forward` |
| Routing | `net.ipv4.ip_forward = 1` for routers, NAT, Kubernetes nodes | `sysctl net.ipv4.ip_forward` |
| Memory | `vm.swappiness`, `vm.overcommit_memory`, `vm.max_map_count`, `vm.dirty_ratio` | `sysctl -a --pattern ^vm` |
| Files and processes | `fs.file-max`, `fs.inotify.max_user_watches`, `kernel.pid_max` | `sysctl fs.file-nr` |
<!-- --8<-- [end:facts] -->

---

## Reading and Writing

```bash
sysctl vm.swappiness net.ipv4.ip_forward
cat /proc/sys/net/ipv4/ip_forward
sysctl -a 2>/dev/null | grep -c .; sysctl -a 2>/dev/null | cut -d. -f1 | sort | uniq -c
sysctl -w net.ipv4.ip_forward=1
```

Output:

```text
vm.swappiness = 60
net.ipv4.ip_forward = 0
0
1039
      1 abi
      2 debug
      4 dev
     66 fs
    128 kernel
    769 net
     12 sunrpc
     12 user
     45 vm
net.ipv4.ip_forward = 1
```

Most of the 1039 keys are under `net`, many of them repeated for each interface (`net.ipv4.conf.eth0.*`). The kernel checks each value, so non-root users and bad values fail:

```bash
su - laborant -c "sysctl -w vm.swappiness=10"
sysctl -w vm.swappiness=abc
sysctl -w vm.swappiness=300
sysctl -w net.ipv4.tcp_bogus=1
```

Output:

```text
sysctl: permission denied on key "vm.swappiness"
sysctl: setting key "vm.swappiness": Invalid argument
sysctl: setting key "vm.swappiness": Invalid argument
sysctl: cannot stat /proc/sys/net/ipv4/tcp_bogus: No such file or directory
```

`vm.swappiness` accepts 0 to 200, so 300 is rejected like a non-number.

---

## Making Values Persistent

Values set with `-w` disappear at reboot. A file in `/etc/sysctl.d/` is applied at every boot by `systemd-sysctl.service`, and `sysctl --system` applies all files now. As root:

```bash
printf "net.ipv4.ip_forward = 1\nvm.swappiness = 10\nvm.max_map_count = 524288\n" > /etc/sysctl.d/90-app.conf; sysctl -p /etc/sysctl.d/90-app.conf
printf "vm.swappiness = 30\n" > /etc/sysctl.d/95-db.conf; sysctl --system | grep -E "^\*|swappiness"
sysctl vm.swappiness
```

Output:

```text
net.ipv4.ip_forward = 1
vm.swappiness = 10
vm.max_map_count = 524288
* Applying /usr/lib/sysctl.d/10-default-yama-scope.conf ...
* Applying /usr/lib/sysctl.d/10-map-count.conf ...
* Applying /usr/lib/sysctl.d/50-coredump.conf ...
* Applying /usr/lib/sysctl.d/50-default.conf ...
* Applying /usr/lib/sysctl.d/50-pid-max.conf ...
* Applying /usr/lib/sysctl.d/50-redhat.conf ...
* Applying /etc/sysctl.d/90-app.conf ...
* Applying /etc/sysctl.d/95-db.conf ...
* Applying /etc/sysctl.d/99-sysctl.conf ...
* Applying /etc/sysctl.conf ...
vm.swappiness = 10
vm.swappiness = 30
vm.swappiness = 30
```

Two files set `vm.swappiness`; `95-db.conf` is read after `90-app.conf`, so 30 wins. The values survived the reboot of this host:

```bash
sysctl vm.swappiness net.ipv4.ip_forward vm.max_map_count
```

Output:

```text
vm.swappiness = 30
net.ipv4.ip_forward = 1
vm.max_map_count = 524288
```

!!! warning "A value in /etc/sysctl.conf can override your drop-in"
    `/etc/sysctl.d/99-sysctl.conf` is a symlink to `/etc/sysctl.conf`, and it sorts after most drop-ins. A leftover line there silently wins over `90-app.conf`; name drop-ins that must win `99-zz-name.conf` or clean `sysctl.conf`.

=== "RHEL / Rocky"

    ```bash
    ls /etc/sysctl.d /usr/lib/sysctl.d
    ls -l /etc/sysctl.conf /etc/sysctl.d/99-sysctl.conf
    ```

    Output:

    ```text
    /etc/sysctl.d:
    99-sysctl.conf

    /usr/lib/sysctl.d:
    10-default-yama-scope.conf
    10-map-count.conf
    50-coredump.conf
    50-default.conf
    50-pid-max.conf
    50-redhat.conf
    -rw-r--r-- 1 root root 449 Jun 10 00:00 /etc/sysctl.conf
    lrwxrwxrwx 1 root root  14 Jun 10 00:00 /etc/sysctl.d/99-sysctl.conf -> ../sysctl.conf
    ```

    The first listing was taken before `90-app.conf` and `95-db.conf` were added.

=== "Ubuntu / Debian"

    ```bash
    ls /usr/lib/sysctl.d /etc/sysctl.d; ls -l /etc/sysctl.d/99-sysctl.conf
    grep -v '^#' /etc/sysctl.d/10-kernel-hardening.conf | grep .; grep -v '^#' /etc/sysctl.d/10-map-count.conf | grep .
    ```

    Output:

    ```text
    /etc/sysctl.d:
    10-bufferbloat.conf
    10-console-messages.conf
    10-ipv6-privacy.conf
    10-kernel-hardening.conf
    10-magic-sysrq.conf
    10-map-count.conf
    10-network-security.conf
    10-ptrace.conf
    10-zeropage.conf
    99-sysctl.conf
    README.sysctl

    /usr/lib/sysctl.d:
    10-apparmor.conf
    50-bubblewrap.conf
    50-pid-max.conf
    99-protect-links.conf
    lrwxrwxrwx 1 root root 14 Jul 28 15:04 /etc/sysctl.d/99-sysctl.conf -> ../sysctl.conf
    kernel.kptr_restrict = 1
    vm.max_map_count=1048576
    ```

    Ubuntu ships its defaults in `/etc/sysctl.d/10-*.conf`; RHEL keeps them in `/usr/lib/sysctl.d/`, where package updates can replace them.

---

## Keys That Depend on a Module

A key belongs to the code that registers it. Until the module loads, `sysctl` cannot find it, and a `sysctl.d` file that sets it fails at boot.

```bash
sysctl net.sctp.rto_min
modprobe -v sctp
sysctl net.sctp.rto_min
```

Output:

```text
sysctl: cannot stat /proc/sys/net/sctp/rto_min: No such file or directory
insmod /lib/modules/6.1.167/kernel/net/sctp/sctp.ko 
net.sctp.rto_min = 1000
```

The best-known case is Kubernetes' `net.bridge.bridge-nf-call-iptables`, which needs `br_netfilter`. The playground kernel has `br_netfilter` built in, so the key exists from boot here; on RHEL and Ubuntu kernels it is a module, and the setup loads it through `/etc/modules-load.d/` before `sysctl --system` runs.

```bash
sysctl net.bridge.bridge-nf-call-iptables
modinfo br_netfilter | head -3
```

Output:

```text
net.bridge.bridge-nf-call-iptables = 1
name:           br_netfilter
filename:       (builtin)
description:    Linux ethernet netfilter firewall bridge
```

---

## Parameters Worth Knowing

```bash
sysctl vm.max_map_count kernel.pid_max fs.file-max fs.file-nr net.core.somaxconn net.ipv4.ip_local_port_range fs.inotify.max_user_watches vm.overcommit_memory kernel.panic
```

Output:

```text
vm.max_map_count = 524288
kernel.pid_max = 4194304
fs.file-max = 9223372036854775807
fs.file-nr = 1408	0	9223372036854775807
net.core.somaxconn = 4096
net.ipv4.ip_local_port_range = 32768	60999
fs.inotify.max_user_watches = 63259
vm.overcommit_memory = 0
kernel.panic = 1
```

| Key | Why it is changed |
|---|---|
| `net.ipv4.ip_forward` | Routing, NAT, VPN gateways, Kubernetes and Docker hosts |
| `net.bridge.bridge-nf-call-iptables` | Kubernetes: bridged pod traffic must pass iptables |
| `vm.max_map_count` | Elasticsearch and OpenSearch need at least 262144, SonarQube 524288; the kernel default is 65530 |
| `vm.swappiness` | Lower on database hosts to keep memory in RAM |
| `vm.overcommit_memory` | Redis recommends 1; 2 enforces strict accounting |
| `fs.file-max` | System-wide file handle limit (already huge on 64-bit kernels) |
| `fs.inotify.max_user_watches` | IDEs, file sync tools and kubelet on busy nodes |
| `net.core.somaxconn` | Upper limit for listen backlogs on busy servers |
| `net.ipv4.ip_local_port_range` | More source ports for many outbound connections |
| `kernel.panic` | Seconds before an automatic reboot after a panic (`1` here) |
| `kernel.pid_max` | Hosts with very many processes or threads |

`vm.max_map_count` shows 524288 because `90-app.conf` set it. Both Rocky 10.2 and Ubuntu 24.04 already raise it to 1048576 in `10-map-count.conf`, so this drop-in lowered the limit:

```bash
grep -v '^#' /usr/lib/sysctl.d/10-map-count.conf
```

Output:

```text
vm.max_map_count=1048576
```

!!! tip "Check the current value before writing a drop-in"
    A copied setup guide can lower a value the distribution already raised, as happened here. Run `sysctl <key>` first, and add a comment above each line (`# SonarQube: embedded Elasticsearch`) that says why it exists.

---

## Common Errors

### `sysctl: permission denied on key "vm.swappiness"`

**Cause:** Writing requires root.

**Fix:** `sudo sysctl -w vm.swappiness=10`.

### `sysctl: setting key "vm.swappiness": Invalid argument`

**Cause:** The value is not a number or is out of range for that key.

**Fix:** Check the valid range in the kernel documentation (`Documentation/admin-guide/sysctl/`).

### `sysctl: cannot stat /proc/sys/net/sctp/rto_min: No such file or directory`

**Cause:** The key is misspelled, or its module is not loaded.

**Fix:** `sysctl -a --pattern <part>` to find the name; load the module and list it in `/etc/modules-load.d/`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How do you change a kernel parameter now, and how do you make it permanent?"
    **Say first:** `sysctl -w` changes it now; a file in `/etc/sysctl.d/` plus `sysctl --system` makes it permanent.

    **Proof:** `sudo sysctl -w net.ipv4.ip_forward=1`; `echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/90-forward.conf`.

    **Follow-up:** Which service applies the file at boot?

??? question "L1: What does net.ipv4.ip_forward do, and when must it be 1?"
    **Say first:** It lets the kernel route packets between interfaces; routers, NAT gateways, VPN servers and container or Kubernetes hosts need it.

    **Proof:** `sysctl net.ipv4.ip_forward`

    **Follow-up:** What breaks for containers when it is 0?
<!-- --8<-- [end:l1] -->

??? question "L2: Two files set the same key to different values. Which wins, and how do you check?"
    **Say first:** The file read last, in name order across the sysctl directories.

    **Proof:** `sysctl --system | grep -E "^\*|swappiness"` shows the order and each value.

    **Follow-up:** How does `/etc/sysctl.conf` fit into that order?

??? question "L2: Prepare a host for SonarQube or Elasticsearch."
    **Say first:** Raise `vm.max_map_count` to at least 262144 persistently, and the file descriptor limit for the service.

    **Proof:** `echo "vm.max_map_count = 524288" | sudo tee /etc/sysctl.d/90-sonarqube.conf`; `sudo sysctl --system`; `LimitNOFILE=` in the unit.

    **Follow-up:** How does this change inside a container? (It is a host setting; the container cannot set it.)

??? question "L2: List all keys related to TCP keepalive and their values."
    **Say first:** Filter `sysctl -a` with a pattern.

    **Proof:** `sysctl -a --pattern keepalive`

    **Follow-up:** Which one sets the idle time before the first probe? (`net.ipv4.tcp_keepalive_time`.)

??? question "L3: A Kubernetes node setup script fails with cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables. Why?"
    **Say first:** The `br_netfilter` module is not loaded, so the key does not exist yet.

    **Proof:** `lsmod | grep br_netfilter`; `sudo modprobe br_netfilter`; `echo br_netfilter | sudo tee /etc/modules-load.d/k8s.conf`.

    **Follow-up:** Why must the module also load at boot before `systemd-sysctl` runs?

??? question "L3: A value set in /etc/sysctl.d/90-app.conf is correct in the file but wrong on the running host after reboot. What do you check?"
    **Say first:** A later file overriding it, a service or script changing it after boot, or a key that did not exist when the file was applied.

    **Proof:** `sysctl --system | grep -E "^\*|<key>"`; `grep -r <key> /etc/sysctl.conf /etc/sysctl.d /usr/lib/sysctl.d /run/sysctl.d`; `journalctl -b -u systemd-sysctl`.

    **Follow-up:** Which tool can also change values at runtime on RHEL? (`tuned` profiles.)

---

## Related

- [proc and sys](proc-and-sys.md): the files behind the keys
- [Kernel Modules](kernel-modules.md): keys that appear with a module
- [Writing a Service](../08-systemd-and-services/writing-a-service.md): per-service limits

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
