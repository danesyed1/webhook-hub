class Delivery < ApplicationRecord
  belongs_to :event
  belongs_to :webhook_endpoint
  has_many :delivery_attempts, dependent: :destroy

  STATUSES = %w[pending processing delivered failed].freeze
  MAX_ATTEMPTS = 5

  RETRY_DELAYS = [ 0, 10, 30, 120, 600 ].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :event_id, uniqueness: { scope: :webhook_endpoint_id }

  scope :recent, -> { order(created_at: :desc) }
  scope :failed, -> { where(status: "failed") }
  scope :delivered, -> { where(status: "delivered") }
  scope :pending, -> { where(status: "pending") }

  def next_retry_delay
    RETRY_DELAYS[attempt_count] || RETRY_DELAYS.last
  end

  def exhausted?
    attempt_count >= MAX_ATTEMPTS
  end

  def last_attempt
    delivery_attempts.order(attempt_number: :desc).first
  end

  def project
    event.project
  end
end
