# TLS Certificate Errors

An HTTPS request fails with a certificate error. The interviewer checks whether the candidate names the specific error, separates "the handshake worked but verification failed" from a connection problem, and fixes the cause rather than passing `-k`.

---

## Symptom

> "`curl` fails on our internal HTTPS site with a certificate error, but the browser seems fine (or complains too). What is wrong?"

---

## Clarifying Questions

- **What is the exact error?** Unknown issuer, name mismatch, expired and self-signed are different faults.
- **From every client or one?** One client points to its trust store or its clock; all clients point to the server's certificate.
- **By name or by IP?** Certificates cover names, not addresses.
- **Recently working?** An expiry or a clock change is the usual "worked yesterday" cause.

---

## Diagnostic Path

The client is `client` (Ubuntu 24.04); the server is nginx on `web` serving `www.shop.internal:8443` with a certificate from a private lab CA.

### 1. Read the Exact Error and the Chain

```bash
curl -sS https://www.shop.internal:8443/; echo "exit=$?"
openssl s_client -connect www.shop.internal:8443 -servername www.shop.internal -showcerts </dev/null 2>/dev/null | grep -E '^ *[0-9] s:|^ +i:|^Verify return'
```

Output:

```text
curl: (60) SSL certificate problem: unable to get local issuer certificate
# ... (trimmed)
exit=60
 0 s:O = Shop Lab, CN = www.shop.internal
   i:O = Shop Lab, CN = Shop Lab Root CA
Verify return code: 21 (unable to verify the first certificate)
```

The TLS handshake completed and only verification failed: the issuer `Shop Lab Root CA` is not in this client's trust store. `s:` is each certificate's subject, `i:` its issuer. Adding the CA fixes it, as in [OpenSSL and Trust Store](../../15-security/openssl-and-trust-store.md#adding-a-ca-to-the-trust-store).

### 2. Name Mismatch

With the CA trusted, a request by IP still fails:

```bash
curl -sS https://172.16.1.3:8443/; echo "exit=$?"
```

Output:

```text
curl: (60) SSL: no alternative certificate subject name matches target host name '172.16.1.3'
# ... (trimmed)
exit=60
```

Clients match the requested name against the certificate's `subjectAltName`, which lists DNS names only. Use a listed name, or reissue the certificate with the address in the SAN.

### 3. Expiry, Usually a Clock

The same trusted, correctly named request fails after the clock jumps past the certificate's validity:

```bash
date -u
sudo date -s '2027-02-01 12:00:00' >/dev/null    # clock skew, for the demo
curl -sS https://www.shop.internal:8443/; echo "exit=$?"
```

Output:

```text
Thu Sep 17 17:07:06 UTC 2026
curl: (60) SSL certificate problem: certificate has expired
exit=60
```

The 90-day certificate is valid, but the client's clock reads February 2027. A real expiry gives the same message with a correct clock; check the dates with `openssl x509 -noout -dates`. Correcting the time restores the request:

```bash
sudo chronyc -a 'burst 4/4' >/dev/null; sudo chronyc -a makestep >/dev/null; sleep 2
date -u
curl -sS https://www.shop.internal:8443/; echo "exit=$?"
```

Output:

```text
Thu Sep 17 17:07:41 UTC 2026
www over TLS on web
exit=0
```

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Unknown CA | `unable to get local issuer certificate`, self-signed | Add the CA to the client trust store |
| Missing intermediate | Browser works, `curl` fails; `s_client` shows only the leaf | Serve the full chain on the server |
| Name mismatch | `no alternative certificate subject name matches` | Use a name in the SAN, or reissue with the name |
| Expired certificate | `certificate has expired`, clock correct | Renew and deploy the certificate |
| Clock skew | `certificate has expired` or `not yet valid`, clock wrong | Fix time sync (chrony) |
| Wrong SNI | Server returns the default cert | Send `-servername`/SNI matching the vhost |

---

## Fix

Depends on the branch: add the CA, serve the full chain, reissue with the right SAN, renew the certificate, or fix the clock. For the trust-store case:

```bash
sudo cp shop-lab-root-ca.crt /usr/local/share/ca-certificates/    # Ubuntu
sudo update-ca-certificates
curl -sS https://www.shop.internal:8443/    # confirm
```

---

## Prevention

- Monitor expiry (`openssl x509 -checkend`) and alert weeks ahead; automate renewal (ACME) where possible.
- Keep time sync running everywhere, since skew breaks TLS silently.
- Include every name clients use in the SAN, and serve the full chain rather than the leaf alone.
- Never make `-k` or disabled verification the fix; it removes the protection entirely.

---

## Related

- [OpenSSL and Trust Store](../../15-security/openssl-and-trust-store.md): inspecting certificates and trust stores
- [Time and Timezones](../../13-networking/time-and-timezones.md): why clock skew breaks TLS
- [SSL and TLS Certificates Guide](../../../networking/ssl-tls-certificates-guide.md): certificate concepts

Captured on Ubuntu 24.04.4 (OpenSSL 3.0.13) against Rocky Linux 10.2 on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
