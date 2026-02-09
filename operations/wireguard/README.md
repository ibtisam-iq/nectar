# 🛠 Step-by-Step Guide: WireGuard VPN on an Indian VPS

## **Step 1: Rent a VPS in India**

Choose any provider with Indian datacenters:

* **Hetzner** (Mumbai) → \~€3.79/month
* **Vultr** / **DigitalOcean** → \~\$5/month
* **AWS Lightsail India** → \~\$5/month
* **Oracle Cloud Free Tier** → if India region is available, you may get it free

👉 You just need **1 vCPU, 1GB RAM, 20GB SSD**.

## **Step 2: SSH into Your VPS**

From your local machine:

```bash
ssh root@<your_vps_ip>
```

## **Step 3: Install WireGuard**

On Ubuntu/Debian (recommended):

```bash
apt update && apt upgrade -y
apt install wireguard -y
```

## **Step 4: Generate Keys**

```bash
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
```

* Private key → `/etc/wireguard/privatekey`
* Public key → `/etc/wireguard/publickey`

## **Step 5: Configure WireGuard Server**

Create file:

```bash
nano /etc/wireguard/wg0.conf
```

Paste this (replace `<SERVER_PRIVATE_KEY>` with contents of `/etc/wireguard/privatekey`):

```ini
[Interface]
PrivateKey = <SERVER_PRIVATE_KEY>
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = true

# Allow forwarding
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

## **Step 6: Enable IP Forwarding**

```bash
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

## **Step 7: Start WireGuard**

```bash
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
```

## **Step 8: Add a Client**

On the server, generate client keys:

```bash
wg genkey | tee client-privatekey | wg pubkey > client-publickey
```

Edit server config `/etc/wireguard/wg0.conf` → add client section:

```ini
[Peer]
PublicKey = <CLIENT_PUBLIC_KEY>
AllowedIPs = 10.0.0.2/32
```

## **Step 9: Create Client Config**

On your laptop/phone, create file `wg-client.conf`:

```ini
[Interface]
PrivateKey = <CLIENT_PRIVATE_KEY>
Address = 10.0.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## **Step 10: Connect**

* On **Linux/Mac**:

  ```bash
  wg-quick up wg-client.conf
  ```
* On **Windows/Android/iOS**:

  * Install the **WireGuard App**
  * Import `wg-client.conf` (scan QR code or copy file)

👉 Now all traffic goes through your **Indian server** 🎉

⚡ Pro tip for automation:
You can use **`angristan/wireguard-install`** script to do all steps in 2 minutes:

```bash
curl -O https://raw.githubusercontent.com/angristan/wireguard-install/master/wireguard-install.sh
chmod +x wireguard-install.sh
./wireguard-install.sh
```

This script asks a few questions, then sets up server + client config automatically.

✅ After setup, visit [whatismyipaddress.com](https://whatismyipaddress.com) and you’ll see an **Indian IP**.

---

```bash
ubuntu@ip-172-31-83-184:~$ curl ifconfig.me
54.163.181.14ubuntu@ip-172-31-83-184:~$
ubuntu@ip-172-31-83-184:~$ curl -O https://raw.githubusercontent.com/angristan/wireguard-install/master/wireguard-install.sh
chmod +x wireguard-install.sh
./wireguard-install.sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 20487  100 20487    0     0   411k      0 --:--:-- --:--:-- --:--:--  416k
You need to run this script as root
ubuntu@ip-172-31-83-184:~$ sudo ./wireguard-install.sh
Welcome to the WireGuard installer!
The git repository is available at: https://github.com/angristan/wireguard-install

I need to ask you a few questions before starting the setup.
You can keep the default options and just press enter if you are ok with them.

IPv4 or IPv6 public address: 54.163.181.14
Public interface: enX0
WireGuard interface name: wg0
Server WireGuard IPv4: 10.66.66.1
Server WireGuard IPv6: fd42:42:42::1
Server WireGuard port [1-65535]: 62722
First DNS resolver to use for the clients: 1.1.1.1
Second DNS resolver to use for the clients (optional): 1.0.0.1

WireGuard uses a parameter called AllowedIPs to determine what is routed over the VPN.
Allowed IPs list for generated clients (leave default to route everything): 0.0.0.0/0,::/0

Okay, that was all I needed. We are ready to setup your WireGuard server now.
You will be able to generate a client at the end of the installation.
Press any key to continue...
Hit:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble InRelease
Hit:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates InRelease
Hit:3 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-backports InRelease
Hit:4 http://security.ubuntu.com/ubuntu noble-security InRelease
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Note, selecting 'systemd-resolved' instead of 'resolvconf'
iptables is already the newest version (1.8.10-3ubuntu2).
iptables set to manually installed.
The following additional packages will be installed:
  libnss-systemd libpam-systemd libqrencode4 libsystemd-shared libsystemd0 libudev1 systemd systemd-dev systemd-sysv udev wireguard-tools
Suggested packages:
  systemd-container systemd-homed systemd-userdbd systemd-boot libtss2-rc0
The following NEW packages will be installed:
  libqrencode4 qrencode wireguard wireguard-tools
The following packages will be upgraded:
  libnss-systemd libpam-systemd libsystemd-shared libsystemd0 libudev1 systemd systemd-dev systemd-resolved systemd-sysv udev
10 upgraded, 4 newly installed, 0 to remove and 99 not upgraded.
Need to get 8983 kB of archives.
After this operation, 518 kB of additional disk space will be used.
Get:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates/main amd64 libnss-systemd amd64 255.4-1ubuntu8.10 [159 kB]
Get:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates/main amd64 systemd-dev all 255.4-1ubuntu8.10 [105 kB]
Get:3 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates/main amd64 systemd-resolved amd64 255.4-1ubuntu8.10 [296 kB]
Get:4 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates/main amd64 libsystemd-shared amd64 255.4-1ubuntu8.10 [2074 kB]
Get:5 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates/main amd64 libsystemd0 amd64 255.4-1ubuntu8.10 [434 kB]
Get:6 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates/main amd64 systemd-sysv amd64 255.4-1ubuntu8.10 [11.9 kB]
Get:7 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates/main amd64 libpam-systemd amd64 255.4-1ubuntu8.10 [235 kB]
Get:8 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates/main amd64 systemd amd64 255.4-1ubuntu8.10 [3475 kB]
Get:9 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates/main amd64 udev amd64 255.4-1ubuntu8.10 [1873 kB]
Get:10 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble-updates/main amd64 libudev1 amd64 255.4-1ubuntu8.10 [176 kB]
Get:11 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble/universe amd64 libqrencode4 amd64 4.1.1-1build2 [25.0 kB]
Get:12 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble/universe amd64 qrencode amd64 4.1.1-1build2 [26.1 kB]
Get:13 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble/main amd64 wireguard-tools amd64 1.0.20210914-1ubuntu4 [89.1 kB]
Get:14 http://us-east-1.ec2.archive.ubuntu.com/ubuntu noble/universe amd64 wireguard all 1.0.20210914-1ubuntu4 [3086 B]
Fetched 8983 kB in 0s (63.4 MB/s)
(Reading database ... 70681 files and directories currently installed.)
Preparing to unpack .../libnss-systemd_255.4-1ubuntu8.10_amd64.deb ...
Unpacking libnss-systemd:amd64 (255.4-1ubuntu8.10) over (255.4-1ubuntu8.8) ...
Preparing to unpack .../systemd-dev_255.4-1ubuntu8.10_all.deb ...
Unpacking systemd-dev (255.4-1ubuntu8.10) over (255.4-1ubuntu8.8) ...
Preparing to unpack .../systemd-resolved_255.4-1ubuntu8.10_amd64.deb ...
Unpacking systemd-resolved (255.4-1ubuntu8.10) over (255.4-1ubuntu8.8) ...
Preparing to unpack .../libsystemd-shared_255.4-1ubuntu8.10_amd64.deb ...
Unpacking libsystemd-shared:amd64 (255.4-1ubuntu8.10) over (255.4-1ubuntu8.8) ...
Preparing to unpack .../libsystemd0_255.4-1ubuntu8.10_amd64.deb ...
Unpacking libsystemd0:amd64 (255.4-1ubuntu8.10) over (255.4-1ubuntu8.8) ...
Setting up libsystemd0:amd64 (255.4-1ubuntu8.10) ...
(Reading database ... 70681 files and directories currently installed.)
Preparing to unpack .../systemd-sysv_255.4-1ubuntu8.10_amd64.deb ...
Unpacking systemd-sysv (255.4-1ubuntu8.10) over (255.4-1ubuntu8.8) ...
Preparing to unpack .../libpam-systemd_255.4-1ubuntu8.10_amd64.deb ...
Unpacking libpam-systemd:amd64 (255.4-1ubuntu8.10) over (255.4-1ubuntu8.8) ...
Preparing to unpack .../systemd_255.4-1ubuntu8.10_amd64.deb ...
Unpacking systemd (255.4-1ubuntu8.10) over (255.4-1ubuntu8.8) ...
Preparing to unpack .../udev_255.4-1ubuntu8.10_amd64.deb ...
Unpacking udev (255.4-1ubuntu8.10) over (255.4-1ubuntu8.8) ...
Preparing to unpack .../libudev1_255.4-1ubuntu8.10_amd64.deb ...
Unpacking libudev1:amd64 (255.4-1ubuntu8.10) over (255.4-1ubuntu8.8) ...
Setting up libudev1:amd64 (255.4-1ubuntu8.10) ...
Selecting previously unselected package libqrencode4:amd64.
(Reading database ... 70681 files and directories currently installed.)
Preparing to unpack .../libqrencode4_4.1.1-1build2_amd64.deb ...
Unpacking libqrencode4:amd64 (4.1.1-1build2) ...
Selecting previously unselected package qrencode.
Preparing to unpack .../qrencode_4.1.1-1build2_amd64.deb ...
Unpacking qrencode (4.1.1-1build2) ...
Selecting previously unselected package wireguard-tools.
Preparing to unpack .../wireguard-tools_1.0.20210914-1ubuntu4_amd64.deb ...
Unpacking wireguard-tools (1.0.20210914-1ubuntu4) ...
Selecting previously unselected package wireguard.
Preparing to unpack .../wireguard_1.0.20210914-1ubuntu4_all.deb ...
Unpacking wireguard (1.0.20210914-1ubuntu4) ...
Setting up libqrencode4:amd64 (4.1.1-1build2) ...
Setting up qrencode (4.1.1-1build2) ...
Setting up systemd-dev (255.4-1ubuntu8.10) ...
Setting up wireguard-tools (1.0.20210914-1ubuntu4) ...
wg-quick.target is a disabled or a static unit, not starting it.
Setting up libsystemd-shared:amd64 (255.4-1ubuntu8.10) ...
Setting up wireguard (1.0.20210914-1ubuntu4) ...
Setting up systemd (255.4-1ubuntu8.10) ...
Setting up udev (255.4-1ubuntu8.10) ...
Setting up systemd-resolved (255.4-1ubuntu8.10) ...
Setting up systemd-sysv (255.4-1ubuntu8.10) ...
Setting up libnss-systemd:amd64 (255.4-1ubuntu8.10) ...
Setting up libpam-systemd:amd64 (255.4-1ubuntu8.10) ...
Processing triggers for libc-bin (2.39-0ubuntu8.4) ...
Processing triggers for man-db (2.12.0-4build2) ...
Processing triggers for dbus (1.14.10-4ubuntu4.1) ...
Processing triggers for initramfs-tools (0.142ubuntu25.5) ...
update-initramfs: Generating /boot/initrd.img-6.8.0-1029-aws
Scanning processes...
Scanning candidates...
Scanning linux images...

Running kernel seems to be up-to-date.

Restarting services...
 systemctl restart irqbalance.service multipathd.service packagekit.service polkit.service rsyslog.service ssh.service udisks2.service

Service restarts being deferred:
 systemctl restart ModemManager.service
 /etc/needrestart/restart.d/dbus.service
 systemctl restart networkd-dispatcher.service
 systemctl restart systemd-logind.service
 systemctl restart unattended-upgrades.service

No containers need to be restarted.

User sessions running outdated binaries:
 ubuntu @ session #1: sshd[1121]
 ubuntu @ user manager service: systemd[1126]

No VM guests are running outdated hypervisor (qemu) binaries on this host.
* Applying /usr/lib/sysctl.d/10-apparmor.conf ...
* Applying /etc/sysctl.d/10-bufferbloat.conf ...
* Applying /etc/sysctl.d/10-console-messages.conf ...
* Applying /etc/sysctl.d/10-ipv6-privacy.conf ...
* Applying /etc/sysctl.d/10-kernel-hardening.conf ...
* Applying /etc/sysctl.d/10-magic-sysrq.conf ...
* Applying /etc/sysctl.d/10-map-count.conf ...
* Applying /etc/sysctl.d/10-network-security.conf ...
* Applying /etc/sysctl.d/10-ptrace.conf ...
* Applying /etc/sysctl.d/10-zeropage.conf ...
* Applying /etc/sysctl.d/50-cloudimg-settings.conf ...
* Applying /usr/lib/sysctl.d/50-pid-max.conf ...
* Applying /etc/sysctl.d/99-cloudimg-ipv6.conf ...
* Applying /usr/lib/sysctl.d/99-protect-links.conf ...
* Applying /etc/sysctl.d/99-sysctl.conf ...
* Applying /etc/sysctl.d/wg.conf ...
* Applying /etc/sysctl.conf ...
kernel.apparmor_restrict_unprivileged_userns = 1
net.core.default_qdisc = fq_codel
kernel.printk = 4 4 1 7
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2
kernel.kptr_restrict = 1
kernel.sysrq = 176
vm.max_map_count = 1048576
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.all.rp_filter = 2
kernel.yama.ptrace_scope = 1
vm.mmap_min_addr = 65536
net.ipv4.neigh.default.gc_thresh2 = 15360
net.ipv4.neigh.default.gc_thresh3 = 16384
net.netfilter.nf_conntrack_max = 1048576
kernel.pid_max = 4194304
net.ipv6.conf.all.use_tempaddr = 0
net.ipv6.conf.default.use_tempaddr = 0
fs.protected_fifos = 1
fs.protected_hardlinks = 1
fs.protected_regular = 2
fs.protected_symlinks = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
Created symlink /etc/systemd/system/multi-user.target.wants/wg-quick@wg0.service → /usr/lib/systemd/system/wg-quick@.service.

Client configuration

The client name must consist of alphanumeric character(s). It may also include underscores or dashes and can't exceed 15 chars.
Client name: ibtisam
Client WireGuard IPv4: 10.66.66.2
Client WireGuard IPv6: fd42:42:42::2

Here is your client config file as a QR Code:

█████████████████████████████████████████████████████████████████████████████████████████
█████████████████████████████████████████████████████████████████████████████████████████
████ ▄▄▄▄▄ █ ▄ ▄▀▄▄▄▀ ▀ ▄ ▄▄█▄ ▄  ▄▀▀█ ▀▄   ▄ ▄▀ █▄▀█▄▀ ▀▀▀▀▄▄▄▀▀▄▄ ▄▀▄ █▄▀▀▀█ ▄▄▄▄▄ ████
████ █   █ █  ▄█ ▀ ▄   ▄▀█▀▀█ █▀█▀ ▀▀▀▀ ▀▀█  █ ▀▀▀▄ ██▀▀▄   ▄█▄ █▀█▀▄ ▀█▄█ █ █ █   █ ████
████ █▄▄▄█ █▀▀▄█ ▄█▀▀▀ █▄ ▄▀ ▄▄▄ █▀▄██ ▀█▄ █ █ ▄██▀█ ▄▄▄ ▀▄▀ ▄█▄█   ▄█ ▀▀▄█▀██ █▄▄▄█ ████
████▄▄▄▄▄▄▄█▄▀ █ ▀ ▀ ▀ ▀▄▀▄▀ █▄█ █▄█ █ ▀▄█ ▀ █ █ █ █ █▄█ █▄█▄█ █▄█▄█ ▀▄▀▄█ █▄█▄▄▄▄▄▄▄████
████ ▄█▀  ▄▀▀███▀  ▀▄  ▄▀▄     ▄  ▀▀▀▀ ▀ █▀ ▄▀▀█ ▀ █  ▄▄ ▀█▀ ▀▄▀█  ▄▀█▀▄▄▄▄█▀▀█ ▀▄▄▄ ████
████▀█▀▄▄▀▄▀█▀ ▀██▀█ ▀▀▄██▄█▄█  ▄ ▀█ ▄▄█▄▀█▀█ ▀▄ ▄▄▀█▄▀▄▀█▄ █▀ ▄▀▄ ▀▄ █▀▀▀▀█▄█████▄██████
█████▀▄▀  ▄ ▄ ▄█  ▄▄▀█▀  ▄▀██ █▀ ▀▀ █▀ ▀   █▄█▀█▄▀  ▀█▀ ▀  ▀▀▄▀  ▀▀▄ █▀▀█▀█▀ ▀█▀▄█ ▀▄████
████▄▀█   ▄ ▄█▀▀██▀▀█▀█▄▄   ▀ ▄█▄▄▀▄▀ ▄ ▀▀▀▀█▄▀█ ▄ ▄█ ▀▄ ▄█ █  ▄▀▄█▄  █▄██  ██▄▄▀ █ █████
████ ▄ ▀ ▄▄▀▄█  █▀ ▀█▄▄ ▀█▀█   █▀▀▀▀▄▀▄▄▄▄▄ ███  ▀██ █▄  █▄▄█▄▀█▀ ▀█  ▀▀█▄██▄█▀█▄ ▄ ▀████
█████ ▄▀▀▄▄█▄▀ ▄ ▀███ ▄ ▄▀▄▀▀▄ ▄█ ▄▄ ▄   ▀  ▀ ▄▄ ▄█▄▄ █▄▀ █▄▀▀█▀█▀█▀█ █▀▀ █▄ ██ ▄ ▄▄▀████
█████   ▀█▄▄▄ ▄▀▄█▀█▄█▀█▀▀▄▀▀ ██▀▄ ▀▄██   █▄ ▄  ▀█ ▄▀▀   ▄▄ ▀▀ ▀▄▄█ ▄▄▀▄ ██▀█▄▄██▀ ▀█████
█████ ▀ ▀ ▄ ██▀▀▄▀▄██▄ ▀▄▀▄██ ▄ █▀█  ▄   ▀ ▀█▀█▄▄▄  █ ▀▄█ █▀ ▄▀▀▀ ▄▄  ▄  █  ███▄▄▀▀▀▄████
█████▀ █ ▄▄▄ ███▄█▀█▀▀▄▀▄ ▄▄ ▄▄▄ ▄▀█ ███▀█ ▀█▀ █ ██▄ ▄▄▄ ▄▄ ▄▄ ▄█ █▄▀██ ▀▀   ▄▄▄ ▀█▀█████
████▄▀▄  █▄█ ██  █ ▀▀█▀█ █ ▀ █▄█ ▄  █▄▄▀ ▀  ▀▄▀ █▄ ▄ █▄█    ██ ▀▀██▀  ▄▀ █   █▄█ ▄ █▀████
█████▄ █▄ ▄▄ ▄   ▀█▄█▄  ▄█▄  ▄▄ ▄ ▄▄ ▄▄█▀▄█ ███▄ █ █ ▄ ▄ █▀█▀█ ▄█▀▄█▀ █▄█▀▄ ▄▄ ▄▄█▄▄ ████
████  ▀█▄▀▄██▀▀██▄ ▄ ▀▀█▀█▄▄▀██▄▀▄▄█▀ ██ ▀▀ ▄▄▀██ ▄▄▄▄▄  ▄█▀██ ▄▀██▄▄██▀█▄  ▄▀▄▀█   ▀████
████▀▀ ▀▀▀▄██▄▀█ ▄▀▄█▄ ▀▄▄██▄▀  ▄ ▄▀ █ ▀▄▄ ▀██▄▀▄█▀▀  ▄█▄ ▀  ▄ ▀▀▀▄▀▀▄▀█▄ █ ▄▄█▀▄█▄▀▀████
████▄ ▄  █▄▄▄ █▀▀▀   ▀██▄    ▄█▄   █▄ ▀ █  ▀▀▄ ▄▄  █▄█▀ ▀██▄█▀ ▀██▄█ █▄▄█  ▄ ▄█▀▀██▄ ████
████   ▄▄ ▄▄▀ ▀▄▀ ▄█▄▀▄ ▀█▄█ █ ██▄▄▄▀▄█▄█ █ ▄█▄█ ▄█▄█ ▀██   ▄ █▀▀▄█▀▀▀▀█▄█▄ ▄▄▄████  ████
█████ ▀█▀▀▄▀ ▀▀▄▀▄██▄█▀ █▄▀█▀▄██ ▄▄▄▄▀ ▀▄████  ███▄ █ ▄ █████▀█ █▀▄▄▀ ▄ █ ▄▀▀█▀█▄█  ▄████
████▀█▄▀▀▄▄ ▀▀ █   ▄ █ ▄ ▄█▀▄█ █▀▀█ ▄ █▀▀█ █▀██   ▄▀▀▄█▄██  ▄▄▀▄▄ ███ █▀▄██ ▀▄██▄ █▀▀████
████  ▀█▄▄▄▀█▀█▄███▀██▀ ▄█▄▄ ▀▀▀█▄ ▄ ▄█  ▀▀█▀▄ ▄█▄██▄▄█ ▄▀██▀▀▀█▀ █  ▀█▄▀█████ ▄▄ █ ▄████
████▄   █ ▄ ▄ █▀▀ █▀▀▄▄▀▄▀▀▀█ █▄▀▀█ ███▄ ▄ ▀█▀██▀▄█▀  ▀█▀▀  ▀▄▄▄██▀▀█▀▀▀▀▄▄  ▄█ █▀█▀█████
████▄▄▄▄ ▄▄▀▀▀▀▄▀▄▄▀▄ █▀▄ ▄█▀▀ ▄  █▄ ▄█▀ ▀█ ▄▄▀  ▄▄▄▄▀█▀█▀█▀▀  █▀ █ ▄▄▀ ▀█▀ █▄██▄▄ ▀█████
█████▄   ▄▄▄ ▄ ▄▀▀▀ ██▀    █ ▄▄▄ █ ▀▄▄█▄▄ ███ ▀▀▄▄▄▄ ▄▄▄ ▄▀ ██▄▄█ ▀▀▀▄▄▄▄█▄█ ▄▄▄ ▀███████
████ █ █ █▄█ █  ▀▀▄▀ █ ██▀   █▄█ █ ██▄   ██▀████▄▄▀█ █▄█ █▀▀█▄ ██▄█▀ ▀▄▀ █   █▄█ ▀▄██████
█████ ▀ ▄ ▄▄▄█▄█  ▀█▀▀▀▄▀█▀ ▄ ▄  ▄▄▀███▄▄▀ ▀ █ ▀█▀▄  ▄  ▄  █▀▀ ▀▄█ ▄▀█▀█▄▀▄▀▄    ▀▀▀ ████
████ ██ ▀▄▄  ▄ █▄█▄▀ ▀█ ▄ ▄ ▀▄▄ █▄▄▄▄▄▄█ ▄█ █▄█▄ ▄▄ █ █▀▀▀███▀  ▀▄▄█ ▄███▀ █▀█▄▀▀██▄█████
████   █▀▄▄▄▀▄▄█▄██▀▄▄   ██▄█▀▀▄▀ ▄▀█▀   █  ▄█ █▀▀▄ ▄▀▄▀ █▀ ▄█▄██▀▀ ▀▀█▄▄ ▄█▄█ ▀  █ ▄████
████▄ ▄ ▄ ▄▄▀ █▀█▀  ▄  █▄█▄ ██▄▀ ▄ ▄▄▄▄██ ▀▀█▄▀█▄▄▄▄▀  ▀  ███  █▀█▄▀▄█▄▄█ ▀▀▀▀█▄▄▄▄▄▀████
████▀█ ▀█▀▄  ▄▀▄▄▀ ▄█▄▄▄ ▄▀█▄▀████▄  ▀ ▀ █▄▀██▄█ ▀  ▄█▄█▄█▄▀█▄▀  ▀▀▄ ██ ▄ ▄▄▄▀▄█ ▄▀▀▄████
████▄▄████▄▄█▀██▀ ▀▀█▄▄ ▄▀ ▄▀▄▄▄▄  ▄█▄  █▀▄▀█  █▀▄▄█▄▄▀▄▀▄▄▄▀  ▄█ █▄ ▀█▀▀ ▀▀▀█▀█  █▄▄████
█████ █ ▀▄▄█  █ ▀ ▀██▀▀▀▄▄█▄▄▄ ▀ ▄  █▀█▀▄▄  ▀ ▀ █▀█  ▄▄ ▄▄█▀▄▄█▄▄█▀█▄█▄ ▄▄█▄▀▄ █▀▀▄ █████
████ █▄▄▀▀▄ ▄█▀ █▄▄█▄ ▀▀▄ █ ▄▀█ █ ▄▄ ▄▀  ▀ ▀▀ █▄▄▄▄▀██ █  ▄ █▀▄▀█▀██▀ ▄▄█▀▀ ▀▄ ▄█▄█ ▄████
████ ▀▄  ▄▄▀▀▄▀ ▀█▄▄▀▄ █▄███▀▀  ▄▄ ▀ ██▀ ▀▄▄ ▄   █▀▄ ▀█ ██ ▄▄▀ █▄▀▀▀ ██▀ █▀▀▄▀ ▄▄▀█▀ ████
█████ ▄▄█▀▄    █▀▀▀ █ ▀▀▄▀▄ █▄▀▄▄█▀  ▄▄▀▄█▀▀█▀█▄▀▄█▄▄ █▀▀▄██▀▄▀ █▀▄   █  ▄▀▄▄ █▄ ▄▀██████
█████▄▄▄██▄█▀▄█▄ ▀▀ ▀▄▄  ▄ █ ▄▄▄ ▄ ▀ █ █ █▀█▀▀ ▀▄ ▀▀ ▄▄▄ █   █ █▄▀▀▀███ ▀▀ █ ▄▄▄ ▀██▄████
████ ▄▄▄▄▄ █▀██▀██▄▄▀█ █ ▄▄█ █▄█ ▄▄ █▄ ▀█▀▀▀▀▄▀▀▄▄▀▄ █▄█ ▄ █▀█  ██▄▀▄▀ ▄▀▄▀▄ █▄█ ▀███████
████ █   █ █▄█▄ █▀██  █ ▄ ▀▄▄▄▄ ▄█ ▄ ▄ █ ▄█▄▀▄▄▄ █▄█ ▄ ▄ ▀██ █▄▄█▀▄▄ ▄▀█▄▄▄█  ▄▄ █▀▀ ████
████ █▄▄▄█ █▀ ▄█▀█▄ █ ▀██▄▄▄▀▀█▀█▄▀██ █████▀▀▄▀█▀▄▄ ▀ ▄▄▄▄▄▀█▀ ▄▀██▀ ▀█▀█ ▀▀ ▀ ▀ ▄███████
████▄▄▄▄▄▄▄█▄██▄▄█▄▄▄▄██▄▄▄██▄▄▄▄█▄████▄▄███▄█▄▄▄▄██▄███▄████▄▄█▄▄█████▄█▄▄█▄▄▄▄████▄████
█████████████████████████████████████████████████████████████████████████████████████████
█████████████████████████████████████████████████████████████████████████████████████████

Your client config file is in /home/ubuntu/wg0-client-ibtisam.conf
If you want to add more clients, you simply need to run this script another time!

WireGuard is running.
You can check the status of WireGuard with: systemctl status wg-quick@wg0


If you don't have internet connectivity from your client, try to reboot the server.
ubuntu@ip-172-31-83-184:~$ cat /home/ubuntu/wg0-client-ibtisam.conf
[Interface]
PrivateKey = sFDmKg3sb0Els3V8T0YDgUqlDolJjuApOPOn9kLqSUs=
Address = 10.66.66.2/32,fd42:42:42::2/128
DNS = 1.1.1.1,1.0.0.1

# Uncomment the next line to set a custom MTU
# This might impact performance, so use it only if you know what you are doing
# See https://github.com/nitred/nr-wg-mtu-finder to find your optimal MTU
# MTU = 1420

[Peer]
PublicKey = l5RMen7ouvY8UwXB7tR0hCGnKvyigfhha7ssT69pu14=
PresharedKey = ADHAzUhjwoSdl6DriOrkuUZqaI8k4ZXLS6UvFvCGs7I=
Endpoint = 54.163.181.14:62722
AllowedIPs = 0.0.0.0/0,::/0
ubuntu@ip-172-31-83-184:~$ curl ipinfo.io
{
  "ip": "54.163.181.14",
  "hostname": "ec2-54-163-181-14.compute-1.amazonaws.com",
  "city": "Ashburn",
  "region": "Virginia",
  "country": "US",
  "loc": "39.0437,-77.4875",
  "org": "AS14618 Amazon.com, Inc.",
  "postal": "20147",
  "timezone": "America/New_York",
  "readme": "https://ipinfo.io/missingauth"
}ubuntu@ip-172-31-83-184:~$
```

