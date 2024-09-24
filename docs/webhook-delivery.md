# Webhook Delivery Flow

This document explains how WebhookHub delivers webhooks: the format, the retry logic, and what gets recorded.

---

## What Gets Sent

When WebhookHub delivers a webhook, it sends an HTTP POST to the endpoint URL with this body:

```json
{
  "id": "018e1b2c-3d4e-7f89-a0b1-c2d3e4f50678",
  "type": "order.created",
  "created_at": "2026-09-22T12:30:00Z",
  "data": {
    "order_id": "ord_123",
    "amount": 4999
  }
}
```

And these headers:

```
Content-Type: application/json
User-Agent: WebhookHub/1.0
X-Webhook-Id: 018e1b2c-3d4e-7f89-a0b1-c2d3e4f50678
X-Webhook-Timestamp: 1727000000
X-Webhook-Signature: v1=abc123def456...
```

---

## What Counts as Success

Any HTTP response with status code **200–299** is a success. WebhookHub marks the delivery as delivered and stops.

Everything else is a failure:
- Connection refused / timeout
- HTTP 4xx (except for codes that won't change on retry — see below)
- HTTP 5xx

---

## Retry Logic

Failed deliveries are automatically retried using exponential backoff:

| Attempt | Wait before retry |
|---------|------------------|
| 1       | Immediately |
| 2       | 10 seconds |
| 3       | 30 seconds |
| 4       | 2 minutes |
| 5       | 10 minutes |

After 5 failed attempts, the delivery is marked **Permanently Failed**. No more retries happen automatically.

**Which status codes trigger a retry?**

Retried: connection errors, timeouts, 408, 429, 5xx

Not retried: 400, 401, 403, 404, and other 4xx codes (these indicate a problem with the request itself — retrying won't help).

---

## Manual Retry

For permanently failed deliveries, you can trigger a manual retry from the delivery detail page in the dashboard. This creates a fresh attempt without duplicating the original event.

---

## Delivery Attempts

Every HTTP attempt is recorded as a `DeliveryAttempt`. You can inspect these in the dashboard under the delivery detail page.

Each attempt stores:
- Attempt number (1, 2, 3...)
- When it started and completed
- HTTP status code
- Response body (first 10KB)
- Response headers
- Error message (for connection failures)
- Duration in milliseconds
- Success or failure

Response bodies are capped at 10,000 bytes to prevent malicious endpoints from consuming excessive storage.

---

## Request Timeout

WebhookHub waits up to **30 seconds** for the endpoint to respond. If the endpoint takes longer, the attempt is marked as timed out and scheduled for retry.

---

## Delivery States

A delivery progresses through these states:

```
pending → processing → delivered
                     ↘ pending (scheduled retry)
                              → ... (up to 5 attempts)
                                        ↘ failed (permanently)
```

- **pending** — waiting to be picked up by Sidekiq
- **processing** — the HTTP request is currently in flight
- **delivered** — at least one attempt returned 2xx
- **failed** — all retries exhausted, no successful delivery

---

## Idempotency

Each delivery has a unique constraint on `(event_id, endpoint_id)`. This means:
- One event can only have one delivery record per endpoint
- The Sidekiq job checks if the delivery is already "delivered" before attempting
- If the same job runs twice (e.g. Sidekiq crash + restart), it won't deliver twice

---

## Fan-Out

When an event comes in, WebhookHub creates one delivery per subscribed endpoint. If you have 5 endpoints subscribed to `order.created`, one event creates 5 deliveries, and 5 independent Sidekiq jobs are queued. Each delivery is tracked independently — one failing endpoint doesn't affect the others.
