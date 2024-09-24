class EventType < ApplicationRecord
  belongs_to :project
  has_many :endpoint_event_types, dependent: :destroy
  has_many :webhook_endpoints, through: :endpoint_event_types

  validates :name, presence: true, uniqueness: { scope: :project_id },
                   format: { with: /\A[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+\z/, message: "must be dot-separated lowercase (e.g. order.created)" }

  SEED_TYPES = %w[
    order.created
    order.updated
    order.cancelled
    payment.completed
    payment.failed
    customer.created
  ].freeze
end
