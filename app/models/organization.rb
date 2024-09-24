class Organization < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :projects, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  before_validation :generate_slug, on: :create

  def owner
    users.joins(:memberships).where(memberships: { organization_id: id, role: "owner" }).first
  end

  private

  def generate_slug
    return if slug.present?
    base = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
    candidate = base
    counter = 1
    while Organization.where(slug: candidate).exists?
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end
end
