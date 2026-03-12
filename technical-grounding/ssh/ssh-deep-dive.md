# SSH — How It Actually Works

SSH lets you log into a remote machine securely over a network. Port 22 is where it listens. But the real thing to understand is *what happens when you connect* — specifically the two phases every SSH connection goes through.

---

## The Two Phases

Every SSH connection has exactly two phases:

| Phase | What Happens |
|---|---|
| **Phase 1 — Tunnel** | An encrypted channel is built so nothing you send can be read by anyone in between |
| **Phase 2 — Auth** | You prove your identity to the server inside that encrypted channel |

Phase 1 always completes first. Your password or private key never travels unencrypted.

---

## Phase 1 — Building the Tunnel

When you run `ssh user@server-ip`:

1. TCP connection is made to port 22
2. Both sides agree on which encryption algorithms to use
3. A shared session key is generated using **Diffie-Hellman** — both sides independently compute the same secret without ever sending it over the wire
4. All further communication is encrypted with this key
5. The server sends its **host key** — the client checks `~/.ssh/known_hosts` to verify this is the right server

The important thing: **no key is ever transmitted**. Both sides compute the same session key independently.

---

## Phase 2 — Authentication

Once the tunnel is up, the server asks: prove who you are.

### Public Key Authentication (the standard)

1. Server looks up your public key in `~/.ssh/authorized_keys`
2. Server sends a **random challenge** — a unique string
3. Your machine **signs** the challenge using your **private key** — locally
4. Server **verifies** the signature using your public key
5. Match → you are in

```
YOUR MACHINE                              SERVER
────────────                              ──────
ssh user@IP  ──────────────────────────►  checks authorized_keys
             ◄──── random challenge ────  "prove it: a7f3k9x2..."
Sign(challenge, private_key)
             ────── signature ──────────► verify(signature, public_key) ✅
```

**The private key never leaves your machine.** Not even inside the encrypted tunnel.

---

## The `.ssh` Directory — What Lives There

| File | Created By | Lives On | Purpose |
|---|---|---|---|
| `id_ed25519` | `ssh-keygen` | Your machine only | Your private key — signs challenges |
| `id_ed25519.pub` | `ssh-keygen` | Your machine + every server you access | Your public key — copied to servers |
| `authorized_keys` | You / system | The **server** | List of public keys allowed to SSH in |
| `known_hosts` | SSH automatically | Your machine (client) | Fingerprints of servers you have connected to |
| `config` | You manually | Your machine | Shortcuts and per-host settings |

### Core Rule

```
id_ed25519 + id_ed25519.pub  →  you SSH OUT to other servers
authorized_keys              →  others SSH IN to this machine
```

A machine can play both roles at once — which is why a lab machine like `dev-machine` has all files present.

---

## The `authorized_keys` File Format

Each line is one public key, in three parts:

```
ssh-ed25519  AAAAC3NzaC1lZDI1NTE5AAAA...  laborant@k8s-omni (managed)
    ①               ②                              ③
```

| Part | Name | Effect |
|---|---|---|
| `ssh-ed25519` | Key type | Algorithm used |
| `AAAAC3...` | Key data | The actual cryptographic material |
| `laborant@k8s-omni` | Comment | Human label only — SSH ignores it completely |

---

## The `known_hosts` File

This lives on the **client**. It records the fingerprint of every server you have connected to.

First connection to a new server:
```
The authenticity of host '13.x.x.x' can't be established.
ED25519 key fingerprint is SHA256:xK9mN2...
Are you sure you want to continue connecting? (yes/no)?
```

Type `yes` → fingerprint saved. Every future connection silently verifies it matches.

If it does not match (server rebuilt, or an attack):
```
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```
SSH blocks the connection. This is not a bug — it is working correctly.

---

## `ssh-keygen` — What It Does

```bash
ssh-keygen -t ed25519 -C "label@machine"
```

Generates two files:
- `~/.ssh/id_ed25519` — private key
- `~/.ssh/id_ed25519.pub` — public key

You run this **once** on your machine. The files stay there permanently. Some systems (AWS EC2, lab environments) auto-generate a key pair during provisioning — so a fresh machine may already have one.

---

## One Private Key — Many Servers

This is the most important thing to understand clearly.

You do not need a separate private key per server. You need **one private key on your machine** and your **public key on every server**.

```
YOUR MACHINE
├── ~/.ssh/id_ed25519        ← stays here, never moves
└── ~/.ssh/id_ed25519.pub    ← copy of this goes to every server

SERVER-01  authorized_keys → your public key
SERVER-02  authorized_keys → your public key
...
SERVER-50  authorized_keys → your public key

ssh user@server-01  → id_ed25519 signs → ✅
ssh user@server-50  → id_ed25519 signs → ✅
```

One key. Fifty servers. The private key never moves.

---

## Two Patterns: Generic vs AWS EC2

There are two real-world patterns. The mechanism is identical — only who generates the key pair differs.

### Pattern 1: Self-Managed (Generic)

You generate the key pair yourself.

```bash
# Step 1: Generate key pair (once, on your machine)
ssh-keygen -t ed25519 -C "your-label"

# Step 2: Copy public key to the server
ssh-copy-id user@server-ip
# → appends id_ed25519.pub into server's authorized_keys

# Step 3: Connect
ssh user@server-ip
# → SSH finds ~/.ssh/id_ed25519 automatically (default location)
# → no -i flag needed
```

### Pattern 2: AWS EC2

AWS generates the key pair on your behalf.

```bash
# Step 1: In AWS Console → create key pair during EC2 launch
# → AWS generates the key pair
# → AWS injects the public key into EC2's authorized_keys
# → You download the private key as a .pem file

# Step 2: Fix permissions
chmod 400 ~/.ssh/my-key.pem

# Step 3: Connect
ssh -i ~/.ssh/my-key.pem ec2-user@ec2-ip
# → -i needed because key is not at default location
```

### The `.pem` File Is YOUR Private Key

This confuses almost everyone. The `.pem` file AWS gives you is **not the EC2 server's key**. It is **your** private key — AWS generated it on your behalf and handed it to you.

- AWS does not keep a copy
- The EC2 server has your **public key** in its `authorized_keys`
- You use the `.pem` (your private key) to sign the challenge in Phase 2
- If you lose the `.pem`, AWS cannot recover it — because it was always yours

### Using Your Existing Key with EC2 (Recommended)

You do not have to use AWS-generated keys. You can import your own:

```bash
# Register your existing public key with AWS
aws ec2 import-key-pair \
  --key-name "my-macbook-key" \
  --public-key-material fileb://~/.ssh/id_ed25519.pub
```

Select `my-macbook-key` when launching EC2. Now connect without any `-i` flag:

```bash
ssh ec2-user@ec2-ip
# SSH finds ~/.ssh/id_ed25519 automatically
```

Same one key. Works for EC2 too.

---

## Why `-i` Is Sometimes Needed and Sometimes Not

SSH looks for private keys in these default locations automatically:

```
~/.ssh/id_ed25519
~/.ssh/id_ecdsa
~/.ssh/id_rsa
```

If your key is there — no `-i` needed.  
If your key has a different name or location (like `my-key.pem`) — specify it:

```bash
ssh -i ~/Downloads/my-key.pem ec2-user@server-ip
```

The `-i` flag is not about *whether* the private key is used — it is always used. It is about whether SSH can *find* it on its own.

---

## Two Key Pairs on Every SSH Connection

There are actually **two** key pairs involved in every connection — for different purposes:

| Key Pair | Belongs To | Used In | You Have |
|---|---|---|---|
| Your user key pair | You | Phase 2 — you prove your identity | Both private + public |
| Server's host key pair | The server | Phase 1 — server proves its identity | Only the fingerprint (in `known_hosts`) |

The server's private key lives at `/etc/ssh/ssh_host_ed25519_key` — inside the server, never accessible to you. You only ever see its fingerprint. These are completely separate from your user key pair and serve a different purpose.

---

## File Permissions — Why SSH Enforces Them

SSH refuses to use key files that are too permissive. If others on the system can read your private key, the key is worthless.

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/authorized_keys
```

If permissions are wrong, SSH prints:
```
WARNING: UNPROTECTED PRIVATE KEY FILE!
```
Fix: `chmod 600 ~/.ssh/id_ed25519`

---

## Common Errors

### `Permission denied (publickey)`
Your public key is not in the server's `authorized_keys`, or SSH could not find your private key.
```bash
ssh -v user@server-ip     # shows exactly what SSH is trying
cat ~/.ssh/id_ed25519.pub # compare with server's authorized_keys
```

### `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`
Server fingerprint changed (server rebuilt, or possible attack).
```bash
ssh-keygen -R server-ip   # remove old entry
ssh user@server-ip        # reconnect and save new fingerprint
```

### `WARNING: UNPROTECTED PRIVATE KEY FILE!`
```bash
chmod 600 ~/.ssh/id_ed25519
```

---

## Quick Reference

```bash
# Generate key pair
ssh-keygen -t ed25519 -C "label@machine"

# Copy public key to a server
ssh-copy-id user@server-ip

# Connect (key at default location)
ssh user@server-ip

# Connect (key at custom path)
ssh -i ~/.ssh/my-key.pem ec2-user@server-ip

# Debug a failing connection
ssh -v user@server-ip

# Fix known_hosts after server rebuild
ssh-keygen -R server-ip

# View your public key
cat ~/.ssh/id_ed25519.pub

# View who can SSH into this machine
cat ~/.ssh/authorized_keys

# View servers you have connected to before
cat ~/.ssh/known_hosts
```
