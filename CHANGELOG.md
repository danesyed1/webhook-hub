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
