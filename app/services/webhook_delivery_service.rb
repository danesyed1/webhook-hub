class WebhookDeliveryService
  TIMEOUT_SECONDS = 30
  RETRY_STATUS_CODES = [ 408, 429, 500, 502, 503, 504 ].freeze

  def initialize(delivery)
    @delivery = delivery
    @endpoint = delivery.webhook_endpoint
    @event = delivery.event
  end

  def call
    @delivery.update!(status: "processing")

    attempt_number = @delivery.attempt_count + 1
    attempt = DeliveryAttempt.create!(
      delivery: @delivery,
      attempt_number:,
      started_at: Time.current
    )

    payload = build_payload
    body = payload.to_json
    timestamp = Time.current.to_i
    signature_header = build_signature_header(body, timestamp)

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    log_attempt(attempt_number, "start")

    begin
      response = Faraday.new(request: { timeout: TIMEOUT_SECONDS }) do |f|
        f.adapter :net_http
      end.post(@endpoint.url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["User-Agent"] = "WebhookHub/1.0"
        req.headers["X-Webhook-Id"] = @event.id
        req.headers["X-Webhook-Timestamp"] = timestamp.to_s
        req.headers["X-Webhook-Signature"] = signature_header
        req.body = body
      end

      duration_ms = elapsed_ms(started)
      success = response.status.between?(200, 299)
      retryable = RETRY_STATUS_CODES.include?(response.status)

      attempt.update!(
        completed_at: Time.current,
        http_status: response.status,
        response_body: response.body.to_s.first(DeliveryAttempt::RESPONSE_BODY_LIMIT),
        response_headers: response.headers.to_h,
        duration_ms:,
        success:
      )

      @delivery.update!(attempt_count: attempt_number)

      if success
        @delivery.update!(status: "delivered")
        log_attempt(attempt_number, "delivered", http_status: response.status, duration_ms: duration_ms)
      elsif retryable && !@delivery.exhausted?
        schedule_retry
        log_attempt(attempt_number, "retrying", http_status: response.status, duration_ms: duration_ms)
      else
        @delivery.update!(status: "failed")
        log_attempt(attempt_number, "failed", http_status: response.status, duration_ms: duration_ms)
      end

    rescue Faraday::Error, Net::OpenTimeout, Net::ReadTimeout => e
      duration_ms = elapsed_ms(started)

      attempt.update!(
        completed_at: Time.current,
        error_message: e.message,
        duration_ms:,
        success: false
      )

      @delivery.update!(attempt_count: attempt_number)

      if @delivery.exhausted?
        @delivery.update!(status: "failed")
        log_attempt(attempt_number, "failed_exhausted", error: e.message, duration_ms: duration_ms)
      else
        schedule_retry
        log_attempt(attempt_number, "retrying", error: e.message, duration_ms: duration_ms)
      end
    end
  end

  private

  def build_payload
    {
      id: @event.id,
      type: @event.event_type,
      created_at: @event.created_at.iso8601,
      data: @event.payload
    }
  end

  # During a secret rotation grace period, include both the new (v1) and old (v0) signatures
  # so receivers can verify with either until they've updated their stored secret.
  def build_signature_header(body, timestamp)
    signed_payload = "#{timestamp}.#{body}"
    secrets = @endpoint.active_secrets
    parts = secrets.each_with_index.map do |secret, i|
      version = i == 0 ? "v1" : "v0"
      sig = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
      "#{version}=#{sig}"
    end
    parts.join(",")
  end

  def elapsed_ms(started)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
  end

  def schedule_retry
    delay = @delivery.next_retry_delay
    next_at = Time.current + delay.seconds
    @delivery.update!(status: "pending", next_attempt_at: next_at)
    DeliverWebhookJob.set(wait: delay.seconds).perform_later(@delivery.id)
  end

  def log_attempt(attempt_number, outcome, **extra)
    Rails.logger.info({
      event: "webhook_delivery",
      outcome: outcome,
      delivery_id: @delivery.id,
      event_id: @event.id,
      endpoint_id: @endpoint.id,
      endpoint_url: @endpoint.url,
      attempt_number: attempt_number,
      **extra
    }.to_json)
  end
end
