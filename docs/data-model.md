# Data Model

All IDs are UUIDs. This is the complete database schema for WebhookHub.

---

## Entity Overview

```
User ──────── Membership ──────── Organization
                                       │
                                    Project
                                   /   |   \
                              ApiKey  EventType  WebhookEndpoint
                                                      │
                              Event ─────────── Delivery
                               │                     │
                          (project_id)        DeliveryAttempt
```

---

## Tables

### users

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| email | string | Unique, lowercased |
| password_digest | string | bcrypt hash |
| name | string | Display name |
| created_at / updated_at | datetime | |

---

### organizations

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| name | string | Display name |
| slug | string | Unique, URL-safe identifier (e.g. `acme-corp`) |
| created_at / updated_at | datetime | |

---

### memberships

Connects users to organizations with a role.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| user_id | uuid | FK → users |
| organization_id | uuid | FK → organizations |
| role | string | `owner` or `member` |
| created_at / updated_at | datetime | |

Unique constraint on `(user_id, organization_id)`.

**Roles:**
- `owner` — can manage organization, members, projects, and API keys
- `member` — can view projects, manage endpoints, view and retry deliveries

---

### projects

A logical environment within an organization.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| organization_id | uuid | FK → organizations |
| name | string | Unique per org |
| description | string | Optional |
| created_at / updated_at | datetime | |

---

### api_keys

Credentials used to authenticate the event ingestion API.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| project_id | uuid | FK → projects |
| name | string | Human-readable label |
| key_digest | string | SHA-256 of the raw key (for auth) |
| key_prefix | string | First 16 chars, for display only |
| last_used_at | datetime | Updated on each API call |
| revoked_at | datetime | Null = active |
| created_at / updated_at | datetime | |

The raw API key is never stored — only its SHA-256 digest.

---

### event_types

Defines the event types available in a project.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| project_id | uuid | FK → projects |
| name | string | e.g. `order.created` |
| description | string | Optional |
| created_at / updated_at | datetime | |

Unique constraint on `(project_id, name)`.

---

### webhook_endpoints

A destination that receives webhook deliveries.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| project_id | uuid | FK → projects |
| name | string | Display name |
| url | string | Must be HTTP/HTTPS, not private IP |
| description | string | Optional |
| enabled | boolean | Default true |
| signing_secret | string | Raw HMAC secret (used to sign payloads) |
| signing_secret_prefix | string | First 12 chars, for display only |
| created_at / updated_at | datetime | |

---

### endpoint_event_types

Which event types each endpoint subscribes to (many-to-many join table).

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| webhook_endpoint_id | uuid | FK → webhook_endpoints |
| event_type_id | uuid | FK → event_types |
| created_at / updated_at | datetime | |

Unique constraint on `(webhook_endpoint_id, event_type_id)`.

---

### events

An event submitted via the API.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| project_id | uuid | FK → projects |
| event_type | string | e.g. `order.created` |
| payload | jsonb | The `data` field from the API request |
| status | string | `queued`, `processing`, `delivered`, `failed` |
| created_at / updated_at | datetime | |

---

### deliveries

One delivery per (event, endpoint) pair. Tracks the overall delivery status across all retry attempts.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| event_id | uuid | FK → events |
| webhook_endpoint_id | uuid | FK → webhook_endpoints |
| status | string | `pending`, `processing`, `delivered`, `failed` |
| attempt_count | integer | How many attempts have been made |
| next_attempt_at | datetime | When the next retry is scheduled |
| created_at / updated_at | datetime | |

Unique constraint on `(event_id, webhook_endpoint_id)` — this is the idempotency guarantee.

---

### delivery_attempts

One record per HTTP attempt. Captures everything about what was sent and received.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | Primary key |
| delivery_id | uuid | FK → deliveries |
| attempt_number | integer | 1, 2, 3... |
| started_at | datetime | When the HTTP request started |
| completed_at | datetime | When we got a response (or gave up) |
| http_status | integer | Response status code (null if connection failed) |
| response_body | text | First 10KB of response body |
| response_headers | jsonb | Response headers |
| error_message | string | Connection error message (null if HTTP succeeded) |
| duration_ms | integer | Total time in milliseconds |
| success | boolean | True if http_status is 2xx |
| created_at / updated_at | datetime | |

---

## Key Indexes

These are the most important indexes for query performance:

```sql
-- Tenant-scoped event lookups
CREATE INDEX ON events (project_id, created_at);

-- Delivery status monitoring
CREATE INDEX ON deliveries (status);
CREATE INDEX ON deliveries (next_attempt_at);  -- for retry scheduling
CREATE INDEX ON deliveries (webhook_endpoint_id, created_at);

-- Idempotency enforcement
CREATE UNIQUE INDEX ON deliveries (event_id, webhook_endpoint_id);

-- API key authentication
CREATE UNIQUE INDEX ON api_keys (key_digest);
```
