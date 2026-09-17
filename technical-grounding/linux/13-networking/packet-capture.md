# Packet Capture

`tcpdump` records the packets that actually cross an interface, which settles arguments that logs and test tools cannot: whether a request arrived, whether a reply left, and which side closed or reset a connection. A capture saved as a pcap file opens in Wireshark for deeper analysis.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Privilege | Capturing needs root or `CAP_NET_RAW` and `CAP_NET_ADMIN` | `sudo tcpdump -D` |
| Interfaces | `-i eth0`, `-i any` (all, cooked headers with direction); `-D` lists them | `tcpdump -D` |
| Basic flags | `-n` no name lookups, `-c N` stop after N packets, `-v` more detail, `-e` MAC addresses | `sudo tcpdump -ni eth0 -c 5` |
| Payload | `-A` ASCII, `-X` hex and ASCII, `-s 0` full packets (default snap length 262144) | `sudo tcpdump -A` |
| Files | `-w file.pcap` writes, `-r` reads, `-U` flushes per packet; `-C`/`-G`/`-W` rotate | `tcpdump -nr file.pcap` |
| Filter primitives | `host`, `net`, `port`, `portrange`, `src`/`dst`, `tcp`/`udp`/`icmp`, `arp` | `man pcap-filter` |
| Combining | `and`, `or`, `not`, parentheses in quotes | `'host 10.0.0.5 and not port 22'` |
| TCP flags filter | `tcp[tcpflags]` with `tcp-syn`, `tcp-ack`, `tcp-fin`, `tcp-rst`, `tcp-push` | `'tcp[tcpflags] & tcp-rst != 0'` |
| Flag letters | `S` SYN, `.` ACK, `P` push, `F` FIN, `R` reset; `S.` is SYN-ACK | handshake capture |
| Where it sees traffic | Incoming before the firewall's input rules, outgoing after the output rules | capture plus firewall counters |
| Other tools | `tshark` (Wireshark CLI), `capinfos`, `termshark` | `tshark -r file.pcap` |
<!-- --8<-- [end:facts] -->

---

## Capturing a TCP Connection

On `client`, while `curl` fetches a page from `web` port 8080:

```bash
sudo tcpdump -ni eth0 -c 10 'tcp port 8080'
```

Output:

```text
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
12:11:58.590318 IP 172.16.0.2.48996 > 172.16.1.3.8080: Flags [S], seq 103526772, win 64240, options [mss 1460,sackOK,TS val 1882303493 ecr 0,nop,wscale 7], length 0
12:11:58.590630 IP 172.16.1.3.8080 > 172.16.0.2.48996: Flags [S.], seq 2348120322, ack 103526773, win 65160, options [mss 1460,sackOK,TS val 2085631425 ecr 1882303493,nop,wscale 7], length 0
12:11:58.590652 IP 172.16.0.2.48996 > 172.16.1.3.8080: Flags [.], ack 1, win 502, options [nop,nop,TS val 1882303493 ecr 2085631425], length 0
12:11:58.590683 IP 172.16.0.2.48996 > 172.16.1.3.8080: Flags [P.], seq 1:79, ack 1, win 502, options [nop,nop,TS val 1882303493 ecr 2085631425], length 78: HTTP: GET / HTTP/1.1
12:11:58.590862 IP 172.16.1.3.8080 > 172.16.0.2.48996: Flags [.], ack 79, win 509, options [nop,nop,TS val 2085631425 ecr 1882303493], length 0
12:11:58.591024 IP 172.16.1.3.8080 > 172.16.0.2.48996: Flags [P.], seq 1:183, ack 79, win 509, options [nop,nop,TS val 2085631425 ecr 1882303493], length 182: HTTP: HTTP/1.1 200 OK
12:11:58.591029 IP 172.16.0.2.48996 > 172.16.1.3.8080: Flags [.], ack 183, win 501, options [nop,nop,TS val 1882303493 ecr 2085631425], length 0
12:11:58.591092 IP 172.16.0.2.48996 > 172.16.1.3.8080: Flags [F.], seq 79, ack 183, win 501, options [nop,nop,TS val 1882303493 ecr 2085631425], length 0
12:11:58.591200 IP 172.16.1.3.8080 > 172.16.0.2.48996: Flags [F.], seq 183, ack 80, win 509, options [nop,nop,TS val 2085631425 ecr 1882303493], length 0
12:11:58.591204 IP 172.16.0.2.48996 > 172.16.1.3.8080: Flags [.], ack 184, win 501, options [nop,nop,TS val 1882303494 ecr 2085631425], length 0
10 packets captured
10 packets received by filter
0 packets dropped by kernel
```

| Packets | Meaning |
|---|---|
| 1 to 3 | Three-way handshake: `S`, `S.`, `.`; both sides announce MSS 1460 and window scaling |
| 4 | Request, 78 bytes (`P.` pushes data to the application) |
| 5 to 7 | Server ACK, 182-byte response, client ACK |
| 8 to 10 | Client closes first (`F.`), server closes (`F.`), final ACK |

After the handshake, `tcpdump` prints relative sequence numbers (`seq 1:79`). The client sent the first FIN, so its side of this connection went to `TIME-WAIT`.

!!! tip "Capture on both ends"
    A request visible on the client but not on the server was dropped in between; a reply visible on the server but not on the client was dropped on the way back. Two captures turn "the network is broken" into a specific hop.

---

## A DNS Query and a Refused Connection

The first capture ran during `dig @172.16.1.3 db.shop.internal`, the second while `nc -z` tried port 9202:

```bash
sudo tcpdump -ni eth0 -c 2 'udp port 53'
sudo tcpdump -ni eth0 -c 2 'tcp[tcpflags] & (tcp-syn|tcp-rst) != 0'
```

Output:

```text
# ... (trimmed)
12:12:00.605297 IP 172.16.0.2.41588 > 172.16.1.3.53: 38119+ [1au] A? db.shop.internal. (57)
12:12:00.605844 IP 172.16.1.3.53 > 172.16.0.2.41588: 38119*- 1/0/1 A 172.16.1.10 (89)
# ... (trimmed)
12:12:02.625527 IP 172.16.0.2.37984 > 172.16.1.3.9202: Flags [S], seq 1193972441, win 64240, options [mss 1460,sackOK,TS val 1882307528 ecr 0,nop,wscale 7], length 0
12:12:02.625829 IP 172.16.1.3.9202 > 172.16.0.2.37984: Flags [R.], seq 0, ack 1193972442, win 0, length 0
```

The reset (`R.`) is the wire form of `Connection refused`. In the DNS lines, `38119` is the query ID, `+` means recursion desired, `A?` the question, `*` an authoritative answer, and `1/0/1` the answer, authority and additional record counts.

---

## Reading the Payload

```bash
sudo tcpdump -ni eth0 -A -c 2 'tcp port 8080 and tcp[tcpflags] & tcp-push != 0'
```

Output:

```text
# ... (trimmed)
12:12:28.116370 IP 172.16.0.2.42644 > 172.16.1.3.8080: Flags [P.], seq 3332687597:3332687688, ack 3379682489, win 502, options [nop,nop,TS val 1882333019 ecr 2085660950], length 91: HTTP: GET /health HTTP/1.1
E...=.@.@..D.................q......Y......
p2.[|P..GET /health HTTP/1.1
Host: api.shop.internal:8080
User-Agent: curl/8.5.0
Accept: */*


12:12:28.116528 IP 172.16.1.3.8080 > 172.16.0.2.42644: Flags [P.], seq 1:151, ack 91, win 509, options [nop,nop,TS val 2085660950 ecr 1882333019], length 150: HTTP: HTTP/1.1 200 OK
E...Tu@.?................q.....H....Y......
|P..p2.[HTTP/1.1 200 OK
Server: nginx/1.26.3
# ... (trimmed)
ok
```

The unreadable characters before `GET` are the IP and TCP headers printed as ASCII. The response's IP header carries TTL 63 (`?` is 0x3f), one less than `web` sent, because `gw` forwarded it.

!!! danger "Captures contain secrets"
    Plain HTTP, DNS and many database protocols carry passwords, tokens and personal data in clear text. Capture only what the problem needs, delete pcap files afterwards, and never attach them to public tickets.

---

## Saving and Reading pcap Files

```bash
sudo tcpdump -ni eth0 -U -w /tmp/web.pcap -c 14 'host 172.16.1.3'
ls -l /tmp/web.pcap
tcpdump -nr /tmp/web.pcap icmp
tshark -r /tmp/web.pcap -Y http
capinfos /tmp/web.pcap | grep -E 'Number of packets|Capture duration'
```

Output:

```text
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
14 packets captured
14 packets received by filter
0 packets dropped by kernel
-rw-r--r-- 1 tcpdump tcpdump 1550 Sep 17 12:12 /tmp/web.pcap
reading from file /tmp/web.pcap, link-type EN10MB (Ethernet), snapshot length 262144
12:12:54.235511 IP 172.16.0.2 > 172.16.1.3: ICMP echo request, id 4001, seq 1, length 64
12:12:54.235627 IP 172.16.1.3 > 172.16.0.2: ICMP echo reply, id 4001, seq 1, length 64
12:12:55.266253 IP 172.16.0.2 > 172.16.1.3: ICMP echo request, id 4001, seq 2, length 64
12:12:55.266556 IP 172.16.1.3 > 172.16.0.2: ICMP echo reply, id 4001, seq 2, length 64
    4   0.000359   172.16.0.2 → 172.16.1.3   HTTP 150 GET /health HTTP/1.1 
    6   0.000612   172.16.1.3 → 172.16.0.2   HTTP 216 HTTP/1.1 200 OK  (text/plain)
Number of packets:   14
Capture duration:    1.033646 second
                     Number of packets = 14
```

`tcpdump` drops root privileges to the `tcpdump` user after opening the interface, so the file belongs to that user and reading it needs no `sudo`. Reading applies a new filter (`icmp`) to the saved packets, and `tshark -Y` uses Wireshark's display filters. For long captures, `-C 100 -W 5` keeps five 100 MB files in rotation, and `-G 3600` starts a new file every hour.

---

## Common Errors

### `tcpdump: eth0: You don't have permission to perform this capture on that device`

**Cause:** the capture ran without root or the capture capabilities.

**Fix:** `sudo tcpdump ...`.

### `tcpdump: eth9: No such device exists`

**Cause:** the interface name is wrong.

**Fix:** `tcpdump -D` or `ip -br link`; use `-i any` when unsure.

### `tcpdump: truncated dump file; tried to read 4 file header bytes, only got 0`

**Cause:** the pcap file is empty, for example because the capture was stopped before anything was written to disk.

**Fix:** write with `-U`, let `-c` end the capture, or stop it with Ctrl-C so it flushes.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What do the flags S, S., F. and R. mean in tcpdump output?"
    **Say first:** SYN, SYN-ACK, FIN with ACK, and reset with ACK.

    **Proof:** `sudo tcpdump -ni eth0 'tcp port 8080'` during a `curl`.

    **Follow-up:** Which packet does the client see when a port is closed?
<!-- --8<-- [end:l1] -->

??? question "L2: Capture only DNS traffic to and from one server and save it for Wireshark."
    **Say first:** filter on host and port 53, write to a file.

    **Proof:** `sudo tcpdump -ni eth0 -w dns.pcap 'host 172.16.1.3 and port 53'`.

    **Follow-up:** Why include TCP 53 as well as UDP?

??? question "L2: Show only new connection attempts and resets on an interface."
    **Say first:** filter on the SYN and RST bits.

    **Proof:** `sudo tcpdump -ni eth0 'tcp[tcpflags] & (tcp-syn|tcp-rst) != 0'`.

    **Follow-up:** How would you exclude the SYN-ACKs?

??? question "L2: Capture on a busy server for a day without filling the disk."
    **Say first:** use a tight filter, a snap length, and ring-buffer rotation.

    **Proof:** `sudo tcpdump -ni eth0 -s 128 -C 100 -W 10 -w /var/tmp/cap.pcap 'port 443'`.

    **Follow-up:** What is lost with `-s 128`?

??? question "L3: The application team says the server never answers. Their client logs show timeouts. How do you prove where the packets go?"
    **Say first:** capture on the server (and ideally the client) for the client's address and port, then compare.

    **Proof:** `sudo tcpdump -ni any host <client> and port <port>`; SYNs without SYN-ACKs point to the server or its firewall; SYN-ACKs that never reach the client point to the return path.

    **Follow-up:** Why can tcpdump show a packet that the firewall then drops?

??? question "L3: TLS connections to a partner API hang after the ClientHello. What would a capture show, and what does it suggest?"
    **Say first:** small packets pass, large server packets are missing or retransmitted, which suggests a path MTU problem.

    **Proof:** `sudo tcpdump -ni eth0 host <partner>` shows the ClientHello and ACKs but no full-size segments; `tracepath <partner>`.

    **Follow-up:** Which ICMP message should appear, and where is it blocked?

---

## Related

- [Connectivity Testing](connectivity-testing.md): tests to run before capturing
- [Sockets and TCP States](sockets-and-tcp-states.md): the states behind the flags
- [DNS Resolution](dns-resolution.md): what the DNS lines mean
- [OSI Model](../../networking/osi-model.md): the layers in a packet

Captured on Ubuntu 24.04.4 (tcpdump 4.99.4, tshark) on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
