# OpenSSL and Trust Store

`openssl` creates and inspects keys, certificate requests and certificates, and tests TLS servers. The system trust store decides which certificate authorities `curl`, package managers and most applications accept, and the two distributions manage it with different commands.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Chain | Server certificate, then intermediates, signed up to a root the client trusts; the server sends leaf and intermediates | `openssl s_client -showcerts` |
| Names | Clients match the host name against `subjectAltName`; the CN alone is ignored | `openssl x509 -noout -ext subjectAltName` |
| Inspect | `openssl x509 -in FILE -noout -subject -issuer -dates` | `openssl x509 -text` |
| Expiry check | `-checkend SECONDS` exits 1 if the certificate expires within that time | `openssl x509 -checkend 2592000` |
| Key match | Public key hash of certificate and private key must be equal | `openssl pkey -pubout` |
| Test a server | `openssl s_client -connect HOST:PORT -servername NAME`; `-servername` sends SNI | `curl -v https://HOST` |
| Formats | PEM (Base64, `-----BEGIN`), DER (binary), PKCS#12 (`.p12`/`.pfx`, key and chain in one file) | `openssl x509 -inform der` |
| RHEL trust | Drop CA files in `/etc/pki/ca-trust/source/anchors/`, run `update-ca-trust`; bundle `/etc/pki/tls/certs/ca-bundle.crt` | `trust list --filter=ca-anchors` |
| Ubuntu trust | Drop `*.crt` files in `/usr/local/share/ca-certificates/`, run `update-ca-certificates`; bundle `/etc/ssl/certs/ca-certificates.crt` | `ls -l /etc/ssl/certs` |
| Crypto policy | RHEL sets allowed protocols and key sizes system-wide | `update-crypto-policies --show` |
| Private keys | Mode `600`, owned by root or the service user; never in a repository | `ls -l *.key` |
<!-- --8<-- [end:facts] -->

---

## A Private CA and a Server Certificate

On `web` (Rocky Linux 10.2), a lab root CA signs a certificate for `www.shop.internal`. Production certificates come from a public or corporate CA; the commands to inspect them are the same.

```bash
cd /etc/pki/lab
sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -noenc -keyout ca.key -out ca.crt -days 3650 -subj "/O=Shop Lab/CN=Shop Lab Root CA" 2>&1 | tail -2
sudo openssl req -new -newkey rsa:2048 -noenc -keyout www.key -out www.csr -subj "/O=Shop Lab/CN=www.shop.internal" -addext "subjectAltName=DNS:www.shop.internal,DNS:shop.internal" 2>&1 | tail -2
sudo openssl req -in www.csr -noout -text | grep -A1 'Subject Alternative Name'
sudo openssl x509 -req -in www.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out www.crt -days 90 -copy_extensions copy
```

Output:

```text
-----
# ... (trimmed: key generation progress)
-----
                X509v3 Subject Alternative Name: 
                    DNS:www.shop.internal, DNS:shop.internal
Certificate request self-signature ok
subject=O=Shop Lab, CN=www.shop.internal
```

`-copy_extensions copy` carries the SAN from the request into the certificate; without it, `openssl x509 -req` drops request extensions. The certificate then looks like this:

```bash
sudo openssl x509 -in www.crt -noout -subject -issuer -dates -ext subjectAltName
sudo openssl verify -CAfile ca.crt www.crt
sudo openssl x509 -in www.crt -noout -pubkey | sha256sum
sudo openssl pkey -in www.key -pubout | sha256sum
sudo openssl pkey -in ca.key -pubout | sha256sum
sudo openssl x509 -in www.crt -noout -checkend 2592000; echo "exit=$?"
sudo openssl x509 -in www.crt -noout -checkend 7776000; echo "exit=$?"
```

Output:

```text
subject=O=Shop Lab, CN=www.shop.internal
issuer=O=Shop Lab, CN=Shop Lab Root CA
notBefore=Sep 17 16:41:56 2026 GMT
notAfter=Dec 16 16:41:56 2026 GMT
X509v3 Subject Alternative Name: 
    DNS:www.shop.internal, DNS:shop.internal
www.crt: OK
6c1ad2a007ed889818b8375b94743651092ecdfefc883fce125ee796f85d0c72  -
6c1ad2a007ed889818b8375b94743651092ecdfefc883fce125ee796f85d0c72  -
a8246508522bd7797621bf270b7b572d620addd9e40eb7e6ee0500b01d289a60  -
Certificate will not expire
exit=0
Certificate will expire
exit=1
```

The matching hashes pair `www.crt` with `www.key`; the CA key's hash differs. The 90-day certificate passes a 30-day check and fails a 90-day one, which is how monitoring alerts before expiry.

!!! danger "The CA key signs anything"
    Whoever holds `ca.key` can issue a certificate for any name that clients of this CA will trust. Keep CA keys offline or in a vault, and never copy them to the servers that use the certificates.

nginx on `web` serves the certificate on port 8443 (`ssl_certificate /etc/pki/lab/www.crt;`, `ssl_certificate_key /etc/pki/lab/www.key;`), and firewalld allows the port.

---

## Testing From a Client

`client` (Ubuntu 24.04) does not know the lab CA yet:

```bash
curl -sS https://www.shop.internal:8443/; echo "exit=$?"
openssl s_client -connect www.shop.internal:8443 -servername www.shop.internal -brief </dev/null 2>&1 | head -8
openssl s_client -connect www.shop.internal:8443 -servername www.shop.internal -showcerts </dev/null 2>/dev/null | grep -E '^ *[0-9] s:|^ +i:|^Verify return'
```

Output:

```text
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html
# ... (trimmed)
exit=60
depth=0 O = Shop Lab, CN = www.shop.internal
verify error:num=20:unable to get local issuer certificate
depth=0 O = Shop Lab, CN = www.shop.internal
verify error:num=21:unable to verify the first certificate
CONNECTION ESTABLISHED
Protocol version: TLSv1.3
Ciphersuite: TLS_AES_256_GCM_SHA384
Peer certificate: O = Shop Lab, CN = www.shop.internal
 0 s:O = Shop Lab, CN = www.shop.internal
   i:O = Shop Lab, CN = Shop Lab Root CA
Verify return code: 21 (unable to verify the first certificate)
```

The handshake worked, and only verification failed: the issuer is not in the client's trust store. `s:` is the subject and `i:` the issuer of each certificate the server sent.

!!! warning "curl -k hides the problem instead of fixing it"
    `-k` (`--insecure`) accepts any certificate, including an attacker's. Use it only to confirm that the rest of the request works, then fix the trust store or the certificate.

---

## Adding a CA to the Trust Store

=== "RHEL / Rocky"

    ```bash
    sudo cp /tmp/shop-lab-root-ca.crt /etc/pki/ca-trust/source/anchors/
    sudo update-ca-trust
    trust list --filter=ca-anchors | grep -B1 -A2 'Shop Lab'
    curl -sS https://www.shop.internal:8443/
    update-crypto-policies --show
    ```

    Output:

    ```text
        type: certificate
        label: Shop Lab Root CA
        trust: anchor
        category: authority
    www over TLS on web
    DEFAULT
    ```

    Captured on `gw`, which failed with the same `curl: (60)` error before the update.

=== "Ubuntu / Debian"

    ```bash
    sudo cp /tmp/shop-lab-root-ca.crt /usr/local/share/ca-certificates/shop-lab-root-ca.crt
    sudo update-ca-certificates
    ls -l /etc/ssl/certs/ | grep -i shop
    curl -sS https://www.shop.internal:8443/
    ```

    Output:

    ```text
    Updating certificates in /etc/ssl/certs...
    rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
    1 added, 0 removed; done.
    Running hooks in /etc/ca-certificates/update.d...
    done.
    lrwxrwxrwx 1 root root     20 Sep 17 16:42 2d9115bf.0 -> shop-lab-root-ca.pem
    lrwxrwxrwx 1 root root     53 Sep 17 16:42 shop-lab-root-ca.pem -> /usr/local/share/ca-certificates/shop-lab-root-ca.crt
    www over TLS on web
    ```

    `update-ca-certificates` reads only files ending in `.crt` in that directory.

Applications with their own trust store (Java keystores, Python `certifi`, Node.js) ignore both system stores unless configured to use them.

---

## A Name the Certificate Does Not Cover

With the CA trusted, a request by IP address still fails, because the certificate lists only DNS names:

```bash
curl -sS https://172.16.1.3:8443/; echo "exit=$?"
```

Output:

```text
curl: (60) SSL: no alternative certificate subject name matches target host name '172.16.1.3'
More details here: https://curl.se/docs/sslcerts.html
# ... (trimmed)
exit=60
```

The fix is a certificate whose SAN includes the name clients use (`IP:172.16.1.3` for an address), or clients that use the listed name.

---

## Common Errors

### `curl: (60) SSL certificate problem: unable to get local issuer certificate`

**Cause:** the issuing CA is not trusted by the client, or the server does not send the intermediate certificate.

**Fix:** check the chain with `openssl s_client -showcerts`; add the CA to the trust store, or configure the server with the full chain.

### `curl: (60) SSL: no alternative certificate subject name matches target host name '172.16.1.3'`

**Cause:** the requested host name is not in the certificate's `subjectAltName`.

**Fix:** use a listed name, or reissue the certificate with the missing name.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does a client check when it verifies a server certificate?"
    **Say first:** that the chain leads to a trusted root, that the requested name is in the SAN, and that every certificate is within its validity dates.

    **Proof:** `openssl s_client -connect host:443 -servername host` shows the chain and `Verify return code`.

    **Follow-up:** Which of these checks does a wrong system clock break?
<!-- --8<-- [end:l1] -->

??? question "L2: Check when a server's certificate expires, from the command line."
    **Say first:** fetch it with `s_client` and read the dates, or use `-checkend` for a pass or fail.

    **Proof:** `openssl s_client -connect www.shop.internal:8443 -servername www.shop.internal </dev/null 2>/dev/null | openssl x509 -noout -enddate`

    **Follow-up:** How would you alert 30 days ahead?

??? question "L2: Confirm that a private key belongs to a certificate."
    **Say first:** compare the hashes of their public keys.

    **Proof:** `openssl x509 -in www.crt -noout -pubkey | sha256sum` and `openssl pkey -in www.key -pubout | sha256sum` printed the same value.

    **Follow-up:** What does nginx print when they do not match?

??? question "L2: Make the whole server trust an internal CA."
    **Say first:** add the CA to the system trust store with the distribution's tool.

    **Proof:** RHEL: `/etc/pki/ca-trust/source/anchors/` and `update-ca-trust`; Ubuntu: `/usr/local/share/ca-certificates/NAME.crt` and `update-ca-certificates`.

    **Follow-up:** Why does a Java application still fail afterwards?

??? question "L3: A browser trusts the site but curl on a server reports unable to get local issuer certificate. What is different?"
    **Say first:** the server probably sends an incomplete chain; browsers often fill in intermediates, `curl` does not.

    **Proof:** `openssl s_client -showcerts` lists only the leaf; the fix is the full chain in the server's certificate file.

    **Follow-up:** How do you build the full-chain file?

??? question "L3: A service fails TLS only when called by IP address. Why?"
    **Say first:** the certificate lists DNS names only, and clients match the requested name against the SAN.

    **Proof:** `curl https://172.16.1.3:8443/` printed `no alternative certificate subject name matches`; `openssl x509 -noout -ext subjectAltName` shows the names.

    **Follow-up:** Why is disabling host name verification in the client the wrong fix?

---

## Related

- [SSL and TLS Certificates Guide](../../networking/ssl-tls-certificates-guide.md): certificate concepts and public CAs
- [TLS Certificate Errors](../interview/scenarios/tls-certificate-errors.md): expiry, clock skew, SNI and missing intermediates
- [Time and Timezones](../13-networking/time-and-timezones.md): why clock skew breaks TLS

Captured on Rocky Linux 10.2 (OpenSSL 3.5.8) and Ubuntu 24.04.4 (OpenSSL 3.0.13) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
