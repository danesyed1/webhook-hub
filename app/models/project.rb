class Project < ApplicationRecord
  belongs_to :organization

  has_many :api_keys, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy
  has_many :event_types, dependent: :destroy
  has_many :events, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :organization_id }

  def active_api_keys
    api_keys.where(revoked_at: nil)
  end

  def events_today
    events.where(created_at: Time.current.beginning_of_day..Time.current.end_of_day)
  end

  def deliveries
    Delivery.joins(:event).where(events: { project_id: id })
  end

  def delivery_stats
    all = deliveries
    total = all.count
    successful = all.where(status: "delivered").count
    failed = all.where(status: "failed").count
    success_rate = total > 0 ? (successful.to_f / total * 100).round(1) : 0

    avg_latency = DeliveryAttempt
      .joins(:delivery)
      .where(deliveries: { id: all.select(:id) })
      .where(success: true)
      .average(:duration_ms)
      &.round || 0

    { total:, successful:, failed:, success_rate:, avg_latency: }
  end
end
