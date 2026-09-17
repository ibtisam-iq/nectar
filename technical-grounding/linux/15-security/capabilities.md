# Capabilities

Linux capabilities split root's power into about 40 separate privileges, such as binding ports below 1024 (`CAP_NET_BIND_SERVICE`) or changing file owners (`CAP_CHOWN`). Programs and services get only the ones they need, which replaces many setuid binaries and root-run daemons.

**Track:** Advanced · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Process sets | Effective (checked now), Permitted (may enable), Inheritable, Bounding (upper limit), Ambient (kept across `execve` for non-root) | `grep Cap /proc/self/status` |
| Root | A root process has all capabilities in its effective set; a normal user has none | `sudo grep CapEff /proc/self/status` |
| Decode | `capsh --decode=HEX` turns a mask into names | `capsh --decode=0000000000000400` |
| File capabilities | Stored in the `security.capability` extended attribute; `setcap cap_x=+ep FILE` | `getcap FILE` |
| Copies | `cp` without `--preserve=xattr` drops file capabilities; so does rewriting the file | `getcap` on the copy |
| Low ports | Ports below `net.ipv4.ip_unprivileged_port_start` (1024) need `CAP_NET_BIND_SERVICE` | `sysctl net.ipv4.ip_unprivileged_port_start` |
| ping | Ubuntu: file capability `cap_net_raw`; RHEL: unprivileged ICMP sockets via `net.ipv4.ping_group_range` | `getcap /usr/bin/ping` |
| systemd | `AmbientCapabilities=` grants, `CapabilityBoundingSet=` limits; `User=` alone drops everything | `systemctl show -p CapabilityBoundingSet UNIT` |
| Dropping | `capsh --drop=cap_x -- -c CMD` runs a command without that capability, even as root | `sudo capsh --print` |
| Containers | Docker keeps 14 capabilities by default; `--cap-drop ALL --cap-add NET_BIND_SERVICE` is the least-privilege pattern | `docker inspect` |
| Dangerous ones | `CAP_SYS_ADMIN` (mount, many admin calls), `CAP_SYS_PTRACE`, `CAP_DAC_OVERRIDE`, `CAP_SETUID` are almost root | `man 7 capabilities` |
<!-- --8<-- [end:facts] -->

---

## Reading Capability Sets

A shell run by `laborant` on `client` (Ubuntu 24.04) has no effective capabilities; the same command under `sudo` has all of them. The bounding set limits what either can ever gain.

```bash
grep Cap /proc/self/status
sudo grep Cap /proc/self/status
capsh --decode=000001ffffffffff | tr ',' '\n' | head -5
capsh --decode=000001ffffffffff | tr ',' '\n' | wc -l
```

Output:

```text
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	000001ffffffffff
CapAmb:	0000000000000000
CapInh:	0000000000000000
CapPrm:	000001ffffffffff
CapEff:	000001ffffffffff
CapBnd:	000001ffffffffff
CapAmb:	0000000000000000
0x000001ffffffffff=cap_chown
cap_dac_override
cap_dac_read_search
cap_fowner
cap_fsetid
41
```

Kernel 6.1 knows 41 capabilities, one bit each. Root is powerful because its effective set is full, and removing one bit removes that power even for root:

```bash
sudo touch /tmp/owned-by-root
sudo capsh --drop=cap_chown -- -c 'chown laborant /tmp/owned-by-root'; echo "exit=$?"
sudo capsh --drop=cap_chown -- -c 'grep CapEff /proc/self/status'
```

Output:

```text
chown: changing ownership of '/tmp/owned-by-root': Operation not permitted
exit=1
CapEff:	000001fffffffffe
```

Bit 0 (`cap_chown`) is cleared in the last line.

---

## How ping Works Without setuid

=== "RHEL / Rocky"

    ```bash
    getcap /usr/bin/ping; echo "getcap exit=$?"
    sysctl net.ipv4.ping_group_range
    ```

    Output:

    ```text
    getcap exit=0
    net.ipv4.ping_group_range = 0	2147483647
    ```

    `ping` has no capability. The sysctl lets every group (0 to 2147483647) open unprivileged ICMP sockets.

=== "Ubuntu / Debian"

    ```bash
    getcap /usr/bin/ping
    ls -l /usr/bin/ping
    sysctl net.ipv4.ping_group_range
    ```

    Output:

    ```text
    /usr/bin/ping cap_net_raw=ep
    -rwxr-xr-x 1 root root 89800 Jul 24  2025 /usr/bin/ping
    net.ipv4.ping_group_range = 1	0
    ```

    The empty group range (1 to 0) disables ICMP sockets, so `ping` gets `cap_net_raw` from the file instead of a setuid bit.

---

## File Capabilities for One Binary

An unprivileged user cannot listen on port 99. A copy of `nc` with `cap_net_bind_service` can, without any other root power:

```bash
nc -l 99; echo "exit=$?"
sudo cp /usr/bin/nc.openbsd /usr/local/bin/nc-lowport
sudo setcap cap_net_bind_service=+ep /usr/local/bin/nc-lowport
getcap /usr/local/bin/nc-lowport
timeout 2 /usr/local/bin/nc-lowport -l 99 & sleep 0.5; ss -tlnp 'sport = :99'; wait
cp /usr/local/bin/nc-lowport /tmp/nc-copy; getcap /tmp/nc-copy; echo "getcap on the copy: exit=$?"
sysctl net.ipv4.ip_unprivileged_port_start
```

Output:

```text
nc: Permission denied
exit=1
/usr/local/bin/nc-lowport cap_net_bind_service=ep
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      1            0.0.0.0:99        0.0.0.0:*          
getcap on the copy: exit=0
net.ipv4.ip_unprivileged_port_start = 1024
```

`+ep` sets the capability as permitted and effective when the file runs. The copy printed nothing for `getcap`: the capability lived in an extended attribute that `cp` did not copy.

!!! warning "A file capability is a privilege on everything that binary can do"
    Giving `cap_net_bind_service` to a general tool such as `nc` or `python3` lets every user of that file bind low ports. Grant capabilities to the service instead (next section), or to a dedicated binary that only root can replace.

---

## Capabilities for a systemd Service

On `web` (Rocky Linux 10.2), a unit runs `ncat` on port 99 as the user `deploy`. `User=` starts the process with no capabilities, so the bind fails:

```bash
sudo tee /etc/systemd/system/lab-lowport.service >/dev/null <<'EOF'
[Unit]
Description=Lab listener on port 99 as an unprivileged user

[Service]
User=deploy
ExecStart=/usr/bin/ncat -lk 99
EOF
sudo systemctl daemon-reload
sudo systemctl start lab-lowport; sleep 1
systemctl is-active lab-lowport
sudo journalctl -u lab-lowport -o cat | head -4
```

Output:

```text
failed
Started lab-lowport.service - Lab listener on port 99 as an unprivileged user.
Ncat: bind to :::99: Permission denied. QUITTING.
lab-lowport.service: Main process exited, code=exited, status=2/INVALIDARGUMENT
lab-lowport.service: Failed with result 'exit-code'.
```

A drop-in grants the one capability through the ambient set and removes everything else from the bounding set:

```bash
sudo mkdir -p /etc/systemd/system/lab-lowport.service.d
printf '[Service]\nAmbientCapabilities=CAP_NET_BIND_SERVICE\nCapabilityBoundingSet=CAP_NET_BIND_SERVICE\n' | sudo tee /etc/systemd/system/lab-lowport.service.d/caps.conf >/dev/null
sudo systemctl daemon-reload
sudo systemctl restart lab-lowport; sleep 1
systemctl is-active lab-lowport
PID=$(systemctl show -p MainPID --value lab-lowport)
grep -E 'CapEff|CapBnd|CapAmb' /proc/$PID/status
capsh --decode=0000000000000400
sudo ss -tlnp 'sport = :99'
```

Output:

```text
active
CapEff:	0000000000000400
CapBnd:	0000000000000400
CapAmb:	0000000000000400
0x0000000000000400=cap_net_bind_service
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                         
LISTEN 0      10           0.0.0.0:99        0.0.0.0:*    users:(("ncat",pid=93287,fd=4))
LISTEN 0      10              [::]:99           [::]:*    users:(("ncat",pid=93287,fd=3))
```

Daemons that start as root often drop to a user and keep what they need. `chronyd` on the same host runs as `chrony` with two capabilities:

```bash
grep -E 'CapEff' /proc/$(pgrep -x chronyd)/status
capsh --decode=$(awk '/CapEff/ {print $2}' /proc/$(pgrep -x chronyd)/status)
ps -o user,pid,comm -C chronyd
```

Output:

```text
CapEff:	0000000002000400
0x0000000002000400=cap_net_bind_service,cap_sys_time
USER         PID COMMAND
chrony       850 chronyd
```

!!! tip "Audit services for capability sets"
    `grep CapEff /proc/*/status` with `capsh --decode` shows which processes still hold broad masks such as `000001ffffffffff`. `systemd-analyze security UNIT` scores a unit's sandboxing, including its capability bounding set.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are Linux capabilities, and why do they exist?"
    **Say first:** they split root's privileges into separate bits, so a process gets only the ones it needs instead of full root.

    **Proof:** `sudo capsh --drop=cap_chown -- -c 'chown ...'` failed even as root.

    **Follow-up:** Which capabilities are nearly equal to root?

??? question "L1: How does ping send ICMP without being setuid root?"
    **Say first:** on Ubuntu it carries the file capability `cap_net_raw`; on RHEL it uses unprivileged ICMP sockets allowed by `net.ipv4.ping_group_range`.

    **Proof:** `getcap /usr/bin/ping`; `sysctl net.ipv4.ping_group_range`.

    **Follow-up:** Why is a file capability safer than setuid root?
<!-- --8<-- [end:l1] -->

??? question "L2: Let a service running as a normal user listen on port 443."
    **Say first:** grant `CAP_NET_BIND_SERVICE` in the unit, not on a shared binary.

    **Proof:** `AmbientCapabilities=CAP_NET_BIND_SERVICE` and `CapabilityBoundingSet=CAP_NET_BIND_SERVICE`; `grep CapEff /proc/PID/status` shows `0000000000000400`.

    **Follow-up:** What are the alternatives (sysctl, a proxy, socket activation)?

??? question "L2: Read a process's capabilities and decode them."
    **Say first:** read the masks from `/proc/PID/status` and decode with `capsh`.

    **Proof:** `grep CapEff /proc/$(pgrep -x chronyd)/status`; `capsh --decode=0000000002000400` prints `cap_net_bind_service,cap_sys_time`.

    **Follow-up:** Which set does the kernel check at the moment of a system call?

??? question "L3: A binary with setcap worked yesterday; after a deployment it gets Permission denied binding port 99. What happened?"
    **Say first:** the deployment replaced or copied the file, and the capability in its extended attribute was lost.

    **Proof:** `getcap` on the new file prints nothing; `cp` did the same in the capture; reapply `setcap` in the deployment, or move the grant into the systemd unit.

    **Follow-up:** Which filesystems or mounts ignore file capabilities?

??? question "L4: A container runs as root. Why can it not mount a filesystem or load a kernel module?"
    **Say first:** the runtime drops most capabilities from the bounding set, so the root user inside lacks `CAP_SYS_ADMIN` and `CAP_SYS_MODULE`.

    **Proof:** `grep CapBnd /proc/1/status` inside the container shows a reduced mask; `capsh --decode` lists the default set.

    **Don't say:** root in a container is the same as root on the host.

---

## Related

- [Special Permissions](../05-permissions/special-permissions.md): setuid, the older way to grant privilege
- [Writing a Service](../08-systemd-and-services/writing-a-service.md): other systemd hardening directives
- [AppArmor](apparmor.md): profiles that restrict capabilities further

Captured on Ubuntu 24.04.4 (libcap 2.66) and Rocky Linux 10.2 on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
