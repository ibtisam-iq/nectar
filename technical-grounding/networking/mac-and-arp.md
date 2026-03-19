# MAC Address, ARP & Layer 2 Fundamentals

## 1. Why Two Addresses?

IP alone cannot deliver data to a specific device — it only finds the network.
MAC alone cannot route between networks — it only works locally.

```
IP  → gets you to the correct network
MAC → gets you to the correct device inside that network
```

**Analogy:**
- IP = full postal address (country → city → street → house)
- MAC = room number / specific person inside that house

---

## 2. MAC Address

**Definition:** A physical (hardware-level) address permanently assigned to a Network Interface Card (NIC) by the manufacturer.

| Property | Value |
|----------|-------|
| Length | 48 bits (6 bytes) |
| Format | `A1:B2:C3:D4:E5:F6` (hex, colon-separated) |
| Scope | Local network only (Layer 2) |
| Assigned by | NIC manufacturer |
| Changeable? | Hardware MAC = fixed; software-level = can be spoofed |

> **Broadcast MAC:** `FF:FF:FF:FF:FF:FF` — sent to all devices on the local network.

---

## 3. IP vs MAC — Core Difference

| Feature | IP Address | MAC Address |
|---------|-----------|------------|
| Type | Logical | Physical (hardware) |
| Layer | Layer 3 (Network) | Layer 2 (Data Link) |
| Scope | Across networks (global) | Within local network only |
| Assigned by | Network admin / DHCP | Manufacturer |
| Changes? | Yes (dynamic/static) | Hardware: No; Software: Can be spoofed |
| Purpose | Find the network | Find the exact device |
| Works with | Router | Switch |

---

## 4. ARP — Address Resolution Protocol ⭐

**Definition:** Protocol that maps a known IP address → MAC address within a local network.

### How ARP Works (4-Step Process)

```
1. Sender checks ARP cache → is IP→MAC mapping already stored?
2. If not → sends ARP Request broadcast (FF:FF:FF:FF:FF:FF)
   "Who has IP 192.168.1.10? Tell me your MAC."
3. Device with matching IP replies with ARP Reply (unicast)
   "I have 192.168.1.10 — my MAC is A1:B2:C3:D4:E5:F6"
4. Sender stores result in ARP cache → proceeds with data transmission
```

### ARP Cache (ARP Table)

Stores recent IP → MAC mappings to avoid repeating ARP broadcasts.

| IP Address | MAC Address | Type |
|-----------|-------------|------|
| 192.168.1.10 | A1:B2:C3:... | Dynamic |
| 192.168.1.1 | D4:E5:F6:... | Dynamic |

> Entries expire after a timeout and are re-resolved via ARP.

### ARP in Context

| Direction | Protocol |
|-----------|---------|
| IP → MAC | ARP |
| MAC → IP | RARP (Reverse ARP) — legacy |
| IPv6 equivalent | **NDP (Neighbor Discovery Protocol)** — replaces ARP in IPv6 |

---

## 5. Multiple MACs Per Device

A single machine can have multiple MAC addresses — one per Network Interface.

| Interface | MAC |
|-----------|-----|
| WiFi card | `AA:BB:CC:11:22:33` |
| Ethernet port | `AA:BB:CC:44:55:66` |
| Docker virtual adapter | `AA:BB:CC:77:88:99` |
| VM virtual NIC | `AA:BB:CC:AA:BB:CC` |

> **Which MAC is used?** → Whichever interface is used for communication.

---

## 6. Switch — The MAC Address Manager

A **Switch** (Layer 2 device) maintains a **MAC Address Table** that maps MAC addresses to physical ports.

| MAC Address | Port |
|-------------|------|
| A1:B2:C3 | Port 1 |
| D4:E5:F6 | Port 2 |

**How it works:**
1. Frame arrives at switch
2. Switch checks destination MAC in its table
3. Forwards frame to correct port only (not broadcast — unless MAC unknown)

---

## 7. Switch vs Router (Layer Comparison)

| | Switch | Router |
|--|--------|--------|
| OSI Layer | Layer 2 (Data Link) | Layer 3 (Network) |
| Works on | MAC address | IP address |
| Connects | Devices within same network | Different networks |
| Maintains | MAC Address Table | Routing Table |
| When needed | Same Network ID | Different Network ID |

---

## 8. MAC Spoofing (Bonus — Interview Trap) ⭐

> "Is a MAC address truly permanent?"

**Answer:** The hardware MAC burned into the NIC is fixed. However, the OS-level MAC **can be changed (spoofed) via software** without altering hardware.

```bash
# Linux
sudo ip link set dev eth0 address AA:BB:CC:DD:EE:FF

# macOS
sudo ifconfig en0 ether AA:BB:CC:DD:EE:FF
```

**Common uses:** privacy on public Wi-Fi, bypassing MAC filters, security testing.

---

## 9. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Machine has one MAC | One MAC per network interface (can have many) |
| MAC works across internet | MAC is local network only — stripped at each router hop |
| IP directly finds device | IP finds network; ARP + MAC finds the device |
| MAC is always permanent | Hardware MAC is fixed; software-level MAC can be spoofed |
| ARP used in IPv6 | IPv6 uses NDP (Neighbor Discovery Protocol) instead |

---

## 10. Interview Questions Checklist ✅

- [ ] What is a MAC address? How is it different from IP?
- [ ] Can a device have multiple MAC addresses? Why?
- [ ] What is ARP? Explain the 4-step process
- [ ] What is an ARP cache/table?
- [ ] What is RARP?
- [ ] What replaces ARP in IPv6?
- [ ] How does a switch use MAC addresses?
- [ ] Switch vs Router — which layer, which address?
- [ ] Can a MAC address be changed? (MAC spoofing)
- [ ] Why are both MAC and IP needed together?
