# API Reference

WebhookHub has one API endpoint for the MVP: event ingestion.

---

## Authentication

All API requests require a Bearer token in the `Authorization` header:

```
Authorization: Bearer wh_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

API keys are created per-project in the dashboard under **API Keys**. The full key is only shown once at creation time — store it securely.

Keys look like:
```
wh_live_<48 hex characters>
```

---

## POST /api/v1/projects/:project_id/events

Submit an event. WebhookHub will deliver it to all enabled endpoints subscribed to that event type.

### Request

```
POST /api/v1/projects/018e1b2c-3d4e-7f89-a0b1-c2d3e4f50678/events
Authorization: Bearer wh_live_xxxxxxxxxxxx
Content-Type: application/json
```

```json
{
  "type": "order.created",
  "data": {
    "order_id": "ord_123",
    "customer_id": "cus_456",
    "amount": 4999
  }
}
```

**Fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | The event type (e.g. `order.created`). Must match a defined event type in the project. |
| `data` | No | Any JSON object. This is the payload delivered to endpoints. |

### Response

**201 Created** — event accepted and queued for delivery:

```json
{
  "id": "018e1b2c-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "type": "order.created",
  "status": "queued",
  "delivery_count": 3
}
```

`delivery_count` is how many endpoints this event was queued for.

### Error Responses

**400 Bad Request** — missing or malformed parameters:
```json
{
  "error": {
    "code": "invalid_request",
    "message": "Event type is required"
  }
}
```

**401 Unauthorized** — missing or invalid API key:
```json
{
  "error": {
    "code": "unauthorized",
    "message": "Invalid or revoked API key"
  }
}
```

**429 Too Many Requests** — rate limit exceeded (100 requests/minute per key by default):
```json
{
  "error": {
    "code": "rate_limited",
    "message": "Too many requests. Retry after 60 seconds."
  }
}
```

Headers included on rate-limited responses:
```
Retry-After: 60
X-RateLimit-Limit: 100
X-RateLimit-Reset: 1727000000
```

---

## cURL Example

```bash
curl -X POST https://your-domain.com/api/v1/projects/PROJECT_ID/events \
  -H "Authorization: Bearer wh_live_xxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment.completed",
    "data": {
      "payment_id": "pay_789",
      "amount": 9999,
      "currency": "USD"
    }
  }'
```

---

## Idempotency

Each event gets a unique UUID. If your app sends the same event twice (network retry scenario), WebhookHub will create two separate events and deliver both. To avoid duplicate deliveries, deduplicate on the event ID on the receiving end or implement your own idempotency key before sending.

The delivery system is idempotent internally: the same Sidekiq job running twice won't create duplicate delivery attempts (protected by unique database constraints on `event_id + endpoint_id`).

---

## Event Types

Event types are defined per-project in the dashboard. Examples that are seeded by default:

```
order.created
order.updated
order.cancelled
payment.completed
payment.failed
customer.created
```

An endpoint only receives an event if it has subscribed to that event type. An event with no subscribed endpoints still gets created and logged — it just has zero deliveries.
