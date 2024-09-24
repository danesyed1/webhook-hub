# Security

This document covers the security features built into WebhookHub.

---

## Webhook Signing (HMAC-SHA256)

Every webhook delivery is signed so your customers can verify it actually came from you.

### How it works

1. WebhookHub generates a signing secret per endpoint (e.g. `whsec_abc123...`)
2. When delivering, it signs: `timestamp + "." + raw_json_body`
3. The signature is computed with HMAC-SHA256 using the endpoint's secret
4. The signature is sent in the `X-Webhook-Signature` header as `v1=<hex>`

### Verifying on the receiving end

Here's how your customers verify a webhook:

```ruby
def verify_signature(payload_body, timestamp, signature_header, secret)
  # Reject if timestamp is too old (prevents replay attacks)
  if (Time.now.to_i - timestamp.to_i).abs > 300
    raise "Timestamp too old"
  end

  signed_payload = "#{timestamp}.#{payload_body}"
  expected = "v1=" + OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)

  # Use a constant-time comparison to prevent timing attacks
  ActiveSupport::SecurityUtils.secure_compare(expected, signature_header)
end
```

```python
import hmac, hashlib, time

def verify_signature(payload_body, timestamp, signature_header, secret):
    if abs(time.time() - int(timestamp)) > 300:
        raise Exception("Timestamp too old")

    signed_payload = f"{timestamp}.{payload_body}"
    expected = "v1=" + hmac.new(
        secret.encode(), signed_payload.encode(), hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(expected, signature_header)
```

### Rotating secrets

You can rotate an endpoint's signing secret from the dashboard. **Important:** after rotation, update your receiving code with the new secret. There is a brief window where in-flight webhooks signed with the old secret may arrive — you can handle this by checking both secrets during the transition.

The full secret is only shown once at creation time and once when rotated. The UI only ever shows a masked preview (e.g. `whsec_abc...`).

---

## API Key Security

API keys use the format `wh_live_<48 hex chars>`.

**Storage:** Only a SHA-256 hash of the key is stored in the database. The raw key is never stored. Authentication involves hashing the provided key and comparing digests — the original key can never be recovered from the database.

**Display:** The dashboard shows a masked version (`wh_live_xxxxxxxx••••••••••••`) so you can identify which key is which without exposing the secret.

**Single display:** The full key is shown only once — when created. After that, only the prefix is visible. If you lose the key, revoke it and create a new one.

**Logs:** Raw API keys are never written to application logs.

---

## SSRF Protection

SSRF (Server-Side Request Forgery) is when an attacker tricks the server into making HTTP requests to internal infrastructure.

WebhookHub prevents this by blocking endpoint URLs that target:
- `localhost` / `127.0.0.1` / `0.0.0.0`
- Private IP ranges: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`
- Link-local addresses: `169.254.0.0/16` (AWS metadata endpoint)
- IPv6 loopback: `[::1]`

This validation runs when an endpoint is created or updated. URLs with hostnames (not raw IPs) that resolve to private addresses are not blocked at validation time — a full DNS pre-resolution check would be expensive and subject to TOCTOU issues. For production, consider running Sidekiq workers in a network-isolated environment as an additional layer.

---

## Rate Limiting

The event ingestion API is rate-limited per API key:

- **Default:** 100 requests per minute per key
- **Configurable** via the `API_RATE_LIMIT` environment variable

Rate limiting is implemented with Rack::Attack backed by Redis. Exceeding the limit returns HTTP 429 with `Retry-After` and `X-RateLimit-*` headers.

---

## Other Security Measures

- **CSRF protection** — Rails' built-in CSRF token required for all browser-originated requests
- **Strong parameters** — All controller params use `params.expect(...)` to whitelist allowed fields
- **Response size limits** — Endpoint responses are capped at 10KB to prevent storage abuse
- **Request timeouts** — Webhook deliveries time out after 30 seconds
- **Password hashing** — bcrypt via `has_secure_password`
- **Stack traces hidden** — API errors return structured JSON; no stack traces exposed to users
- **Session security** — Cookie-based sessions with Rails defaults (encrypted, signed)
