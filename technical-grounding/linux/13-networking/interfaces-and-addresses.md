# Interfaces and Addresses

A network interface is the kernel's handle for a link (a NIC, a bridge, a tunnel or loopback), and each interface carries zero or more IP addresses. `ip` from `iproute2` reads and changes both, and is the first command in any network investigation.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Tool | `ip` (iproute2) replaced `ifconfig`, `route` and `arp` (net-tools); net-tools may be absent | `ip -br addr` |
| Link vs address | `ip link` is layer 2 (state, MAC, MTU); `ip addr` is layer 3 | `ip -br link` |
| State flags | `UP` = administratively up; `LOWER_UP` = carrier present | `ip link show eth0` |
| Predictable names | `enp0s3` (PCI path), `ens3` (slot), `eno1` (onboard), `enx<MAC>`; `net.ifnames=0` keeps `eth0` | `udevadm test-builtin net_id /sys/class/net/eth0` |
| Loopback | `lo`, `127.0.0.1/8` and `::1`; traffic never leaves the host | `ip addr show lo` |
| Link-local IPv6 | `fe80::/64`, created on every IPv6-enabled link; derived from the MAC unless privacy addresses are on | `ip -6 addr` |
| Runtime only | `ip addr add` and `ip link set` are lost at reboot; persistence lives in NetworkManager or netplan | `ip -br addr` after a reboot |
| Connected route | Adding `10.0.0.1/24` to an up link adds the route `10.0.0.0/24` | `ip route show dev <if>` |
| ARP / neighbor | IPv4 to MAC cache; states `REACHABLE`, `STALE`, `DELAY`, `INCOMPLETE`, `FAILED` | `ip neigh` |
| Counters | Errors and drops per interface | `ip -s link show eth0` |
| Driver and speed | `ethtool eth0` (speed, duplex, link), `ethtool -i` (driver), `ethtool -S` (NIC counters) | `sudo ethtool eth0` |
| MTU | Default 1500; jumbo frames 9000; tunnels and cloud overlays often lower | `ip link show eth0` |
| sysfs | `/sys/class/net/<if>/` holds `address`, `mtu`, `carrier`, `statistics/` | `cat /sys/class/net/eth0/mtu` |
<!-- --8<-- [end:facts] -->

---

## Listing Interfaces and Addresses

The lab router `gw` (Rocky Linux) has one leg on the `lan` network and one on `dmz`. `-br` prints one line per interface:

```bash
ip -br link
ip -br addr
```

Output:

```text
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0             UP             02:00:ac:10:00:03 <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1             UP             02:00:ac:10:01:02 <BROADCAST,MULTICAST,UP,LOWER_UP> 
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             172.16.0.3/24 fe80::acff:fe10:3/64 
eth1             UP             172.16.1.2/24 fe80::acff:fe10:102/64 
```

MAC addresses on this page are replaced with placeholders; the IPv6 link-local addresses are derived from the placeholder MAC in the same way the kernel derives them from the real one.

```bash
ip addr show eth1
```

Output:

```text
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 02:00:ac:10:01:02 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    altname ens3
    altname enx0200ac100102
    inet 172.16.1.2/24 brd 172.16.1.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::acff:fe10:102/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
```

| Field | Meaning |
|---|---|
| `3:` | Interface index |
| `<...UP,LOWER_UP>` | Admin up, carrier detected; `NO-CARRIER` means a cable or virtual link is down |
| `mtu 1500` | Largest IP packet the link sends without fragmenting |
| `qdisc fq_codel` | Queueing discipline for outgoing packets |
| `link/ether` | MAC address and broadcast MAC |
| `altname` | Predictable names kept as aliases |
| `inet ... scope global` | IPv4 address with prefix length; `brd` is the broadcast address |
| `valid_lft forever` | Static address; a DHCP lease shows seconds remaining |

`ifconfig` still runs where `net-tools` is installed (both playgrounds have it), and prints `netmask 255.255.255.0` instead of `/24`. It hides secondary addresses:

```bash
sudo ip addr add 172.16.1.20/24 dev eth1
ifconfig eth1 | head -3
sudo ip addr del 172.16.1.20/24 dev eth1
```

Output:

```text
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.16.1.2  netmask 255.255.255.0  broadcast 172.16.1.255
        inet6 fe80::acff:fe10:102  prefixlen 64  scopeid 0x20<link>
```

`172.16.1.20` is missing, because the old ioctl interface returns one IPv4 address per interface name.

| net-tools | iproute2 |
|---|---|
| `ifconfig` | `ip addr`, `ip -s link` |
| `ifconfig eth0 up` | `ip link set eth0 up` |
| `route -n` | `ip route` |
| `arp -n` | `ip neigh` |
| `netstat -tulpn` | `ss -tulpn` |

---

## Interface Names

This playground boots with `net.ifnames=0`, so the kernel names stay `eth0` and `eth1`. udev still computes the predictable names and attaches them as `altname`:

```bash
cat /proc/cmdline | grep -o 'net.ifnames=0'
udevadm test-builtin net_id /sys/class/net/eth1 2>/dev/null
```

Output:

```text
net.ifnames=0
ID_NET_NAMING_SCHEME=rhel-10.0
ID_NET_NAME_MAC=enx0200ac100102
ID_NET_NAME_PATH=enp0s3
ID_NET_NAME_SLOT=ens3
```

Without that parameter, systemd picks the first available name in the order onboard (`eno1`), slot (`ens3`), path (`enp0s3`). The naming scheme is versioned (`rhel-10.0` here, `v255` on Ubuntu 24.04), so a distribution upgrade can rename an interface and break a configuration that matches by name.

!!! warning "A renamed interface leaves the server offline"
    Configuration that matches `eth0` stops applying when the NIC becomes `ens3` after a move to new hardware, a new hypervisor or a changed naming scheme. Match by MAC address (`match: macaddress:` in netplan, `802-3-ethernet.mac-address` in NetworkManager) on servers that move.

---

## Adding and Removing Addresses

```bash
sudo ip addr add 172.16.1.20/24 dev eth1
ip -br addr show eth1
ping -c1 -W1 -I 172.16.1.20 172.16.1.3 | head -2
sudo ip addr del 172.16.1.20/24 dev eth1
```

Output:

```text
eth1             UP             172.16.1.2/24 172.16.1.20/24 fe80::acff:fe10:102/64 
PING 172.16.1.3 (172.16.1.3) 56(84) bytes of data.
64 bytes from 172.16.1.3: icmp_seq=1 ttl=64 time=0.173 ms
```

The second address works at once and `-I` picked it as the source. Nothing was written to disk, so a reboot or a NetworkManager reapply removes it; [Network Configuration](network-configuration.md) makes addresses permanent.

A dummy interface shows how link state controls routes. The MAC is set explicitly so the output is stable:

```bash
sudo ip link add lab0 address 02:00:00:00:99:01 type dummy
sudo ip addr add 10.99.0.1/24 dev lab0
ip -br addr show lab0
ip route show dev lab0
sudo ip link set lab0 up
ip -br addr show lab0
ip route show dev lab0
sudo ip link set lab0 mtu 9000
ip link show lab0
sudo ip link del lab0
```

Output:

```text
lab0             DOWN           10.99.0.1/24 
lab0             UNKNOWN        10.99.0.1/24 fe80::ff:fe00:9901/64 
10.99.0.0/24 proto kernel scope link src 10.99.0.1 
6: lab0: <BROADCAST,NOARP,UP,LOWER_UP> mtu 9000 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether 02:00:00:00:99:01 brd ff:ff:ff:ff:ff:ff
```

While the link was down, the address existed but the connected route `10.99.0.0/24` did not. Bringing it up added the route and an IPv6 link-local address built from the MAC (`02:00:00` becomes `00:00:00` with `ff:fe` inserted). Virtual devices without a carrier concept report `UNKNOWN`, which is normal for `lo` and dummies.

---

## Neighbors and ARP

Before sending to an address on the local subnet, the kernel resolves its MAC with ARP (IPv4) or neighbor discovery (IPv6). On the Ubuntu `client`:

```bash
ping -c1 -W1 172.16.0.3 | tail -1
ip neigh show dev eth0
ping -c1 -W1 172.16.0.99 | head -3
ip neigh show 172.16.0.99
sleep 3; ip neigh show 172.16.0.99
sudo arping -c2 -I eth0 172.16.0.3
```

Output:

```text
rtt min/avg/max/mdev = 0.193/0.193/0.193/0.000 ms
172.16.0.1 lladdr 02:00:ac:10:00:01 STALE 
172.16.0.3 lladdr 02:00:ac:10:00:03 DELAY 
PING 172.16.0.99 (172.16.0.99) 56(84) bytes of data.

--- 172.16.0.99 ping statistics ---
172.16.0.99 dev eth0 INCOMPLETE 
172.16.0.99 dev eth0 FAILED 
ARPING 172.16.0.3 from 172.16.0.2 eth0
Unicast reply from 172.16.0.3 [02:00:AC:10:00:03]  0.682ms
Unicast reply from 172.16.0.3 [02:00:AC:10:00:03]  0.641ms
Sent 2 probes (1 broadcast(s))
Received 2 response(s)
```

| State | Meaning |
|---|---|
| `REACHABLE` | Confirmed recently |
| `STALE` | Known but unconfirmed; the next packet triggers `DELAY` and a probe |
| `INCOMPLETE` | Request sent, no answer yet |
| `FAILED` | No answer; nothing owns the address on this link |

A `FAILED` entry for the default gateway means the host cannot leave its subnet at all. When nothing answers ARP, `ping` reports the error locally after about three seconds:

```bash
ping -c5 172.16.0.97
```

Output:

```text
PING 172.16.0.97 (172.16.0.97) 56(84) bytes of data.
From 172.16.0.2 icmp_seq=1 Destination Host Unreachable
From 172.16.0.2 icmp_seq=2 Destination Host Unreachable
# ... (trimmed)
5 packets transmitted, 0 received, +5 errors, 100% packet loss, time 4099ms
pipe 4
```

`From 172.16.0.2`, the host's own address, shows that the failure is local ARP, not a remote router.

!!! tip "Duplicate IP addresses show up in arping"
    `arping -D -I eth0 <ip>` exits non-zero when another host already answers for the address. Two different MACs replying to a plain `arping` for one IP is the classic sign of an address conflict.

---

## Link Health and Drivers

```bash
ip -s link show eth1
sudo ethtool eth1 | grep -E 'Speed|Duplex|Link detected'
ethtool -i eth1 | head -1
```

Output:

```text
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 02:00:ac:10:01:02 brd ff:ff:ff:ff:ff:ff
    RX:  bytes packets errors dropped  missed   mcast           
          3576      48      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
          1828      26      0       0       0       0 
    altname enp0s3
    altname ens3
    altname enx0200ac100102
	Speed: Unknown!
	Duplex: Unknown! (255)
	Link detected: yes
driver: virtio_net
```

A `virtio_net` NIC has no physical speed, so `Unknown!` is expected in a VM. On hardware, a link at `100Mb/s` or `Half` duplex on a gigabit port points to a cable or switch-port problem, and rising `errors` or `dropped` counters point to the NIC, the driver or a full receive ring (`ethtool -g`). Without `sudo`, `ethtool` prints `netlink error: Operation not permitted` before the partial output.

---

## Common Errors

### `RTNETLINK answers: File exists`

**Cause:** the address (or route) is already present on the interface.

**Fix:** check with `ip -br addr`; use `ip addr replace` for an idempotent change.

### `Cannot find device "eth9"`

**Cause:** the interface name is wrong, or the system uses predictable names.

**Fix:** `ip -br link` lists the real names, including `altname` aliases.

### `RTNETLINK answers: Operation not permitted`

**Cause:** changing links, addresses or routes needs `CAP_NET_ADMIN`.

**Fix:** run the command with `sudo`.

### `From 172.16.0.2 icmp_seq=1 Destination Host Unreachable`

**Cause:** the target (or the gateway) on the local subnet does not answer ARP.

**Fix:** `ip neigh` shows `FAILED`; check that the host is up, on the same VLAN, and that the prefix length is right.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between UP and LOWER_UP on an interface?"
    **Say first:** `UP` means an administrator enabled the interface; `LOWER_UP` means the driver sees a carrier, so the physical or virtual link is connected.

    **Proof:** `ip link show eth0`; a pulled cable shows `NO-CARRIER` with `UP` still set.

    **Follow-up:** Why does a dummy interface report `state UNKNOWN`?

??? question "L1: Why did ifconfig give way to ip?"
    **Say first:** `ip` uses netlink and shows everything the kernel supports (multiple addresses, policy routing, tunnels, namespaces); net-tools used old ioctls and is no longer developed.

    **Proof:** `ip addr add` a second address; `ifconfig` shows only the primary one.

    **Follow-up:** Which `ip` commands replace `route -n` and `arp -n`?
<!-- --8<-- [end:l1] -->

??? question "L2: Add a second IP address to eth1 for a test, then remove it."
    **Say first:** `ip addr add` with the prefix length, and `ip addr del` with the same value.

    **Proof:** `sudo ip addr add 172.16.1.20/24 dev eth1; ip -br addr show eth1; sudo ip addr del 172.16.1.20/24 dev eth1`.

    **Follow-up:** Why is the address gone after a reboot?

??? question "L2: Show the MAC address of the default gateway."
    **Say first:** read the gateway from the routing table, then look it up in the neighbor table.

    **Proof:** `ip route show default`; `ip neigh show 172.16.0.1`.

    **Follow-up:** What does `STALE` mean for that entry?

??? question "L2: Find out whether a NIC is dropping packets."
    **Say first:** read the interface counters, then the driver counters.

    **Proof:** `ip -s link show eth0`; `sudo ethtool -S eth0 | grep -i drop`; `sudo ethtool -g eth0` for ring sizes.

    **Follow-up:** How do you tell NIC drops from drops in the firewall or socket buffers?

??? question "L2: What name would eth1 get without net.ifnames=0, and why does it matter?"
    **Say first:** udev computes it from firmware, slot and PCI path; `udevadm test-builtin net_id` prints the candidates.

    **Proof:** `udevadm test-builtin net_id /sys/class/net/eth1` shows `ens3` and `enp0s3`.

    **Follow-up:** How do you keep a configuration working across a rename?

??? question "L3: A freshly cloned VM has an IP address but cannot ping anything on its subnet. What do you check?"
    **Say first:** check the link and carrier, the prefix length, the neighbor table and whether another host already uses the address or MAC.

    **Proof:** `ip -br link`; `ip -br addr`; `ip neigh` shows `FAILED`; `arping -D -I eth0 <ip>`; compare MACs with the source VM.

    **Follow-up:** Which other identifiers must be reset on a clone? (Machine ID, SSH host keys, DHCP client ID.)

??? question "L3: After replacing a network card, the server comes up without network. Why?"
    **Say first:** the new NIC got a different name or MAC, so the saved configuration no longer matches any interface.

    **Proof:** `ip -br link` shows the new name; `nmcli -f NAME,DEVICE con` shows the profile bound to nothing; `journalctl -b -u NetworkManager`.

    **Follow-up:** How would you match the configuration so this cannot happen?

---

## Related

- [Network Configuration](network-configuration.md): making addresses permanent
- [Routing](routing.md): what happens after the address is set
- [Devices and udev](../11-kernel-and-hardware/devices-and-udev.md): how udev names devices
- [MAC and ARP](../../networking/mac-and-arp.md): the protocol background

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 (iximiuz Labs FlexBox microVMs, kernel 6.1.167; iproute2 6.17 on Rocky, 6.1 on Ubuntu), 2026-09. MAC addresses are replaced with placeholders.
