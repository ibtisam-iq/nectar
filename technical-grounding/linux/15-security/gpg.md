# GPG

GnuPG (`gpg`) implements OpenPGP: key pairs that sign and encrypt files. On servers it matters mainly because package managers verify every package and repository against GPG keys, and because release files and backups are signed or encrypted with it.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Sign, encrypt | `gpg --armor --detach-sign FILE`, `gpg --verify FILE.asc FILE`; `gpg -e -r RECIPIENT FILE` or `gpg -c FILE`, `gpg -d` to decrypt | `echo $?` after verify |
| Keys | `~/.gnupg/` holds the keyring and, from creation, a revocation certificate; `gpg --armor --export ID` shares the public key | `gpg --show-keys key.asc` |
| RPM | Keys imported with `rpm --import`, listed as `gpg-pubkey` packages; `gpgcheck=1` and `gpgkey=` per repo | `rpm -q gpg-pubkey` |
| APT | Repository keys in `/usr/share/keyrings/` or `/etc/apt/keyrings/`, bound per repo with `Signed-By`, so a vendor key cannot sign other repositories; `apt-key` is deprecated | `grep Signed-By /etc/apt/sources.list.d/*` |
<!-- --8<-- [end:facts] -->

---

## Signing a Release File

The lab user `ops` on `client` creates a signing key without a passphrase (for the demo only), signs a tarball and verifies it before and after a change.

```bash
gpg --batch --passphrase '' --quick-gen-key 'Ops Release <ops@lab.internal>' ed25519 sign 1y
tar czf app-1.0.tar.gz -C /etc hostname
gpg --armor --detach-sign app-1.0.tar.gz
gpg --verify app-1.0.tar.gz.asc app-1.0.tar.gz
echo tampered >> app-1.0.tar.gz
gpg --verify app-1.0.tar.gz.asc app-1.0.tar.gz; echo "exit=$?"
```

Output:

```text
# ... (trimmed)
gpg: revocation certificate stored as '/home/ops/.gnupg/openpgp-revocs.d/DD6B437E1DC18BAE45F3F6A3B21A6E7B6D4C0EFA.rev'
# ... (trimmed)
gpg: Signature made Thu Sep 17 16:39:25 2026 UTC
gpg:                using EDDSA key DD6B437E1DC18BAE45F3F6A3B21A6E7B6D4C0EFA
gpg: Good signature from "Ops Release <ops@lab.internal>" [ultimate]
gpg: Signature made Thu Sep 17 16:39:25 2026 UTC
gpg:                using EDDSA key DD6B437E1DC18BAE45F3F6A3B21A6E7B6D4C0EFA
gpg: BAD signature from "Ops Release <ops@lab.internal>" [ultimate]
exit=1
```

!!! warning "Protect private keys with a passphrase"
    The empty passphrase above suits a throwaway lab key only. Real signing keys use a passphrase or a hardware token, and CI systems keep them in a secret store, not in the repository.

---

## Package Signatures

=== "RHEL / Rocky"

    ```bash
    rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n'
    rpm -K tree-*.rpm
    rpm -K tree-bad.rpm; echo "exit=$?"
    ```

    Output:

    ```text
    gpg-pubkey-6fedfc85-682ae1a9	Release Engineering (Rocky Linux 10) <releng@rockylinux.org> public key
    gpg-pubkey-e37ed158-65785fa9	Fedora (epel10) <epel@fedoraproject.org> public key
    tree-2.1.0-8.el10.x86_64.rpm: digests signatures OK
    tree-bad.rpm: DIGESTS SIGNATURES NOT OK
    exit=1
    ```

    The package came from `dnf download -q tree`, and `tree-bad.rpm` is a copy with one byte changed. Repositories set `gpgcheck=1` and `gpgkey=`, which `dnf` offers to import on first use.

=== "Ubuntu / Debian"

    ```bash
    grep -E '^Signed-By' /etc/apt/sources.list.d/ubuntu.sources | head -1
    gpg --show-keys /usr/share/keyrings/ubuntu-archive-keyring.gpg | head -3
    ```

    Output:

    ```text
    Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
    pub   rsa4096 2012-05-11 [SC]
          790BC7277767219C42C86F933B4FE6ACC0B21F32
    uid                      Ubuntu Archive Automatic Signing Key (2012) <ftpmaster@ubuntu.com>
    ```

!!! danger "gpgcheck=0 and [trusted=yes] turn off package verification"
    Both settings accept packages from anyone who can answer for the repository URL. Fix a key problem by importing the right key, not by disabling the check.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does a GPG signature on a package or file prove?"
    **Say first:** that the content is unchanged since the holder of the private key signed it; whether the key belongs to the publisher is checked separately, by fingerprint.

    **Proof:** after one appended line, `gpg --verify` printed `BAD signature` and exited 1.

    **Follow-up:** What else must you check before trusting the key?
<!-- --8<-- [end:l1] -->

??? question "L2: Verify a downloaded RPM before installing it."
    **Say first:** check its digests and signature against the imported keys.

    **Proof:** `rpm -K tree-2.1.0-8.el10.x86_64.rpm` printed `digests signatures OK`; a changed copy printed `DIGESTS SIGNATURES NOT OK`.

    **Follow-up:** Where does `dnf` take the key from?

??? question "L2: Add a third-party APT repository the current way."
    **Say first:** store its key in `/etc/apt/keyrings/` and reference it with `Signed-By` in the repository entry.

    **Proof:** `curl -fsSL URL | sudo gpg --dearmor -o /etc/apt/keyrings/vendor.gpg`; `Signed-By: /etc/apt/keyrings/vendor.gpg`.

    **Follow-up:** Why was the global `apt-key` keyring a problem?

??? question "L2: Sign a release artifact and let others verify it."
    **Say first:** create a detached armored signature and publish the public key.

    **Proof:** `gpg --armor --detach-sign app-1.0.tar.gz`; `gpg --armor --export ops@lab.internal > ops-release.asc`.

    **Follow-up:** How do users check the key's fingerprint?

??? question "L2: Encrypt a backup so only the operations team can read it."
    **Say first:** encrypt to the team's public key; only the private key decrypts.

    **Proof:** `gpg -e -r ops@lab.internal backup.tar`; `gpg -d backup.tar.gpg > backup.tar`.

    **Follow-up:** What happens to old backups when the key is lost?

??? question "L3: apt update fails with NO_PUBKEY for a vendor repository. What do you do?"
    **Say first:** get the vendor's current key from its documented source, compare the fingerprint, and install it as that repository's `Signed-By` keyring.

    **Proof:** the key ID in the error; `gpg --show-keys` on the downloaded file; `/etc/apt/keyrings/`.

    **Follow-up:** Why is `[trusted=yes]` the wrong fix?

---

## Related

- [Repositories](../06-package-management/repositories.md) and [Packaging Concepts](../06-package-management/packaging-concepts.md): adding repositories and their keys

Captured on Ubuntu 24.04.4 (GnuPG 2.4.4) and Rocky Linux 10.2 (GnuPG 2.4.5, RPM 4.19.1.1) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
