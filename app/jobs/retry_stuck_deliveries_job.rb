class RetryStuckDeliveriesJob < ApplicationJob
  queue_as :default

  def perform
    stuck = Delivery.where(status: "pending").where("next_attempt_at <= ?", Time.current)
    stuck.find_each { |d| DeliverWebhookJob.perform_later(d.id) }
    Rails.logger.info({ event: "retry_sweeper", requeued: stuck.count }.to_json)
  ensure
    self.class.set(wait: 1.minute).perform_later
  end
end
