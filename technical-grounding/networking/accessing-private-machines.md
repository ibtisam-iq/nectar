# Accessing Services on Private Machines

## The Problem

You have a service running on a machine. You want to open it in your browser. But it does not work.

This guide explains **why** that happens and **exactly how to fix it** — using two different techniques depending on your situation.

---

## Foundation: What is a Port?

Every computer has thousands of numbered **ports** — think of them as doors on a building.

- Each running service opens one door and waits for traffic.
- Port `80` → HTTP web traffic
- Port `8080` → Jenkins
- Port `443` → HTTPS
- Port `22` → SSH (remote login)
- Port `18789` → OpenClaw Gateway (in this example)

When you type `http://someserver:8080` in a browser, you are knocking on door number 8080 of that server.

---

## Foundation: What is `127.0.0.1`?

Every computer has a special address: `127.0.0.1` — also called **localhost**.

It means: **"myself"**.

When a service binds to `127.0.0.1:8080`, it is saying:

> "I am only available to processes running on this same machine. Nobody from outside can reach me."

This is important. If Jenkins or OpenClaw is listening on `127.0.0.1:8080`, that port is **invisible to the outside world**. Even if you know the server's IP address, you cannot reach that port from your laptop.

---

## The Core Problem: Public IP vs. Private / NAT'd Machines

### Scenario A: Machine WITH a Public IP (e.g., AWS EC2)

```
[Your Laptop]  ──internet──▶  [EC2: 54.123.45.67]
                                    │
                               Nginx :80
                                    │
                               Jenkins :8080
```

- EC2 has a real public IP assigned by AWS.
- You add that IP to Cloudflare DNS as an A record.
- You open `http://jenkins.yourdomain.com` → browser reaches EC2 directly.
- **Works out of the box.** ✅

### Scenario B: Machine WITHOUT a Public IP (e.g., iximiuz Lab, Private VPC, Docker container)

```
[Your Laptop]  ──internet──▶  ???
                          (No route exists)
                                    │
                          [iximiuz VM: 172.16.0.2]
                                    │
                               Jenkins :8080
```

- The VM lives inside a private network.
- iximiuz, for example, runs all VMs behind **NAT** — all labs share one outbound IP.
- When you run `curl ifconfig.me` inside the VM, you get the shared NAT IP — not the VM's real address.
- You cannot create a DNS A record pointing to that shared NAT IP and expect it to reach your specific VM.
- **Direct access is impossible.** ❌

This is the wall you hit. The question is: **how do you break through it?**

There are exactly two solutions.

---

## Solution 1: Cloudflare Tunnel — The Machine Reaches Out

### The Concept

Instead of you trying to reach the machine from outside (which fails because there is no public IP), you flip the direction: **the machine reaches out to Cloudflare**.

You install a small daemon called `cloudflared` inside the private machine. It establishes a persistent outbound connection to Cloudflare's edge network. Cloudflare then gives you a public URL. Anyone who opens that URL goes through Cloudflare, which forwards the request back through the tunnel to your machine.

```
[Browser / Internet]
        │
        ▼
[Cloudflare Edge: jenkins.yourdomain.com]
        │
        │  (existing outbound tunnel)
        ▼
[Private VM: cloudflared daemon]
        │
        ▼
[Jenkins :8080]  ✅
```

The VM never needs an inbound firewall rule. It never needs a public IP. It just needs outbound internet access — which almost every machine has.

### When to Use Cloudflare Tunnel

- You want **anyone on the internet** to access the service.
- You want a **permanent, stable public URL** like `jenkins.ibtisam-iq.com`.
- You want the tunnel to **survive reboots** (run cloudflared as a systemd service).
- You are exposing services for your **team or public users**.
- You have no control over firewall rules or public IP assignment.

### Setup: Step by Step

#### Step 1: Install cloudflared inside the VM

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/
```

#### Step 2: Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This opens a browser URL. Log into your Cloudflare account and authorize the domain you want to use.

#### Step 3: Create a named tunnel

```bash
cloudflared tunnel create jenkins-tunnel
```

This creates a tunnel and stores credentials at `~/.cloudflared/<tunnel-id>.json`.

#### Step 4: Create the config file

```bash
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml <<EOF
tunnel: jenkins-tunnel
credentials-file: /home/YOUR_USER/.cloudflared/<TUNNEL-ID>.json

ingress:
  - hostname: jenkins.yourdomain.com
    service: http://localhost:8080
  - service: http_status:404
EOF
```

Replace `YOUR_USER`, `TUNNEL-ID`, and `yourdomain.com` with your actual values.

#### Step 5: Add DNS record in Cloudflare

Go to Cloudflare Dashboard → Zero Trust → Networks → Tunnels.  
Or run:

```bash
cloudflared tunnel route dns jenkins-tunnel jenkins.yourdomain.com
```

This creates a CNAME record pointing `jenkins.yourdomain.com` to your tunnel — not to an IP address.

#### Step 6: Run the tunnel

```bash
# Test run (foreground):
cloudflared tunnel run jenkins-tunnel

# Production (as systemd service):
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

#### Verify

Open `https://jenkins.yourdomain.com` in any browser anywhere in the world. ✅

---

## Solution 2: SSH Tunnel — You Dig In

### The Concept

SSH tunneling is a feature built into the SSH protocol. It lets you forward a port from your local machine through an encrypted SSH connection to a remote machine.

You **already have SSH access** to the private machine (via a proxy, a jump host, or direct). You use that existing SSH connection to create a **pipe** that maps a port on your laptop to a port inside the remote machine.

```
[Your Laptop: localhost:8080]
        │
        │  SSH encrypted tunnel
        ▼
[Private VM: 127.0.0.1:8080]
        │
        ▼
[Jenkins :8080]  ✅  (only visible to YOU)
```

After the tunnel is up, you open `http://localhost:8080` on your own laptop — and traffic secretly travels through SSH to the remote machine.

### When to Use SSH Tunnel

- Only **you personally** need access — not a team or the public.
- You need **temporary / one-session** access.
- The service has a **sensitive token or admin credentials** (you do not want a public URL).
- You already have SSH access to the machine.
- Examples: database admin panels, internal dashboards, OpenClaw gateway, Kubernetes dashboard.

### The SSH Local Port Forward Command

```bash
ssh -N -L <local-port>:<remote-host>:<remote-port> <user>@<ssh-target> -p <ssh-port>
```

Breaking down each flag:

| Flag | Meaning |
|---|---|
| `-N` | Do not open a shell. Just run the tunnel. Terminal will appear frozen — that is correct. |
| `-L` | Local port forward. |
| `local-port` | Port you want to open on your laptop. |
| `remote-host` | The address **as seen from the remote machine**. Usually `127.0.0.1`. |
| `remote-port` | The port the service is running on inside the remote machine. |
| `user@ssh-target` | The SSH login target. |
| `-p` | SSH port (default is 22; proxies often use a different port). |

### Real Example: Accessing OpenClaw on an iximiuz Lab

The service (OpenClaw Gateway) was running on `127.0.0.1:18789` inside an iximiuz lab VM. The VM had no public IP. SSH access was available via `labctl ssh-proxy`.

#### Step 1: Start the SSH proxy (iximiuz specific)

```bash
labctl ssh-proxy <playground-id>
```

Example output:

```
SSH proxy is running on 53711

ssh -i /Users/yourname/.ssh/iximiuz_labs_user ssh://ibtisam@127.0.0.1:53711
```

This command starts a local SSH gateway on your laptop (port 53711). Leave it running in Terminal A.

> **Note:** The port number (53711 here) is assigned randomly each time. Always use the port from the current session's output — never a port from a previous session.

#### Step 2: Create the tunnel in a second terminal

```bash
ssh -N \
  -L 18789:127.0.0.1:18789 \
  -i ~/.ssh/iximiuz_labs_user \
  ibtisam@127.0.0.1 -p 53711
```

The terminal will go silent with no output. **That is correct.** It means the tunnel is active. Do not press Ctrl+C.

#### Step 3: Open the service in your browser

```text
http://localhost:18789/#token=YOUR_TOKEN_HERE
```

Your laptop's port 18789 is now forwarded to the VM's port 18789. The service loads in your local browser. ✅

#### Step 4: Tear down when done

- Close the browser tab.
- Press `Ctrl+C` in the tunnel terminal.
- Press `Ctrl+C` in the `labctl ssh-proxy` terminal.

---

## Why Did `curl ifconfig.me` Give the Wrong IP on iximiuz?

This confused many people. Here is the explanation.

`curl ifconfig.me` asks an external server: "what IP address do my requests come from?"

On AWS EC2, each instance has its own public IP. So the answer is unique per machine.

On iximiuz Labs, all VMs share one outbound NAT IP. When any VM makes an outbound request, it exits through the same shared gateway. So every VM gets the same answer from `ifconfig.me`.

```
iximiuz VM-01 ─┐
iximiuz VM-02 ─┼──▶ Shared NAT Gateway ──▶ Internet
iximiuz VM-03 ─┘
      ↑
  All appear as the same IP to the outside world
```

This means:

- You cannot point a DNS A record to that IP and expect it to route to your specific VM.
- Direct public access via IP is impossible for these VMs.
- You must use one of the two solutions described above.

---

## Side-by-Side Comparison

| | **Cloudflare Tunnel** | **SSH Tunnel** |
|---|---|---|
| **Direction** | VM dials OUT to Cloudflare | You dial IN through SSH |
| **Who can access?** | Anyone with the URL | Only you (on your machine) |
| **Requires public IP?** | No | No |
| **Requires SSH access?** | No | Yes |
| **URL format** | `https://jenkins.yourdomain.com` | `http://localhost:PORT` |
| **Persistent after reboot?** | Yes (if installed as systemd service) | No (must re-run each session) |
| **Best for** | Team services, production, demos | Personal access, sensitive dashboards, one-time use |
| **Setup complexity** | Medium (one-time Cloudflare setup) | Low (two terminal commands) |

---

## Decision Guide: Which One Should I Use?

```
Do you need other people to access the service?
│
├── YES → Use Cloudflare Tunnel
│         (public URL, permanent, team access)
│
└── NO  → Is it temporary / just for you?
           │
           ├── YES → Use SSH Tunnel
           │         (local access, no public URL, session-based)
           │
           └── Do you have SSH access to the machine?
                      │
                      ├── YES → SSH Tunnel works
                      └── NO  → Use Cloudflare Tunnel
```

---

## Common Mistakes

### 1. Using a stale proxy port

Every time you run `labctl ssh-proxy`, it picks a new port. If you close and reopen the proxy, the port changes. Using the old port gives:

```
ssh: connect to host 127.0.0.1 port 58279: Connection refused
```

Fix: Always copy the port from the current `labctl ssh-proxy` output.

### 2. Thinking the tunnel is broken because the terminal is frozen

`ssh -N` is designed to run silently. No output = working correctly. The moment you press Ctrl+C, the tunnel dies. Leave it running.

### 3. Adding the shared NAT IP to Cloudflare DNS as an A record

This will not work for NAT'd machines. Use a Cloudflare Tunnel (CNAME-based) instead — no IP address needed.

### 4. Trying to use `localhost` from inside the VM to test from outside

`localhost` inside the VM is the VM itself. `localhost` on your laptop is your laptop. They are different machines. The SSH tunnel bridges them — but only after you set it up.

---

## Quick Reference Commands

### Cloudflare Tunnel

```bash
# Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared && sudo mv cloudflared /usr/local/bin/

# Authenticate
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create my-tunnel

# Route DNS
cloudflared tunnel route dns my-tunnel service.yourdomain.com

# Run tunnel (foreground)
cloudflared tunnel run my-tunnel

# Run as systemd service
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

### SSH Tunnel

```bash
# Start SSH proxy (iximiuz)
labctl ssh-proxy <playground-id>

# Create local port forward (replace values with your actual port and user)
ssh -N \
  -L <local-port>:127.0.0.1:<remote-port> \
  -i ~/.ssh/iximiuz_labs_user \
  <user>@127.0.0.1 -p <proxy-port>

# Then open in browser:
# http://localhost:<local-port>/
```

---

## Summary

The core insight is this: when a machine has no public IP, you cannot reach it from the outside by default. But you have two ways to bridge that gap — and which one you choose depends entirely on **who needs access** and **how long they need it**.

- **Cloudflare Tunnel** = the private machine calls home to Cloudflare. Everyone can reach it via a public URL.
- **SSH Tunnel** = you personally dig a pipe from your laptop into the private machine. Only you can use it, only while the tunnel is running.

Understanding this pattern unlocks a large class of real-world DevOps problems: private Kubernetes clusters, internal databases, ephemeral lab environments, air-gapped systems, and more.
