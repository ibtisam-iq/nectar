# Bridges, Bonds and VLANs

A bridge is a software switch that joins interfaces into one layer 2 segment, a bond combines NICs for redundancy or throughput, and a VLAN interface tags traffic so one cable carries several networks. Containers, VMs and servers with redundant uplinks use all three.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Bridge | Learns MAC addresses per port (forwarding database); `docker0` and `cni0` are bridges | `bridge fdb show` |
| veth pair | Two linked interfaces; one end in a container namespace, the other on a bridge | `ip -br link type veth` |
| Bond modes | 0 balance-rr, 1 active-backup, 2 balance-xor, 4 802.3ad (LACP, needs switch support), 5/6 adaptive; `miimon` polls link state | `cat /proc/net/bonding/bond0` |
| Teaming | `teamd` deprecated in RHEL 9 and absent from RHEL 10 repositories; use bonding | `dnf list teamd` |
| VLAN | 802.1Q tag with a 12-bit ID (1 to 4094); interface name `eth0.10` by convention | `ip -d link show eth0.10` |
| Persistence | NetworkManager `type bridge`, `bond`, `vlan` profiles; netplan `bridges:`, `bonds:`, `vlans:` | `nmcli con show` |
<!-- --8<-- [end:facts] -->

---

## A Bridge with Two Hosts

Two network namespaces (`h1`, `h2`) stand in for containers; each gets a veth pair whose outer end joins `br-lab` on `gw`:

```bash
sudo ip netns add h1; sudo ip netns add h2; sudo ip link add br-lab type bridge
sudo ip link add v1 type veth peer name eth0 netns h1; sudo ip link add v2 type veth peer name eth0 netns h2
sudo ip link set v1 master br-lab; sudo ip link set v2 master br-lab
sudo ip link set br-lab up; sudo ip link set v1 up; sudo ip link set v2 up
sudo ip -n h1 addr add 10.50.0.1/24 dev eth0; sudo ip -n h1 link set eth0 up
sudo ip -n h2 addr add 10.50.0.2/24 dev eth0; sudo ip -n h2 link set eth0 up
sleep 2; sudo ip netns exec h1 ping -c2 10.50.0.2 | tail -1
bridge fdb show br br-lab | grep -v permanent
```

Output:

```text
rtt min/avg/max/mdev = 0.049/0.051/0.053/0.002 ms
02:00:41:19:a5:5a dev v1 master br-lab 
02:00:de:e9:3b:f0 dev v2 master br-lab 
```

!!! note "A bridge does not need an IP address"
    The bridge learned each namespace's MAC on the port it came from and forwards frames at layer 2, which is the wiring of Docker's default network. It needs an address only when the host itself talks on that segment, as `docker0` does as the containers' gateway.

---

## A VLAN Interface

```bash
sudo ip -n h1 link add link eth0 name eth0.10 type vlan id 10; sudo ip -n h2 link add link eth0 name eth0.10 type vlan id 10
sudo ip -n h1 addr add 10.60.0.1/24 dev eth0.10; sudo ip -n h1 link set eth0.10 up
sudo ip -n h2 addr add 10.60.0.2/24 dev eth0.10; sudo ip -n h2 link set eth0.10 up
sleep 1; sudo ip netns exec h1 ping -c1 10.60.0.2 | tail -1
sudo ip -n h1 -d link show eth0.10 | grep -o 'vlan protocol [^ ]* id [0-9]*'
```

Output:

```text
rtt min/avg/max/mdev = 0.051/0.051/0.051/0.000 ms
vlan protocol 802.1Q id 10
```

`sudo tcpdump -eni v2 vlan` on the bridge port shows the frames with `ethertype 802.1Q (0x8100)` and `vlan 10`. On a real server, the switch port must be a trunk that allows the VLAN, or tagged frames are dropped.

---

## An Active-Backup Bond

```bash
sudo ip link add bond0 type bond mode active-backup miimon 100
sudo ip link add dum1 type dummy; sudo ip link add dum2 type dummy
sudo ip link set dum1 master bond0; sudo ip link set dum2 master bond0; sudo ip link set bond0 up
sudo ip link set dum1 down; sleep 1
grep -E 'Currently Active|Link Failure' /proc/net/bonding/bond0
```

Output:

```text
Currently Active Slave: dum2
Link Failure Count: 1
Link Failure Count: 0
```

The counts belong to `dum1` and `dum2`, and the kernel logged `bond0: (slave dum2): making interface the new active one`. Mode 1 needs no switch configuration: one link is active, and the members share the bond's MAC address.

!!! warning "LACP needs both ends configured"
    Mode 4 (802.3ad) only works when the switch ports form a matching LACP group. With a plain switch port, use active-backup.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a bridge and a bond?"
    **Say first:** a bridge switches frames between several segments; a bond presents several NICs as one link to one segment.

    **Proof:** `bridge link show`; `cat /proc/net/bonding/bond0`.

    **Follow-up:** Which one does Docker use for its default network?
<!-- --8<-- [end:l1] -->

??? question "L2: Show which bond member is active and how many failures each had."
    **Say first:** read the bonding driver's status file.

    **Proof:** `grep -E 'Currently Active|Slave Interface|Failure' /proc/net/bonding/bond0`.

    **Follow-up:** Which bond mode needs switch configuration?

??? question "L2: Create a VLAN 10 interface on eth0 with address 10.10.0.10/24."
    **Say first:** add a `vlan` link on top of `eth0`, or a NetworkManager `vlan` profile for persistence.

    **Proof:** `sudo ip link add link eth0 name eth0.10 type vlan id 10`; persistent: `sudo nmcli con add type vlan con-name vlan10 dev eth0 id 10 ipv4.method manual ipv4.addresses 10.10.0.10/24`.

    **Follow-up:** What must the switch port be configured as?

??? question "L2: Find which bridge a container's veth interface is attached to."
    **Say first:** list the bridge ports.

    **Proof:** `bridge link show`; `ip -br link show master docker0`.

    **Follow-up:** How do you find the veth peer of the container's `eth0`? (`ip link` shows `@ifN`.)

??? question "L3: After a switch replacement, a bonded server loses network every few minutes. What do you check?"
    **Say first:** the bond mode against the new switch configuration, member link failures and LACP state.

    **Proof:** `cat /proc/net/bonding/bond0` (mode, `Link Failure Count`, aggregator IDs); `journalctl -k | grep bond`.

    **Follow-up:** Why can mode 0 cause trouble on a switch without a port channel?

??? question "L3: Hosts on the same bridge cannot reach each other, but each can reach the bridge's IP. Where do you look?"
    **Say first:** port state, the forwarding database, VLAN filtering and `br_netfilter` firewall rules.

    **Proof:** `bridge link show` (state `forwarding`); `bridge fdb show`; `bridge vlan show`; `sysctl net.bridge.bridge-nf-call-iptables`.

    **Follow-up:** Why does Kubernetes require `bridge-nf-call-iptables=1`?

---

## Related

- [Interfaces and Addresses](interfaces-and-addresses.md): `ip link` basics

Captured on Rocky Linux 10.2 (iximiuz Labs FlexBox microVM, kernel 6.1.167), 2026-09. MAC addresses are replaced with placeholders.
