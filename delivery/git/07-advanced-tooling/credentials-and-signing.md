# Credentials and Signing

Credentials decide how Git authenticates to a remote (SSH keys or an HTTPS credential helper), and signing proves who authored a commit or tag. Interviewers ask about both because they are where security meets daily workflow: how a push is authorized, and how a commit's author can be trusted.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| SSH auth | Key pair; public key on the host, private key local | `ssh -T git@host` |
| HTTPS auth | A token via a credential helper, never a password | `git config credential.helper` |
| Credential helper | Caches or stores the token so it is not retyped | `git config credential.helper` |
| macOS helper | `osxkeychain`, built in | `git config credential.helper` |
| Windows helper | Git Credential Manager (`manager`) | `git config credential.helper` |
| Commit signing | `gpg.format` selects `openpgp`, `ssh` or `x509` | `git config gpg.format` |
| SSH signing | Reuse an SSH key to sign commits (Git 2.34+) | `git log --show-signature` |
| Sign a commit | `-S`, or `commit.gpgsign true` for all | `git log --pretty=%G?` |
| Verify | Needs `allowedSignersFile` for SSH signatures | `git log --show-signature` |
| Signature status | `%G?` is `G` (good), `B` (bad), `N` (none) | `git log --pretty=%G?` |
<!-- --8<-- [end:facts] -->

---

## SSH Versus HTTPS

A remote URL's scheme decides how Git authenticates. SSH (`git@host:owner/repo.git`) uses a key pair; HTTPS (`https://host/owner/repo.git`) uses a token supplied by a credential helper.

- **SSH:** generate a key, add the public half to the host, and pushes authenticate with the private key. No per-push prompt, and no token to store on disk.
- **HTTPS:** authenticate with a personal access token (never an account password), which a credential helper caches so it is entered once.

Both are valid; teams often prefer SSH for developer machines and HTTPS with a token for CI. The remote URL alone determines which path a given clone uses.

---

## The Credential Helper (HTTPS)

For HTTPS remotes, a credential helper stores or caches the token so Git does not prompt on every push. The right helper depends on the platform.

=== "macOS / Linux"

    ```bash
    git config --show-origin credential.helper
    ```

    Output:

    ```text
    file:/Library/Developer/CommandLineTools/usr/share/git-core/gitconfig	osxkeychain
    ```

    macOS ships `osxkeychain`, which keeps the token in the login keychain. On Linux, use `libsecret` (`git config --global credential.helper libsecret`) to store it in the desktop keyring, or `cache` to hold it in memory for a timeout.

=== "Windows"

    ```bash
    git config --global credential.helper manager
    ```

    Windows uses Git Credential Manager (`manager`), installed with Git for Windows, which stores the token in the Windows Credential Store and handles browser-based sign-in for hosted platforms.

!!! danger "An HTTPS remote takes a token, never your account password"
    Hosted platforms stopped accepting account passwords over HTTPS; a push prompts for a personal access token instead. Store it through the credential helper, scope it to the minimum, and treat it like a secret. Never paste a token into a URL or commit it to the repo.

---

## Signing Commits With an SSH Key

Signing attaches a cryptographic proof of authorship. Since Git 2.34 an existing SSH key can sign, so no separate GPG key is needed. Three config keys turn it on.

```bash
git config gpg.format ssh
git config user.signingkey ~/.ssh/id_ed25519.pub
git config commit.gpgsign true
```

With `commit.gpgsign true`, every commit is signed; without it, sign one commit with `git commit -S`. Creating a commit now attaches a signature, though verifying it needs one more step.

```bash
git commit -m "feat: signed commit"
git log --show-signature -1
```

Output:

```text
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
commit aca209a229e0b37228a92b6146ff493476c0c365
No signature
```

The commit is signed, but Git cannot verify an SSH signature without knowing which keys to trust.

---

## Verifying a Signature

Verification needs an allowed-signers file: a list mapping an identity to its public key. Point `gpg.ssh.allowedSignersFile` at it, then verification succeeds.

```bash
printf 'amina@example.com %s\n' "$(cat ~/.ssh/id_ed25519.pub)" > ~/.ssh/allowed_signers
git config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
git log --show-signature -1
```

Output:

```text
commit aca209a229e0b37228a92b6146ff493476c0c365
Good "git" signature for amina@example.com with ED25519 key SHA256:aVq9VWtGDKm71xTRpSGwf8LmvXNaf75Py/3rUkM6rsA
```

`Good ... signature` confirms the commit was signed by a trusted key. The one-character status is quicker to script.

```bash
git log -1 --pretty='%h signature=%G? signer=%GS'
```

Output:

```text
aca209a signature=G signer=amina@example.com
```

`%G?` returns `G` for a good signature, `B` for bad, `U` for unknown validity, and `N` for none.

!!! note "Signing proves authorship; the host displays 'Verified'"
    A local `Good signature` means the key matches your allowed-signers file. Hosted platforms show a Verified badge only when the signing key is registered to the account as a signing key, which is a separate upload from an authentication key. Register the key on the platform for the badge to appear.

---

## Common Errors

### `gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification`

**Cause:** SSH signature verification has no list of trusted keys to check against.

**Fix:** create an allowed-signers file (`email key`) and set `git config gpg.ssh.allowedSignersFile <path>`.

### `git@github.com: Permission denied (publickey)`

**Cause:** the SSH key is missing from the agent or not registered on the host, so key authentication fails.

**Fix:** add the key with `ssh-add`, confirm with `ssh -T git@github.com`, and register the public key on the host.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are the two ways Git authenticates to a remote, and how do they differ?"
    **Say first:** SSH with a key pair (public key on the host, private key local), or HTTPS with a personal access token supplied by a credential helper; the remote URL's scheme decides which is used.

    **Proof:** an SSH remote is `git@host:owner/repo.git`; an HTTPS remote prompts for a token that `credential.helper` then stores.

    **Follow-up:** Why does an HTTPS push ask for a token rather than a password?

??? question "L1: What does a credential helper do?"
    **Say first:** it caches or stores the HTTPS token so Git does not prompt on every operation, using the platform keychain (`osxkeychain`, `libsecret`, or Git Credential Manager on Windows).

    **Proof:** `git config credential.helper` names the active helper.

    **Follow-up:** Where does the token physically live for each helper?
<!-- --8<-- [end:l1] -->

??? question "L2: Turn on commit signing without setting up GPG."
    **Say first:** use SSH signing (Git 2.34+): set `gpg.format ssh`, point `user.signingkey` at your public key, and enable `commit.gpgsign`.

    **Proof:**

    ```bash
    git config gpg.format ssh
    git config user.signingkey ~/.ssh/id_ed25519.pub
    git config commit.gpgsign true
    ```

    **Follow-up:** What else is needed before `git log --show-signature` can verify it?

??? question "L2: A signed commit shows 'No signature' with an allowedSignersFile error. What is wrong?"
    **Say first:** the commit is signed, but SSH verification has no trusted-keys list; configure `gpg.ssh.allowedSignersFile`.

    **Proof:**

    ```bash
    git config gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
    git log --show-signature -1   # now Good signature
    ```

    **Follow-up:** What format does each line of that file take?

??? question "L2: How do you check in a script whether the tip commit is validly signed?"
    **Say first:** read `%G?`; `G` means a good signature.

    **Proof:**

    ```bash
    git log -1 --pretty=%G?   # G, B, U, or N
    ```

    **Follow-up:** What do `B` and `N` mean?

??? question "L3: A commit signs and verifies locally but the platform still shows Unverified. Why, and how do you fix it?"
    **Say first:** local verification uses your allowed-signers file, but the platform badge requires the signing key to be registered to your account as a signing key, which is a separate upload from an auth key.

    **Proof:** the same key added under the account's signing keys makes the badge appear; the commit content and signature are unchanged.

    **Follow-up:** Why are authentication keys and signing keys tracked separately by the host?

---

## Related

- [Install and Config](../00-foundations/install-and-config.md): config levels where these keys are set
- [Remotes](../03-remotes-and-collaboration/remotes.md): SSH versus HTTPS remote URLs
- [Tags and Releases](../03-remotes-and-collaboration/tags-and-releases.md): signing annotated tags with the same key
- [Hooks](hooks.md): enforcing signing or checks at commit time

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
