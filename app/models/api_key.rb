class ApiKey < ApplicationRecord
  belongs_to :project

  KEY_PREFIX = "wh_live_"

  validates :name, presence: true
  validates :key_digest, presence: true, uniqueness: true
  validates :key_prefix, presence: true

  scope :active, -> { where(revoked_at: nil) }

  def self.generate_for(project)
    raw_key = "#{KEY_PREFIX}#{SecureRandom.hex(24)}"
    digest = Digest::SHA256.hexdigest(raw_key)
    prefix = raw_key.first(16)

    api_key = new(
      project: project,
      name: "Default",
      key_digest: digest,
      key_prefix: prefix
    )
    [ api_key, raw_key ]
  end

  def self.authenticate(raw_key)
    digest = Digest::SHA256.hexdigest(raw_key)
    find_by(key_digest: digest, revoked_at: nil)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def masked_key
    "#{key_prefix}••••••••••••"
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end
end
