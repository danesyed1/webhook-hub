# Changelog

All notable changes to webhook-hub are documented here.

## [2024-10-02] feat: add Project and WebhookEndpoint models with associations
- Defined Project, WebhookEndpoint models with has_many/belongs_to; added foreign key constraints and presence validations

## [2024-10-14] feat: implement event ingestion REST API with API key auth
- POST /api/v1/projects/:id/events validates bearer token, enqueues fan-out, returns 202 Accepted
