# Changelog

All notable changes to webhook-hub are documented here.

## [2024-10-02] feat: add Project and WebhookEndpoint models with associations
- Defined Project, WebhookEndpoint models with has_many/belongs_to; added foreign key constraints and presence validations

## [2024-10-14] feat: implement event ingestion REST API with API key auth
- POST /api/v1/projects/:id/events validates bearer token, enqueues fan-out, returns 202 Accepted

## [2024-10-26] feat: add DeliverWebhookJob Sidekiq job for async delivery
- DeliverWebhookJob performs HTTP POST to endpoint URL with signed payload, records DeliveryAttempt

## [2024-11-07] feat: implement HMAC-SHA256 signing for webhook payloads
- WebhookDeliveryService computes X-Webhook-Signature header using endpoint secret and SHA-256 HMAC

## [2024-11-19] feat: add exponential backoff retry policy (5 attempts, 30s base)
- Sidekiq retry schedule: 30s, 2m, 8m, 32m, 2h; max_retries set to 5 on DeliverWebhookJob

## [2024-12-01] feat: implement delivery attempt recording with request/response log
- DeliveryAttempt stores status_code, response_body (truncated to 10KB), duration_ms, attempted_at

## [2024-12-13] feat: add Hotwire dashboard for endpoint and delivery management
- Turbo-powered views for listing endpoints, viewing delivery history, and inspecting attempt payloads

## [2024-12-25] feat: add manual retry button on failed delivery attempts
- DeliveriesController#retry re-enqueues DeliverWebhookJob for a specific delivery; Turbo updates status

## [2025-01-06] feat: implement event fan-out to all subscribed endpoints
- FanOutWebhookJob creates one Delivery per matching WebhookEndpoint and enqueues individual delivery jobs

## [2025-01-19] fix: Sidekiq job not persisting delivery attempt on network timeout
- Rescue Net::OpenTimeout and Net::ReadTimeout before Sidekiq retry to ensure attempt record is written

## [2025-02-01] feat: add SSRF protection by blocking private IP ranges
- SsrfGuard resolves endpoint URL hostname and rejects RFC-1918, loopback, and link-local addresses

## [2025-02-13] feat: implement API key rotation without downtime
- ApiKey#rotate! generates new token with 24h overlap window; old key remains valid during transition
