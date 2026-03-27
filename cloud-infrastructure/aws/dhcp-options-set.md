# VPC DHCP Option Set

## What is DHCP in AWS?

DHCP (Dynamic Host Configuration Protocol) provides **network configuration
metadata** to EC2 instances when they start up. AWS handles IP address
assignment separately through its VPC networking system — DHCP in AWS
does NOT assign the IP address itself.

```
❌ Common misconception: "DHCP assigns the private IP"
✅ Correct: AWS VPC subnet CIDR logic assigns the IP.
           DHCP delivers configuration metadata to the instance.
```

Every VPC automatically gets a **DHCP Options Set** at creation time.

---

## What DHCP Options Set Configures

| Option | Default Value | Purpose |
|--------|--------------|---------|
| **Domain name** | `ec2.internal` (us-east-1) or `<region>.compute.internal` | DNS suffix for hostname resolution |
| **Domain name servers** | `AmazonProvidedDNS` | VPC DNS resolver (`VPC CIDR base + 2`) |
| **NTP servers** | Amazon Time Sync Service | System clock synchronization |
| **NetBIOS name servers** | None | Legacy Windows name resolution |
| **NetBIOS node type** | None | NetBIOS node behavior |

**AmazonProvidedDNS** is the keyword AWS uses for the built-in DNS resolver.
Its actual IP is always `VPC base CIDR + 2`:
```
VPC CIDR: 10.0.0.0/16  → DNS at 10.0.0.2
VPC CIDR: 172.31.0.0/16 → DNS at 172.31.0.2
VPC CIDR: 192.168.1.0/24 → DNS at 192.168.1.2
```

> Note: `+2` is the **mathematical base of the CIDR** — not the second host IP.
> `10.0.0.0/16` base = `10.0.0.0`, so DNS = `10.0.0.2`.

---

## Key Behavioral Rules ⭐

| Rule | Detail |
|------|--------|
| One per VPC | Only **one** DHCP option set can be attached at a time |
| Cannot modify | DHCP option sets are **immutable** — cannot edit after creation |
| Replace, don't modify | Create a new option set → attach it → old one detaches |
| Change timing | Changes do **not** apply instantly to running instances |
| When changes apply | On next DHCP lease renewal OR instance restart (lease default: ~3600s) |
| Cannot delete attached | Must detach before deleting a custom option set |
| No DHCP option | You can assign the `no-options` set to disable DHCP config entirely |

---

## Custom DHCP Option Set — When to Use

| Scenario | Custom DHCP Needed |
|---------|-------------------|
| Hybrid environment with on-premises Active Directory | ✅ Set AD DNS server as domain name server |
| Custom internal domain name (e.g., `corp.internal`) | ✅ Set custom domain name |
| Internal NTP server | ✅ Set custom NTP server IP |
| Windows workloads requiring NetBIOS | ✅ Configure NetBIOS options |
| Standard AWS workloads | ❌ Default works fine |

---

## Route 53 Resolver (Modern Hybrid DNS)

For hybrid DNS between on-premises and AWS, the modern approach is
**Route 53 Resolver** — not custom DHCP option sets:

```
Inbound Endpoint:   On-prem DNS → forwards to AWS VPC DNS
Outbound Endpoint:  AWS instances → forwards to on-prem DNS

Rule: "Forward corp.internal → 192.168.1.10 (on-prem DNS)"
```

> Route 53 Resolver is more flexible and doesn't require DHCP option set changes.
> Custom DHCP DNS entries are a legacy/simpler approach.

---

## Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| DHCP assigns the private IP | IP allocation is AWS VPC logic; DHCP delivers config metadata |
| DHCP changes apply instantly | Apply at next DHCP lease renewal or instance restart |
| Can modify a DHCP option set | DHCP option sets are **immutable** — create new, attach, replace |
| DNS at `VPC base + 2` is the third host IP | It's `+2` added to the **network base address** — not the third assignable host |

---

## Interview Questions Checklist

- [ ] What does DHCP Option Set configure in a VPC?
- [ ] Does DHCP assign private IPs? (No — AWS VPC does)
- [ ] What is the IP address of the VPC DNS resolver? (CIDR base + 2)
- [ ] How many DHCP option sets can be attached to a VPC? (One)
- [ ] Can you modify a DHCP option set? (No — immutable, must replace)
- [ ] When do DHCP changes take effect on running instances?
- [ ] What is Route 53 Resolver and when do you use it over DHCP custom options?
- [ ] If you use your own DNS — are queries to it captured? (Yes)
