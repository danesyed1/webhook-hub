# WebhookHub

**Reliable webhook delivery without building webhook infrastructure yourself.**

---

## The Problem

When you build a SaaS product, your customers need to know when things happen in real-time — an order was placed, a payment succeeded, a user signed up. The standard solution is webhooks: your system sends an HTTP POST to your customer's URL whenever an event occurs.

But building reliable webhook infrastructure is deceptively hard:

- **Delivery failures happen.** Networks are unreliable, customer servers go down. You need automatic retries with intelligent backoff.
- **Security matters.** Without HMAC signatures, customers can't verify that your webhooks are actually from you.
- **Debugging is painful.** When a webhook fails, you need to inspect exactly what was sent, what came back, and when each attempt happened.
- **Scale is a trap.** If you deliver webhooks synchronously inside your API request, one slow customer endpoint blocks all your users.

WebhookHub solves this. It's a developer infrastructure platform that handles reliable webhook delivery so your team doesn't have to.

---

## What It Does

1. Your app sends an event to WebhookHub's API
2. WebhookHub fans it out to all subscribed customer endpoints asynchronously
3. Failed deliveries are automatically retried with exponential backoff
4. Every delivery attempt is logged with full request/response details
5. Webhooks are signed so recipients can verify authenticity

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Ruby on Rails 8.1 |
| Database | PostgreSQL |
| Background jobs | Sidekiq + Redis |
| Frontend | Hotwire (Turbo + Stimulus) + Tailwind CSS |
| Auth | Custom session-based (bcrypt) |

---

## Setup

### Prerequisites

- Ruby 3.4+ (or 4.0+)
- PostgreSQL 14+
- Redis 7+

### Quick Start with Docker Compose

The fastest way to get PostgreSQL and Redis running:

```bash
docker compose up -d
```

### 1. Clone and install

```bash
git clone <repo-url>
cd webhook-hub
bundle install
```

### 2. Set environment variables

```bash
cp .env.example .env
# Edit .env with your database/Redis credentials
```

Default values work with Docker Compose out of the box.

### 3. Create and migrate the database

```bash
bin/rails db:create db:migrate db:seed
```

The seed creates a demo account:
- **Email:** demo@webhookhub.dev
- **Password:** password123

### 4. Start the development server

```bash
bin/dev
```

This starts:
- Rails web server on `http://localhost:3000`
- Sidekiq worker (processes webhook deliveries)
- Tailwind CSS watcher

### 5. Send your first event

```bash
curl -X POST http://localhost:3000/api/v1/projects/<project_id>/events \
  -H "Authorization: Bearer wh_live_xxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "order.created",
    "data": {
      "order_id": "ord_123",
      "amount": 4999
    }
  }'
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_HOST` | `localhost` | PostgreSQL host |
| `DATABASE_USERNAME` | `postgres` | PostgreSQL user |
| `DATABASE_PASSWORD` | `password` | PostgreSQL password |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis connection URL |
| `API_RATE_LIMIT` | `100` | Max API requests per minute per key |
| `RAILS_MAX_THREADS` | `5` | Database connection pool size |

---

## Project Structure

```
app/
├── controllers/
│   ├── api/v1/events_controller.rb     # Event ingestion REST API
│   ├── deliveries_controller.rb        # Delivery inspection + manual retry
│   ├── webhook_endpoints_controller.rb # Endpoint management
│   └── ...
├── jobs/
│   └── deliver_webhook_job.rb          # Sidekiq job for async delivery
├── models/
│   ├── event.rb                        # Ingested event
│   ├── delivery.rb                     # One delivery per endpoint per event
│   └── delivery_attempt.rb             # Individual HTTP attempt record
└── services/
    └── webhook_delivery_service.rb     # Core delivery + retry logic
```

---

## Documentation

See the `docs/` folder for detailed documentation:

- [Architecture Overview](docs/architecture.md) — How the pieces fit together
- [API Reference](docs/api.md) — Event ingestion API
- [Webhook Delivery Flow](docs/webhook-delivery.md) — How delivery and retries work
- [Security](docs/security.md) — HMAC signing, SSRF protection, key management
- [Data Model](docs/data-model.md) — Database schema and relationships

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
