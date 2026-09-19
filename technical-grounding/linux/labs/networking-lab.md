# Networking Lab

Map a small network, route between two subnets through a Linux router, make the configuration permanent with NetworkManager and netplan, fix name resolution for an internal zone, tell a closed port from a filtered one, capture a TCP handshake, synchronize time and put two backends behind nginx.

---

## Setup

Start an iximiuz Labs FlexBox playground with two networks and three VMs:

| Machine | Image | Networks | Addresses |
|---|---|---|---|
| `client` | Ubuntu 24.04 | `lan` (172.16.0.0/24) | `172.16.0.2` |
| `gw` | Rocky Linux | `lan`, `dmz` (172.16.1.0/24) | `172.16.0.3`, `172.16.1.2` |
| `web` | Rocky Linux | `dmz` | `172.16.1.3` |

Each network also has a playground gateway at `.1` for internet access, and it does not route between `lan` and `dmz`. Addresses can differ in another playground; check them with `ip -br addr` and adjust the commands. Install the tools:

```bash
# gw and web
sudo dnf install -y bind-utils tcpdump nmap-ncat traceroute chrony nginx nftables NetworkManager dnsmasq
# client
sudo apt-get update && sudo apt-get install -y dnsutils tcpdump netcat-openbsd traceroute iputils-tracepath chrony nginx netplan.io
```

On `web` and `client`, serve a test page on port 8080 that names the host and the connecting address:

```bash
printf 'server {\n    listen 8080;\n    location / {\n        default_type text/plain;\n        return 200 "api on $hostname client=$remote_addr xff=$http_x_forwarded_for\\n";\n    }\n}\n' | sudo tee /etc/nginx/conf.d/api.conf
sudo systemctl enable --now nginx && sudo systemctl reload nginx
curl -s localhost:8080/
```

---

## Addresses and Routes

### 1. Map the Network

On each machine, list interfaces with their addresses, the default route and the MAC address of the default gateway.

??? tip "Solution"
    ```bash
    ip -br addr
    ip route show default
    ping -c1 -W1 "$(ip route show default | awk '{print $3}')" >/dev/null
    ip neigh show "$(ip route show default | awk '{print $3}')"
    ```

    `gw` has two interfaces, one per network; `client` and `web` have one each.

### 2. Add and Remove a Temporary Address

On `client`, add `172.16.0.50/24` to `eth0`, prove `gw` can reach it, then remove it.

??? tip "Solution"
    ```bash
    sudo ip addr add 172.16.0.50/24 dev eth0     # client
    ping -c2 172.16.0.50                          # gw
    sudo ip addr del 172.16.0.50/24 dev eth0     # client
    ```

    The address disappears at the next reboot even without `del`, because `ip` changes only the running kernel.

### 3. Route Between the Networks

Make `client` reach `web` through `gw`. Show with `tcpdump` on `web` why pings still fail after the forward path works, then fix the return path and prove there is one hop in between.

??? tip "Solution"
    ```bash
    sudo ip route add 172.16.1.0/24 via 172.16.0.3        # client
    sudo sysctl -w net.ipv4.ip_forward=1                  # gw
    sudo tcpdump -eni eth0 -c 2 icmp                      # web, while client pings 172.16.1.3
    sudo ip route add 172.16.0.0/24 via 172.16.1.2        # web
    ping -c2 172.16.1.3; tracepath -n 172.16.1.3          # client
    ```

    Before the return route, `web` sends its replies to the MAC of its default gateway (`172.16.1.1`), not to `gw`. After it, `ping` shows `ttl=63`.

### 4. Make the Router and the Client Route Permanent

Persist forwarding on `gw`. On `client`, write a netplan file for `eth0` that keeps its address, the default route and the route to `dmz`, and apply it safely.

??? tip "Solution"
    ```bash
    echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/90-router.conf   # gw
    sudo sysctl --system | grep -A1 90-router
    ```

    On `client` (use the real MAC from `ip -br link`):

    ```bash
    printf 'network:\n  version: 2\n  renderer: networkd\n  ethernets:\n    lan:\n      match:\n        macaddress: "%s"\n      set-name: eth0\n      addresses: [172.16.0.2/24]\n      routes:\n        - to: default\n          via: 172.16.0.1\n        - to: 172.16.1.0/24\n          via: 172.16.0.3\n      nameservers:\n        addresses: [1.1.1.1, 8.8.8.8]\n' "$(cat /sys/class/net/eth0/address)" | sudo tee /etc/netplan/60-lan.yaml
    sudo chmod 600 /etc/netplan/60-lan.yaml
    sudo netplan generate
    sudo netplan apply
    sleep 2; ip route
    ```

    On this playground, `apply` first prints `systemd-networkd is not running` and restarts it. `ip route` then lists the `dmz` route with `proto static`. On a remote server, `sudo netplan try` instead of `apply` reverts the change unless it is confirmed.

### 5. Give gw a Second Address with NetworkManager

Hand `gw`'s `eth1` from systemd-networkd to NetworkManager without losing its address, keep `eth0` out of NetworkManager, and add `172.16.1.254/24` permanently.

??? tip "Solution"
    ```bash
    printf '[keyfile]\nunmanaged-devices=interface-name:eth0\n[main]\nno-auto-default=*\n' | sudo tee /etc/NetworkManager/conf.d/90-lab.conf
    sudo rm /etc/systemd/network/20-eth1.network && sudo networkctl reload
    sudo systemctl enable --now NetworkManager
    sudo nmcli connection add type ethernet con-name dmz ifname eth1 ipv4.method manual ipv4.addresses "172.16.1.2/24,172.16.1.254/24" ipv6.method link-local
    sudo nmcli connection up dmz
    nmcli device status; ip -br addr show eth1
    ping -c1 172.16.1.254                                  # web
    ```

    `no-auto-default=*` stops NetworkManager from creating a DHCP profile (`Wired connection 1`) for `eth1` before the static one exists. The file name under `/etc/systemd/network/` can differ; `networkctl status eth1` shows it.

---

## Names, Ports and Packets

### 6. Resolve an Internal Zone

On `web`, answer `shop.internal` names with dnsmasq:

```bash
sudo dnsmasq --no-resolv --listen-address=172.16.1.3 --bind-interfaces --address=/shop.internal/172.16.1.3
```

On `client`, `api.shop.internal` does not resolve. Send only `shop.internal` queries to `web` and prove it with the tool applications use. Then add `172.16.1.99 www.shop.internal` to `/etc/hosts` and show why `dig @172.16.1.3` and `getent` disagree.

??? tip "Solution"
    ```bash
    getent hosts api.shop.internal; dig @172.16.1.3 +short api.shop.internal
    sudo mkdir -p /etc/systemd/resolved.conf.d
    printf '[Resolve]\nDNS=172.16.1.3\nDomains=~shop.internal\n' | sudo tee /etc/systemd/resolved.conf.d/shop.conf
    sudo systemctl restart systemd-resolved
    ls -l /etc/resolv.conf
    sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    getent hosts api.shop.internal
    echo '172.16.1.99 www.shop.internal' | sudo tee -a /etc/hosts
    getent hosts www.shop.internal; dig @172.16.1.3 +short www.shop.internal
    ```

    The playground writes `/etc/resolv.conf` as a plain file, which bypasses the stub and its routing domain, so the link restores the Ubuntu default. `getent` returns the `/etc/hosts` address because `files` comes first in `nsswitch.conf`; `dig @server` asks the DNS server only. Remove the line afterwards.

### 7. Find Out Who Can Reach a Port

On `web`, start `nc -lk 127.0.0.1 9000` and `nc -lk 0.0.0.0 9001` in the background. From `client`, test both ports; on `web`, show the listeners and their processes.

??? tip "Solution"
    ```bash
    nohup nc -lk 127.0.0.1 9000 >/dev/null 2>&1 &    # web
    nohup nc -lk 0.0.0.0 9001 >/dev/null 2>&1 &      # web
    nc -vz -w2 172.16.1.3 9000; nc -vz -w2 172.16.1.3 9001    # client
    sudo ss -tlpn '( sport = :9000 or sport = :9001 )'         # web
    ```

    Port 9000 is refused from `client` although it is open: it is bound to loopback.

### 8. Tell Refused from Filtered

On `web`, drop TCP 9001 with nftables. Show the difference on `client`, prove on `web` that the SYNs arrive, then remove the rule.

??? tip "Solution"
    ```bash
    sudo nft add table inet lab                                                            # web
    sudo nft add chain inet lab input '{ type filter hook input priority 0; policy accept; }'
    sudo nft add rule inet lab input tcp dport 9001 drop
    nc -vz -w3 172.16.1.3 9001                                                             # client
    sudo tcpdump -nn -i eth0 -c 2 'tcp port 9001'                                          # web, while client retries
    sudo nft delete table inet lab                                                         # web
    ```

    With the rule, `nc` reports `timed out` instead of `refused`, and the capture shows SYNs with no answer.

### 9. Capture a TCP Handshake

On `gw`, save the packets of one HTTP request from `client` to `web:8080` to a file, then read the handshake and the teardown from it.

??? tip "Solution"
    ```bash
    sudo tcpdump -nn -i eth1 -U -w /tmp/http.pcap -c 10 'tcp port 8080'   # gw
    curl -s http://172.16.1.3:8080/                                     # client
    tcpdump -nn -r /tmp/http.pcap                                       # gw
    ```

    The first three packets carry the flags `[S]`, `[S.]` and `[.]`; the connection ends with `[F.]` from each side.

---

## Services

### 10. Serve Time from web

Make `web` an NTP server for both subnets and `gw` its client. Prove `gw` is synchronized to `web`.

??? tip "Solution"
    ```bash
    echo 'allow 172.16.0.0/16' | sudo tee -a /etc/chrony.conf && sudo systemctl enable --now chronyd && sudo systemctl restart chronyd   # web
    sudo sed -i 's/^pool .*/server 172.16.1.3 iburst/' /etc/chrony.conf                                                                # gw
    sudo systemctl enable --now chronyd && sudo systemctl restart chronyd
    sleep 10; chronyc sources; timedatectl | grep synchronized
    ```

    `chronyc sources` on `gw` lists `web` with `^*`. If `web` itself has not selected a source yet (no `^*` in its own `chronyc sources`), `gw` marks it `^?` with an error of several seconds; once `web` is synchronized, `sudo chronyc burst 4/4` on `gw` requests fresh samples.

### 11. Load-Balance Two Backends

On `gw`, publish `shop.lab.internal` on port 80 with nginx, balanced across `web:8080` and `client:8080`, passing the client address. Stop one backend and show that users still get answers.

??? tip "Solution"
    ```bash
    printf 'upstream shop_api {\n    server 172.16.1.3:8080 max_fails=2 fail_timeout=10s;\n    server 172.16.0.2:8080 max_fails=2 fail_timeout=10s;\n}\nserver {\n    listen 80;\n    server_name shop.lab.internal;\n    location / {\n        proxy_pass http://shop_api;\n        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n    }\n}\n' | sudo tee /etc/nginx/conf.d/shop-proxy.conf   # gw
    sudo nginx -t && sudo systemctl enable --now nginx && sudo systemctl reload nginx
    for i in 1 2 3 4; do curl -s --resolve shop.lab.internal:80:172.16.0.3 http://shop.lab.internal/; done   # client
    sudo systemctl stop nginx                                                                                # client
    for i in 1 2 3 4; do curl -s -o /dev/null -w '%{http_code}\n' --resolve shop.lab.internal:80:172.16.0.3 http://shop.lab.internal/; done
    sudo tail -3 /var/log/nginx/error.log                                                                    # gw
    sudo systemctl start nginx                                                                               # client
    ```

    Both hostnames appear in the answers, each with `xff=172.16.0.2`. With the `client` backend stopped, every request still returns `200`, and the error log shows `connect() failed (111: Connection refused)` and `upstream server temporarily disabled`.

---

## Cleanup

```bash
# client
sudo rm -f /etc/systemd/resolved.conf.d/shop.conf /etc/netplan/60-lan.yaml && sudo systemctl restart systemd-resolved
sudo sed -i '/shop.internal/d' /etc/hosts
# gw
sudo rm -f /etc/nginx/conf.d/shop-proxy.conf /etc/sysctl.d/90-router.conf && sudo systemctl reload nginx
# web
sudo pkill dnsmasq; pkill -f 'nc -lk'
```

The FlexBox playground can also be deleted as a whole.

---

## Related

- [Networking](../13-networking/README.md): the module this lab practises
- [DNS Not Resolving](../interview/scenarios/dns-not-resolving.md): the interview scenario for task 6
- [Troubleshooting Ladder](../13-networking/troubleshooting-ladder.md): the order behind tasks 7 and 8
