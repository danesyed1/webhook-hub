# User Flows

This document walks through the main flows a developer experiences in WebhookHub.

---

## 1. Onboarding (First-Time Setup)

This is the path from signup to first event delivered.

```
Sign up
  → Enter name, email, password, organization name
  → Auto-redirected to "Create Project"

Create Project
  → Enter project name (e.g. "Production")
  → Event types are seeded automatically:
      order.created, order.updated, order.cancelled,
      payment.completed, payment.failed, customer.created

Add an Endpoint
  → Enter name, URL, select which event types to subscribe
  → Signing secret generated automatically

Copy API Key
  → Go to API Keys → Generate Key
  → Copy the full key (shown only once)

Send Test Event
  → From the endpoint page, use "Send Test Event"
  → Or use cURL with the API key
  → Watch the delivery appear in real-time on the project dashboard
```

---

## 2. Sending an Event (Developer API Flow)

This is what happens every time your application fires an event:

```
Your App → POST /api/v1/projects/:id/events
               │
               ▼ (synchronous, fast)
           Validate API key
           Validate request body
           Save event to DB
           Find subscribed endpoints
           Create delivery records
           Enqueue Sidekiq jobs
           Return 201 { id, type, status: "queued" }

               │ (asynchronous, background)
               ▼
           Sidekiq picks up DeliverWebhookJob
           WebhookDeliveryService runs:
             - Build JSON payload
             - Sign with HMAC-SHA256
             - POST to endpoint URL
             - Record DeliveryAttempt
             - Mark delivery as "delivered" or schedule retry
```

---

## 3. Inspecting a Failed Delivery

When a delivery fails, here's how to debug it:

```
Dashboard → Project Overview → Recent Failures
  → Click on a failed delivery
  → Delivery Detail Page shows:
      - Event type and ID
      - Which endpoint it was going to
      - Timeline (when each attempt happened)
      - HTTP status codes for each attempt
      - Full response body
      - Error messages (for connection failures)
      - Attempt count and retry schedule

If the issue is fixed on the endpoint side:
  → Click "Retry Delivery"
  → A new attempt is queued immediately
```

---

## 4. Managing Endpoints

From the Endpoints page within a project:

**Create endpoint:**
- Name (for display)
- URL (must be HTTPS, no private IPs)
- Description (optional)
- Select which event types to receive

**Manage endpoint:**
- Enable / Disable (disabled endpoints still appear in the list but receive no events)
- Edit URL or subscribed events
- Rotate signing secret (shown once, then masked)
- Send test event to verify connectivity
- View delivery statistics and history

**Delete endpoint:**
- Requires confirmation
- Deletes all delivery history for that endpoint

---

## 5. API Key Lifecycle

```
Create key
  → Provide a name (e.g. "Production Server")
  → Full key shown once in a highlighted banner
  → Must copy immediately

Use key
  → Authorization: Bearer wh_live_xxxx...
  → last_used_at is updated on each request

Revoke key
  → Immediate effect — any requests using this key get 401
  → Key stays in the list as "Revoked" for audit purposes
```

---

## 6. Multi-Environment Setup

A typical setup for one company:

```
Organization: Acme Corp
├── Project: Production
│   ├── API Key: production-server
│   ├── Endpoints:
│   │   ├── CRM System (subscribed to: customer.created, order.created)
│   │   └── Analytics (subscribed to: all events)
│   └── Event Types: [standard set]
│
└── Project: Staging
    ├── API Key: staging-server
    ├── Endpoints:
    │   └── Internal Test Server
    └── Event Types: [standard set]
```

Each project is completely isolated — different API keys, different endpoints, separate event history.
