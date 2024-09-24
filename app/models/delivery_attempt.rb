class DeliveryAttempt < ApplicationRecord
  belongs_to :delivery

  RESPONSE_BODY_LIMIT = 10_000

  validates :attempt_number, presence: true
  validates :success, inclusion: { in: [ true, false ] }

  before_save :truncate_response_body

  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }

  def duration_seconds
    return nil unless duration_ms
    (duration_ms / 1000.0).round(3)
  end

  private

  def truncate_response_body
    if response_body && response_body.bytesize > RESPONSE_BODY_LIMIT
      self.response_body = response_body.byteslice(0, RESPONSE_BODY_LIMIT) + "\n[truncated]"
    end
  end
end
