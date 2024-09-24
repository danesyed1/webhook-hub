class WebhookEndpoint < ApplicationRecord
  belongs_to :project
  has_many :endpoint_event_types, dependent: :destroy
  has_many :event_types, through: :endpoint_event_types
  has_many :deliveries, dependent: :destroy

  SECRET_PREFIX = "whsec_"

  validates :name, presence: true
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/.+/, message: "must be a valid HTTP/HTTPS URL" }
  validate :url_not_ssrf_target

  scope :enabled, -> { where(enabled: true) }

  before_create :assign_signing_secret

  def self.generate_secret
    raw = "#{SECRET_PREFIX}#{SecureRandom.hex(32)}"
    prefix = "#{raw[0, 12]}..."
    [ raw, prefix ]
  end

  def masked_secret
    "#{signing_secret_prefix}••••••••••"
  end

  ROTATION_GRACE_PERIOD = 5.minutes

  def rotate_secret!
    raw, prefix = self.class.generate_secret
    update!(
      previous_signing_secret: signing_secret,
      previous_secret_expires_at: ROTATION_GRACE_PERIOD.from_now,
      signing_secret: raw,
      signing_secret_prefix: prefix
    )
    raw
  end

  def in_rotation?
    previous_signing_secret.present? && previous_secret_expires_at&.future?
  end

  # Returns all currently-valid secrets (new first, old second during grace period)
  def active_secrets
    secrets = [ signing_secret ]
    secrets << previous_signing_secret if in_rotation?
    secrets
  end

  def subscribes_to?(event_type_name)
    event_types.exists?(name: event_type_name)
  end

  def delivery_stats
    total = deliveries.count
    successful = deliveries.where(status: "delivered").count
    failed = deliveries.where(status: "failed").count
    success_rate = total > 0 ? (successful.to_f / total * 100).round(1) : 0

    avg_latency = DeliveryAttempt
      .joins(:delivery)
      .where(deliveries: { webhook_endpoint_id: id })
      .where(success: true)
      .average(:duration_ms)
      &.round || 0

    { total:, successful:, failed:, success_rate:, avg_latency: }
  end

  private

  def assign_signing_secret
    raw, prefix = self.class.generate_secret
    self.signing_secret = raw
    self.signing_secret_prefix = prefix
  end

  BLOCKED_HOSTS = %w[localhost 127.0.0.1 0.0.0.0 169.254.169.254 [::1]].freeze
  BLOCKED_RANGES = [
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("169.254.0.0/16")
  ].freeze

  def url_not_ssrf_target
    return if url.blank?
    uri = URI.parse(url)
    host = uri.host.to_s.downcase

    if BLOCKED_HOSTS.include?(host)
      errors.add(:url, "cannot target internal/localhost addresses")
      return
    end

    begin
      resolved = IPAddr.new(host)
      if BLOCKED_RANGES.any? { |range| range.include?(resolved) }
        errors.add(:url, "cannot target private IP ranges")
      end
    rescue IPAddr::InvalidAddressError
      # It's a hostname — allow it
    end
  rescue URI::InvalidURIError
    errors.add(:url, "is not a valid URL")
  end
end
