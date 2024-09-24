class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  ROLES = %w[owner member].freeze

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :organization_id }
end
