class DeliverWebhookJob < ApplicationJob
  queue_as :webhooks

  # We manage retries ourselves via exponential backoff; disable Sidekiq's built-in retry.
  sidekiq_options retry: false

  def perform(delivery_id)
    # Atomic claim: single UPDATE transitions pending → processing.
    # PostgreSQL guarantees only one concurrent worker wins this race,
    # so duplicate jobs (sweeper + scheduled) never cause double-delivery.
    claimed = Delivery.where(id: delivery_id, status: "pending")
                      .update_all(status: "processing")
    return if claimed == 0

    delivery = Delivery.find(delivery_id)
    WebhookDeliveryService.new(delivery).call
  end
end
