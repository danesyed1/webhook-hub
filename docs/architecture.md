# Architecture Overview

WebhookHub is a standard Rails monolith intentionally kept simple. No microservices, no message queues, no Kubernetes — just four well-understood pieces working together.

---

## The Four Pieces

```
Browser / Developer Dashboard
        |
   Rails App (Puma)
        |
   PostgreSQL              Redis
   (all app data)    (Sidekiq job queue)
        |                  |
        └──── Sidekiq Worker ────┘
              (delivers webhooks)
```

1. **Rails (Puma)** — Handles the web dashboard and the event ingestion REST API.
2. **PostgreSQL** — Stores everything: users, organizations, events, delivery history.
3. **Redis** — Acts as the job queue between Rails and Sidekiq.
4. **Sidekiq** — A separate process that picks up delivery jobs and makes the actual HTTP requests to customer endpoints.

---

## Why Sidekiq?

The most important design decision: **webhook delivery never happens inside an API request**.

When your app calls `POST /api/v1/projects/:id/events`, Rails does only this:
1. Authenticate the API key
2. Validate the request
3. Save the event to the database
4. Create delivery records (one per subscribed endpoint)
5. Push jobs onto the Sidekiq queue
6. Return a response immediately

The actual HTTP requests go out asynchronously in the background. This means:
- Your API response time is fast and predictable (database write, not network call)
- A slow or unreliable customer endpoint can't affect your API
- Failed deliveries can be retried without blocking anything

---

## Data Hierarchy

Every piece of data belongs to an organization. This is how isolation works:

```
Organization (e.g. "Acme Corp")
  └── Project (e.g. "Production")
        ├── ApiKeys        — credentials to send events
        ├── EventTypes     — what kinds of events exist
        ├── WebhookEndpoints — where to deliver events
        └── Events
              └── Deliveries (one per endpoint)
                    └── DeliveryAttempts (one per retry)
```

A tenant (organization) can have multiple projects. Projects are independent environments — for example, "Production" and "Staging" within the same company. They don't share API keys or endpoints.

---

## The Event Lifecycle

```
1. POST /api/v1/projects/:id/events
         ↓
2. Event saved (status: "queued")
         ↓
3. Find all enabled endpoints subscribed to this event type
         ↓
4. Create one Delivery record per endpoint (status: "pending")
         ↓
5. Enqueue one DeliverWebhookJob per delivery
         ↓
6. Return 201 to caller
         ↓
   (background, asynchronously)
         ↓
7. Sidekiq picks up job → DeliverWebhookJob
         ↓
8. WebhookDeliveryService makes HTTP POST to endpoint URL
         ↓
9. Record DeliveryAttempt (status, response, duration)
         ↓
10. Success → Delivery marked "delivered"
    Failure → Schedule retry with exponential backoff
    Exhausted → Delivery marked "failed" permanently
```

---

## Multi-Tenancy

All database queries are scoped through the organization. The pattern is:

```ruby
# In controllers:
@organization = current_user.organizations.find_by!(slug: params[:organization_slug])
@project = @organization.projects.find(params[:project_id])
@events = @project.events.recent
```

A user can never accidentally access another organization's data because every query starts from what the current user can see.

---

## No Kubernetes, No Microservices

The MVP deliberately avoids:
- Kubernetes / container orchestration
- Kafka or other message brokers
- Separate microservices
- External dead-letter queues

PostgreSQL is the dead-letter queue — permanently failed deliveries stay in the database with full history. Sidekiq with Redis is the message queue. A single Rails server handles everything. This is deployable to a $10/month VPS.
