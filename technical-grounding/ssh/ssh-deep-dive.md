# SSH — How It Actually Works

## The Problem SSH Solves

Before SSH, tools like Telnet were used for remote login. Every keystroke — including your password — was sent as plain text across the network. Anyone sniffing traffic between you and the server could read everything.

SSH (Secure Shell) was created in 1995 to solve this. It wraps the entire session in encryption. But the real challenge it solves is deeper:

> How do two strangers (a client and a server) communicate securely over an untrusted network, without ever having shared a secret before?

Understanding SSH means understanding how it answers that question.

---

## The Two Phases of Every SSH Connection

Every SSH connection happens in exactly two phases. They are distinct and serve completely different purposes.

| Phase | Name | What Happens | Who Does What |
|---|---|---|---|
| **Phase 1** | Tunnel Setup | An encrypted channel is built between client and server | Both sides, using math (Diffie-Hellman) |
| **Phase 2** | Authentication | The user proves their identity inside that encrypted channel | Client signs a challenge; server verifies |

Phase 1 must complete before Phase 2 starts. Your password or private key never travels over an unencrypted connection — Phase 1 builds the tunnel first.

---

## Phase 1: Building the Encrypted Tunnel

### Step-by-Step

When you run `ssh user@server-ip`, this is what happens before you are ever asked to authenticate:

1. **TCP connection** — Your client connects to port 22 on the server.
2. **Version exchange** — Both sides announce their SSH version (SSH-2 is the standard today).
3. **Algorithm negotiation** — Both sides share lists of supported encryption, hashing, and compression algorithms. They agree on the best mutually supported set.
4. **Key exchange (Diffie-Hellman)** — This is the cryptographic magic step. Both sides independently generate a shared secret without ever sending that secret over the wire.
5. **Symmetric session key established** — All further traffic is encrypted with this key.
6. **Server host key verification** — The client checks whether it recognizes this server.

### The Diffie-Hellman Key Exchange — Why It Matters

The problem: two parties need to agree on a secret key, but they can only communicate over a public channel.

Here is how it works:

- Both client and server independently generate a private random number. This number never leaves their machine.
- Each side computes a public value from that private number using mathematical operations (elliptic curve or modular arithmetic).
- They exchange these public values. An attacker can see these values — that is fine.
- Each side then combines **their own private number** with **the other side's public value** using the same math formula. Both sides arrive at the same result.
- That result becomes the **shared session key** — used to encrypt all further communication.

The attacker can see the public values flying across the network but cannot derive the shared secret without the private numbers, which never left either machine.

```
YOUR MACHINE                           SERVER
────────────                           ──────
Generate private: a                    Generate private: b
Compute public:   A = g^a mod p        Compute public:   B = g^b mod p

Send A ─────────────────────────────► Receives A
Receives B ◄──────────────────────── Send B

Compute: B^a mod p                     Compute: A^b mod p
         = (g^b)^a mod p                        = (g^a)^b mod p
         = g^(ab) mod p      ←SAME→            = g^(ab) mod p

         ✅ Both sides have the same key. No key was ever sent.
```

---

## Phase 2: Authentication — Proving Who You Are

Once the encrypted tunnel exists, the server asks: prove your identity. There are two main methods.

### Method A: Password Authentication

- You type a password.
- It is sent inside the encrypted tunnel (not visible to anyone on the network).
- The server checks it against its records.
- **Weakness:** Brute-forceable, phishable, and dependent on a human-memorable secret.

### Method B: Public Key Authentication (The Standard for DevOps)

This is the method used with GitHub, EC2, lab environments, and any serious infrastructure. Here is the exact mechanism:

1. You generate a key pair using `ssh-keygen`.
2. Your **public key** is placed on the server inside `~/.ssh/authorized_keys`.
3. When you connect, the server picks your public key from its list and sends you a **random challenge** — a unique string generated for this session only.
4. Your machine **signs** that challenge using your **private key** — locally, without sending the private key anywhere.
5. The server **verifies the signature** using your public key.
6. If the signature is valid, you are authenticated.

**The private key never leaves your machine.** Not even inside the encrypted tunnel.

```
YOUR MACHINE                              SERVER
────────────                              ──────
ssh user@IP  ──────────────────────────►  "I have your public key.
                                           Prove you hold the private key."

             ◄────── random challenge ────  "Here is a random string: a7f3k9x2..."

Sign(challenge, private_key)
             ────── signature ──────────►  verify(signature, public_key)
                                           "Match. Welcome in." ✅
```

---

## The `.ssh` Directory — What Lives There

The `~/.ssh` folder is where OpenSSH stores all its key material and configuration. It is created automatically the first time you use any SSH command.

Here is every file you will encounter and what it does:

| File | Created By | Purpose | Lives On |
|---|---|---|---|
| `id_ed25519` | `ssh-keygen` | Your **private key** — proves your identity when SSHing out | Your machine only |
| `id_ed25519.pub` | `ssh-keygen` | Your **public key** — copied to servers you want access to | Your machine + shared |
| `authorized_keys` | You / system | List of public keys allowed to SSH **into** this machine | Server / target machine |
| `known_hosts` | SSH automatically | Fingerprints of servers you have connected to before | Your machine (client) |
| `known_hosts.old` | SSH automatically | Backup of the previous `known_hosts` after an update | Your machine |
| `config` | You manually | Shortcuts and connection settings for SSH targets | Your machine |

### The Core Mental Model

```
id_ed25519 + id_ed25519.pub  →  Used when YOU SSH OUT to other servers
authorized_keys              →  Used when OTHERS SSH IN to this machine
```

A machine can play both roles simultaneously. Your `dev-machine` in a lab environment might have all four files — because it both connects to other machines and accepts incoming connections.

---

## The Two Key Files Compared

### `authorized_keys` — The Guest List

This file lives on the **server**. Each line is one public key. Any client whose private key matches a public key in this file is allowed in.

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...long-key...  conductor@labs.iximiuz.com
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...long-key...  laborant@k8s-omni (managed)
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...long-key...  laborant@tunnel
```

Each line has three parts:

| Part | Example | Meaning |
|---|---|---|
| Key type | `ssh-ed25519` | The algorithm used to generate this key |
| Key data | `AAAAC3NzaC1...` | The actual cryptographic material (Base64 encoded) |
| Comment | `conductor@labs.iximiuz.com` | A human-readable label — **has no technical effect** |

The comment is just metadata. You can write anything there. SSH ignores it entirely during authentication. Its only purpose is to help you remember which machine or person that key belongs to.

### `known_hosts` — Your Server Address Book

This file lives on the **client**. It stores the fingerprints of servers you have connected to before.

First time you SSH into a new server:

```
The authenticity of host '13.245.67.89' can't be established.
ED25519 key fingerprint is SHA256:xK9mN2pQrS...
Are you sure you want to continue connecting? (yes/no)?
```

You type `yes`. The server's fingerprint is saved to `~/.ssh/known_hosts`. Every future connection automatically checks that the fingerprint still matches.

If the fingerprint changes (server was replaced, or a Man-in-the-Middle attack is in progress), SSH blocks the connection immediately with a hard error:

```
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```

This is not a bug — it is SSH doing its job.

---

## `ssh-keygen` — What It Does and Why

`ssh-keygen` is a tool that mathematically generates a linked key pair. You cannot create these by hand — the public and private keys must be mathematically related through elliptic curve cryptography (or RSA for older systems).

```bash
ssh-keygen -t ed25519 -C "your-label-here"
```

This single command does three things:

1. Generates a **private key** → saves to `~/.ssh/id_ed25519`
2. Derives the **matching public key** → saves to `~/.ssh/id_ed25519.pub`
3. Embeds the comment (`-C` flag) into both files as metadata

You run this **once manually** on your machine. After that, the files are permanent. Some systems (like AWS EC2 or cloud lab environments) auto-generate keys during provisioning — which is why a freshly started lab machine may already have a key pair.

### Why Ed25519 and Not RSA?

`ed25519` is the modern standard. It produces shorter keys, is faster, and is considered more secure than RSA-2048. Always prefer `-t ed25519` when generating new keys.

---

## How Public Key Authentication Works with Multiple Servers

A common point of confusion: if you copy your public key to 20 servers, where does the private key come in?

Here is the answer:

```
YOUR MACHINE
├── ~/.ssh/id_ed25519        ← one private key, stays here always
└── ~/.ssh/id_ed25519.pub    ← this gets copied to every target server

SERVER-01  ~/.ssh/authorized_keys  ← contains your pub key
SERVER-02  ~/.ssh/authorized_keys  ← contains your pub key
...up to...
SERVER-20  ~/.ssh/authorized_keys  ← contains your pub key
```

When you connect to any of these servers, the server issues a challenge. Your machine signs it locally using the private key. The server verifies the signature using the public key it has stored.

**One private key. Works against all 20 servers.** The private key never moves.

Think of it this way:
- Public key = a lock you install on a door
- Private key = the key you carry in your pocket

You can install copies of your lock on 20 doors. You still only carry one key.

---

## Two Ways to Set Up SSH Access

There are two real-world patterns you will encounter. They differ in who generates the key pair and where the private key ends up.

### Pattern 1: Self-Managed Server (Generic)

You control both machines. You generate your own key pair.

```
Step 1: Generate key pair on your machine (once)
        ssh-keygen -t ed25519 -C "your-label"
        → Creates ~/.ssh/id_ed25519 and ~/.ssh/id_ed25519.pub

Step 2: Copy your public key to the server
        ssh-copy-id user@server-ip
        → Appends your pub key into server's ~/.ssh/authorized_keys

Step 3: Connect
        ssh user@server-ip
        → SSH finds ~/.ssh/id_ed25519 automatically (default location)
        → No -i flag needed
```

### Pattern 2: AWS EC2

AWS manages the key pair for you at launch time.

```
Step 1: In AWS Console, create a key pair during EC2 launch
        → AWS generates the key pair
        → AWS injects the public key into EC2's authorized_keys automatically
        → You download the private key as a .pem file

Step 2: Set correct permissions on the .pem file (required by SSH)
        chmod 400 ~/.ssh/my-key.pem

Step 3: Connect
        ssh -i ~/.ssh/my-key.pem ec2-user@ec2-public-ip
        → -i flag is required because the key is not in the default location
```

### Why `-i` Is Sometimes Required and Sometimes Not

SSH automatically looks for private keys in these default locations, in order:

```
~/.ssh/id_ed25519
~/.ssh/id_ecdsa
~/.ssh/id_rsa
~/.ssh/id_dsa
```

If your private key is at one of these paths, SSH finds it automatically and you do not need `-i`.

If your private key is somewhere else — like `~/Downloads/my-key.pem` or has a custom name — SSH will not find it. You must point to it explicitly with `-i`.

```bash
# Key is at default location — SSH finds it automatically
ssh user@server-ip

# Key is at a non-default location — must specify
ssh -i ~/Downloads/my-key.pem ec2-user@server-ip
```

In both cases, the private key is used. The `-i` flag is not about whether the key is used — it is about whether SSH can find it on its own.

---

## The Complete SSH Connection Flow

Here is every step that happens when you run `ssh user@IP`, from the moment you press Enter to the moment a shell appears:

```
YOUR MACHINE (CLIENT)                       SERVER
─────────────────────                       ──────

[1] TCP SYN to port 22 ────────────────────► sshd daemon is listening
    ◄──────────────── TCP ACK ─────────────  "Connected"

[2] Version strings exchanged
    "SSH-2.0-OpenSSH_9.0"  ◄────────────────►  "SSH-2.0-OpenSSH_8.9"

[3] Algorithm negotiation
    "I support: chacha20, aes256, ..."  ◄──►  "I support: chacha20, aes128, ..."
    → Both agree on best shared set

[4] Diffie-Hellman key exchange
    Public value A  ──────────────────────►
    ◄─────────────────────────────────────  Public value B
    [Both independently compute same session key — key never transmitted]

[5] Server sends HOST KEY (its identity)
    ◄────────── Server's host public key ──
    Client checks ~/.ssh/known_hosts:
    → First time: "Are you sure? (yes/no)" → saves fingerprint
    → Known host: silently verifies fingerprint matches
    → Mismatch: HARD ERROR — connection blocked

    ════════ ALL TRAFFIC NOW ENCRYPTED ════════

[6] Authentication
    "I am 'user', using public key auth"  ────────────────────────────────►
    ◄──────────────────────────────────── "Prove it. Challenge: a7f3k9x2..."
    Sign(challenge, private_key) ─────────────────────────────────────────►
    ◄──────────────────────────────────── verify(signature, public_key) ✅

[7] Shell session begins ✅
```

---

## File Permissions — Why SSH Is Strict

SSH will refuse to use key files if their permissions are too open. This is a security feature — if other users on the system can read your private key, the key is compromised.

```bash
# Required permissions
chmod 700 ~/.ssh                  # Only you can read/write/execute the directory
chmod 600 ~/.ssh/id_ed25519       # Only you can read/write the private key
chmod 644 ~/.ssh/id_ed25519.pub   # Public key — others may read it
chmod 600 ~/.ssh/authorized_keys  # Only you can read/write
chmod 644 ~/.ssh/known_hosts      # Read access is fine
```

If permissions are wrong, SSH will print:

```
WARNING: UNPROTECTED PRIVATE KEY FILE!
Permissions 0644 for '/home/user/.ssh/id_ed25519' are too open.
It is required that your private key files are NOT accessible by others.
```

Fix it with `chmod 600 ~/.ssh/id_ed25519` and SSH will work again.

---

## Summary: The Two Phases Revisited

```
PHASE 1: "Build a secure tunnel"
─────────────────────────────────
Problem:  Both sides need to encrypt traffic, but they have never met.
Solution: Diffie-Hellman — both sides compute the same key independently.
Result:   All further communication is encrypted.
Files:    known_hosts (client verifies server identity during this phase)


PHASE 2: "Prove who you are"
─────────────────────────────
Problem:  Server needs to know this is really you, not an impersonator.
Solution: Challenge-response — server sends a random challenge,
          client signs it with private key, server verifies with public key.
Result:   Authenticated. Shell is granted.
Files:    authorized_keys (server checks if your public key is listed)
          id_ed25519 (your machine uses this to sign the challenge)
```

### The Three Files at a Glance

| File | Who Owns It | What It Controls | Direction |
|---|---|---|---|
| `id_ed25519` | Client | Signs challenges to prove identity | Outgoing SSH |
| `id_ed25519.pub` | Client (shared to server) | Installed on server; used to verify signatures | Outgoing SSH |
| `authorized_keys` | Server | List of clients allowed to connect | Incoming SSH |
| `known_hosts` | Client | List of servers already trusted | Outgoing SSH |

---

## Common Mistakes and Errors

### `Permission denied (publickey)`

Either your public key is not in the server's `authorized_keys`, or SSH could not find your private key. Check:

```bash
# Debug mode — shows exactly what SSH is trying
ssh -v user@server-ip

# Does the server have your public key?
cat ~/.ssh/id_ed25519.pub
# Compare this to what is in server's ~/.ssh/authorized_keys
```

### `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`

The server's fingerprint changed. This can happen legitimately (server was rebuilt) or indicate an attack. If you rebuilt the server yourself:

```bash
ssh-keygen -R server-ip    # removes the old entry from known_hosts
ssh user@server-ip         # connect fresh — will prompt to add new fingerprint
```

### `WARNING: UNPROTECTED PRIVATE KEY FILE!`

File permissions on your private key are too loose:

```bash
chmod 600 ~/.ssh/id_ed25519
```

### Forgot to copy public key before trying to connect

You must copy your public key to the server **before** trying to authenticate with it. Password access (if enabled) can be used for this first step:

```bash
ssh-copy-id user@server-ip
# This copies ~/.ssh/id_ed25519.pub into server's authorized_keys
```

---

## Quick Reference

```bash
# Generate a new key pair
ssh-keygen -t ed25519 -C "label@machine"

# Copy your public key to a server
ssh-copy-id user@server-ip

# Connect (key at default location)
ssh user@server-ip

# Connect (key at custom location — e.g., EC2 .pem)
ssh -i ~/.ssh/my-key.pem ec2-user@server-ip

# Debug connection issues
ssh -v user@server-ip

# Fix known_hosts entry after server rebuild
ssh-keygen -R server-ip

# Fix private key permissions
chmod 600 ~/.ssh/id_ed25519
chmod 700 ~/.ssh

# View your public key (what you copy to servers)
cat ~/.ssh/id_ed25519.pub

# View what keys are authorized to SSH into this machine
cat ~/.ssh/authorized_keys

# View which servers your machine has connected to before
cat ~/.ssh/known_hosts
```
