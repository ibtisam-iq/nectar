# Security Lab

Set up key-based SSH through a bastion and harden the server, open ports with firewalld and ufw, filter and NAT on a Linux router with nftables, fix a real SELinux denial, grant one capability to a service, record changes with auditd, verify a package signature, serve TLS behind a private CA and trust it, then run an integrity and hardening sweep.

---

## Setup

Use the same three-VM FlexBox playground as the [Networking Lab](networking-lab.md): `client` (Ubuntu 24.04, `172.16.0.2`), `gw` (Rocky Linux, `172.16.0.3` and `172.16.1.2`, the router) and `web` (Rocky Linux, `172.16.1.3`). Addresses can differ; check with `ip -br addr`. Install the tools:

```bash
# gw and web
sudo dnf install -y firewalld selinux-policy-targeted policycoreutils policycoreutils-python-utils audit openssl aide openscap-scanner scap-security-guide setools-console nftables acl nmap-ncat
# client
sudo apt-get update && sudo apt-get install -y ufw apparmor-utils auditd openssh-client gnupg debsums lynis libcap2-bin openssl
```

Create a working user on each server (`deploy` on `gw` and `web`) and a client user `ops`. SELinux is enforcing on both Rocky hosts; confirm with `getenforce`.

!!! warning "Do not lock yourself out"
    Every SSH and firewall change here can end your session. Keep a second terminal open, test a new login before closing the old one, and use the playground's own terminal as a console.

---

## SSH and the Server

### 1. Key-Based Login Through a Bastion

From `ops` on `client`, create a key, reach `gw` directly and `web` through `gw`, and confirm the key is used.

??? tip "Solution"
    ```bash
    ssh-keygen -t ed25519 -C "ops@client"          # client
    ssh-copy-id deploy@172.16.0.3                   # gw is the bastion
    cat >> ~/.ssh/config <<'EOF'
    Host gw
        HostName 172.16.0.3
        User deploy
    Host web
        HostName 172.16.1.3
        User deploy
        ProxyJump gw
    EOF
    chmod 600 ~/.ssh/config
    ssh web 'echo $SSH_CONNECTION'                  # source is gw's dmz address
    ssh -v web true 2>&1 | grep Authenticated
    ```

    `ProxyJump` carries the encrypted session through `gw`; the key never lands on the bastion. On `web`, install the key by hand or with `ssh-copy-id` from `gw`.

### 2. Harden sshd

On `web`, disable root and password logins, limit auth tries and add a banner, testing before the reload.

??? tip "Solution"
    ```bash
    echo 'Authorized use only. Activity is logged.' | sudo tee /etc/issue.net
    sudo tee /etc/ssh/sshd_config.d/10-hardening.conf <<'EOF'
    PermitRootLogin no
    PasswordAuthentication no
    MaxAuthTries 3
    X11Forwarding no
    Banner /etc/issue.net
    EOF
    sudo sshd -t && sudo systemctl reload sshd
    sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|maxauthtries|banner) '
    ```

    A drop-in in `sshd_config.d/` is read before the main file, so its values win. `sshd -t` catches a typo before a reload leaves you locked out.

---

## Firewalls

### 3. Open a Port With firewalld

On `web`, start firewalld and open the API port permanently, watching a runtime rule vanish on reload.

??? tip "Solution"
    ```bash
    sudo systemctl enable --now firewalld            # web; SSH stays open by default
    sudo firewall-cmd --add-port=8080/tcp            # runtime only
    sudo firewall-cmd --reload                        # runtime rule gone
    sudo firewall-cmd --permanent --add-service=http --add-port=8080/tcp
    sudo firewall-cmd --reload
    sudo firewall-cmd --list-all
    ```

    firewalld rejects blocked packets, so a client sees an instant `refused` or `No route to host`, not a timeout. Compare `--list-all` with `--permanent --list-all` after every change.

### 4. Open a Port With ufw

On `client`, deny incoming traffic by default but allow SSH and the API from the lab networks.

??? tip "Solution"
    ```bash
    sudo ufw default deny incoming                    # client
    sudo ufw allow OpenSSH
    sudo ufw allow from 172.16.0.0/16 to any port 8080 proto tcp
    sudo ufw enable
    sudo ufw status numbered
    ```

    ufw `deny` drops silently, so a blocked client times out and `[UFW BLOCK]` appears in `journalctl -k`. Delete rules with `ufw delete allow ...`, not by number, to avoid removing only the IPv6 half.

---

## netfilter on the Router

### 5. Filter and NAT Forwarded Traffic

On `gw`, allow only SSH, DNS and the API from `lan` to `dmz`, log the rest, then masquerade `lan` and publish the API on `gw:8088`.

??? tip "Solution"
    ```bash
    sudo nft add table inet lab
    sudo nft add chain inet lab forward '{ type filter hook forward priority filter; policy drop; }'
    sudo nft add rule inet lab forward ct state established,related accept
    sudo nft add rule inet lab forward iifname eth0 oifname eth1 tcp dport '{ 22, 53, 8080 }' accept
    sudo nft add rule inet lab forward iifname eth0 oifname eth1 udp dport 53 accept
    sudo nft add rule inet lab forward counter log prefix '"lab-drop "' drop
    sudo nft add table ip labnat
    sudo nft add chain ip labnat postrouting '{ type nat hook postrouting priority srcnat; }'
    sudo nft add rule ip labnat postrouting oifname eth1 ip saddr 172.16.0.0/24 masquerade
    sudo nft add chain ip labnat prerouting '{ type nat hook prerouting priority dstnat; }'
    sudo nft add rule ip labnat prerouting iifname eth0 tcp dport 8088 dnat to 172.16.1.3:8080
    ```

    From `client`, port 8080 works and port 9100 times out (`lab-drop` in `journalctl -k` on `gw`). After masquerade, `web` logs `client=172.16.1.2`, the router's address; `curl http://172.16.0.3:8088/` reaches `web` through the port forward. `sudo nft delete table inet lab; sudo nft delete table ip labnat` removes it.

---

## SELinux, Capabilities and Auditing

### 6. Fix a SELinux File-Label Denial

On `web`, serve `/static/` from a new directory and fix the 403 the way that survives a relabel.

??? tip "Solution"
    ```bash
    sudo mkdir -p /data/www; echo hi | sudo tee /data/www/index.html
    # add `location /static/ { alias /data/www/; }` to the API server block, reload nginx
    curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/static/index.html   # 403
    sudo ausearch -m AVC -ts recent | grep -o 'avc: .*' | tail -1                       # tcontext default_t/root_t
    sudo semanage fcontext -a -t httpd_sys_content_t '/data/www(/.*)?'
    sudo restorecon -Rv /data/www
    curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/static/index.html   # 200
    ```

    `chcon` alone is undone by the next `restorecon`; the `semanage fcontext` rule is the lasting fix. For a nonstandard port, add `semanage port -a -t http_port_t -p tcp <port>`, and for a proxy, `setsebool -P httpd_can_network_connect on`.

### 7. Give a Service One Capability

On `web`, run a listener on port 99 as `deploy` through a systemd unit, granting only `CAP_NET_BIND_SERVICE`.

??? tip "Solution"
    ```bash
    sudo tee /etc/systemd/system/lab-lowport.service <<'EOF'
    [Unit]
    Description=Lab low-port listener
    [Service]
    User=deploy
    ExecStart=/usr/bin/ncat -lk 99
    AmbientCapabilities=CAP_NET_BIND_SERVICE
    CapabilityBoundingSet=CAP_NET_BIND_SERVICE
    EOF
    sudo systemctl daemon-reload
    sudo systemctl start lab-lowport
    grep -E 'CapEff|CapAmb' /proc/$(systemctl show -p MainPID --value lab-lowport)/status
    ```

    Without the `AmbientCapabilities` line, the bind fails with `Permission denied`, because `User=` drops all capabilities. `capsh --decode=0000000000000400` confirms the one bit is `cap_net_bind_service`.

### 8. Record Changes With auditd

On `web`, watch `/etc/passwd` and record root commands run by a logged-in user, then read the events.

??? tip "Solution"
    ```bash
    sudo tee /etc/audit/rules.d/50-lab.rules <<'EOF'
    -w /etc/passwd -p wa -k identity
    -a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=unset -k root-exec
    EOF
    sudo augenrules --load
    sudo useradd audituser                                   # trigger the watch
    sudo ausearch -k identity -ts recent --format text
    sudo ausearch -k root-exec -ts recent --format text | tail -2
    ```

    `augenrules --load` applies the rules without a restart (`systemctl restart auditd` is refused). The login UID (`auid`) survives `sudo`, so `ausearch` shows the real user behind a root action.

---

## Trust, Integrity and a Sweep

### 9. Verify a Package Signature

On `web`, confirm a downloaded package is signed by a trusted key, and see a tampered copy fail.

??? tip "Solution"
    ```bash
    dnf download tree
    rpm -K tree-*.rpm                                        # digests signatures OK
    cp tree-*.rpm bad.rpm; printf 'X' | dd of=bad.rpm bs=1 seek=5000 conv=notrunc status=none
    rpm -K bad.rpm; echo "exit=$?"                           # DIGESTS SIGNATURES NOT OK, exit 1
    rpm -q gpg-pubkey --qf '%{SUMMARY}\n'                    # the imported keys
    ```

    `gpgcheck=1` in the repo files makes `dnf` refuse unsigned or altered packages. On Ubuntu the equivalent is a per-repository key under `/etc/apt/keyrings/` with a `Signed-By` line.

### 10. Serve TLS and Trust the CA

On `web`, sign a certificate for `www.shop.internal` with a lab CA and serve it; on `client`, watch the request fail, then trust the CA.

??? tip "Solution"
    ```bash
    # web
    sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -noenc \
      -keyout /etc/pki/lab/ca.key -out /etc/pki/lab/ca.crt -days 3650 -subj "/O=Shop Lab/CN=Shop Lab Root CA"
    sudo openssl req -new -newkey rsa:2048 -noenc -keyout /etc/pki/lab/www.key -out /tmp/www.csr \
      -subj "/O=Shop Lab/CN=www.shop.internal" -addext "subjectAltName=DNS:www.shop.internal"
    sudo openssl x509 -req -in /tmp/www.csr -CA /etc/pki/lab/ca.crt -CAkey /etc/pki/lab/ca.key \
      -CAcreateserial -out /etc/pki/lab/www.crt -days 90 -copy_extensions copy
    # serve www.crt/www.key on 8443 with nginx, open the port in firewalld
    # client
    curl -sS https://www.shop.internal:8443/                 # (60) unable to get local issuer certificate
    sudo cp ca.crt /usr/local/share/ca-certificates/shop-lab-root-ca.crt && sudo update-ca-certificates
    curl -sS https://www.shop.internal:8443/                 # works
    ```

    The handshake succeeds before the CA is trusted; only verification fails. On RHEL the trust store is `/etc/pki/ca-trust/source/anchors/` with `update-ca-trust`. A request by IP still fails, because the SAN lists names only.

### 11. Integrity Baseline and Hardening Sweep

On `web`, build an AIDE baseline, make a change, and detect it; then run the hardening checks.

??? tip "Solution"
    ```bash
    sudo aide --init && sudo cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
    printf '#!/bin/sh\ntrue\n' | sudo tee /usr/sbin/lab-helper; sudo chmod 755 /usr/sbin/lab-helper
    sudo aide --check | grep -A2 'Added entries'             # names /usr/sbin/lab-helper
    sudo rpm -Va | awk '$1 ~ /5/ && $2 != "c"'               # changed non-config files
    awk -F: '$3==0 {print $1}' /etc/passwd                   # only root
    sudo find / -xdev -perm -4000 -type f 2>/dev/null        # setuid inventory
    sudo lynis audit system --quick                          # on client: hardening index
    ```

    AIDE reports the added binary; `rpm -Va` finds changed packaged files; the account, setuid and Lynis checks give a baseline to improve. Keep the AIDE database off the host so an attacker cannot rewrite it.

---

## Cleanup

```bash
# web
sudo nft delete table inet lab 2>/dev/null; sudo nft delete table ip labnat 2>/dev/null   # on gw
sudo systemctl disable --now lab-lowport; sudo rm /etc/systemd/system/lab-lowport.service
sudo semanage fcontext -d '/data/www(/.*)?'; sudo rm -rf /data/www /usr/sbin/lab-helper
sudo rm /etc/audit/rules.d/50-lab.rules && sudo augenrules --load
# client
sudo ufw disable
```

Stopping the playground keeps the state; destroying it removes everything.

---

## Related

- [SSH Client](../14-ssh-and-remote-access/ssh-client.md), [sshd Server](../14-ssh-and-remote-access/sshd-server.md): the SSH tasks in depth
- [firewalld and ufw](../15-security/firewalld-and-ufw.md), [nftables and iptables](../15-security/nftables-and-iptables.md): the firewall tasks
- [SELinux](../15-security/selinux.md), [Capabilities](../15-security/capabilities.md), [auditd](../15-security/auditd.md): the access-control tasks
- [OpenSSL and Trust Store](../15-security/openssl-and-trust-store.md), [Compliance and Integrity](../15-security/compliance-and-integrity.md), [Hardening Checklist](../15-security/hardening-checklist.md): trust and integrity

Steps verified on Rocky Linux 10.2 and Ubuntu 24.04.4 on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
