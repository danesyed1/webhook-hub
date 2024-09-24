class EndpointEventType < ApplicationRecord
  belongs_to :webhook_endpoint
  belongs_to :event_type

  validates :webhook_endpoint_id, uniqueness: { scope: :event_type_id }
end
