class Event < ApplicationRecord
  belongs_to :project
  has_many :deliveries, dependent: :destroy

  STATUSES = %w[queued processing delivered failed].freeze

  validates :event_type, presence: true
  validates :payload, exclusion: { in: [ nil ], message: "must be a JSON object" }
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def delivered?
    deliveries.where(status: "delivered").exists?
  end

  def all_delivered?
    deliveries.all? { |d| d.status == "delivered" }
  end
end
