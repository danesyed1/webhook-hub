require "test_helper"

class WebhookDeliveryServiceTest < ActiveSupport::TestCase
  ENDPOINT_URL = "https://example.com/webhooks"

  setup do
    @endpoint = webhook_endpoints(:production_endpoint)
    @event    = events(:order_created_event)
    @delivery = deliveries(:pending_delivery)
    WebMock.reset!
  end

  # ── Happy path ─────────────────────────────────────────────────────────────

  test "successful 200 marks delivery as delivered" do
    stub_webhook(200)
    WebhookDeliveryService.new(@delivery).call
    assert_equal "delivered", @delivery.reload.status
  end

  test "successful delivery creates one attempt with success=true" do
    stub_webhook(200)
    WebhookDeliveryService.new(@delivery).call
    attempt = @delivery.delivery_attempts.last
    assert attempt.success
    assert_equal 200, attempt.http_status
    assert attempt.duration_ms.present?
  end

  # ── Retry behaviour ─────────────────────────────────────────────────────────

  test "retryable HTTP status (503) schedules retry" do
    stub_webhook(503)
    assert_enqueued_with(job: DeliverWebhookJob) do
      WebhookDeliveryService.new(@delivery).call
    end
    assert_equal "pending", @delivery.reload.status
    assert @delivery.next_attempt_at > Time.current
  end

  test "delivery exhausted on retryable error marks as failed" do
    @delivery.update!(attempt_count: Delivery::MAX_ATTEMPTS - 1)
    stub_webhook(503)
    WebhookDeliveryService.new(@delivery).call
    assert_equal "failed", @delivery.reload.status
  end

  test "network timeout schedules retry" do
    stub_request(:post, ENDPOINT_URL).to_timeout
    assert_enqueued_with(job: DeliverWebhookJob) do
      WebhookDeliveryService.new(@delivery).call
    end
    assert_equal "pending", @delivery.reload.status
    attempt = @delivery.delivery_attempts.last
    assert attempt.error_message.present?
  end

  test "network timeout on last attempt marks as failed" do
    @delivery.update!(attempt_count: Delivery::MAX_ATTEMPTS - 1)
    stub_request(:post, ENDPOINT_URL).to_timeout
    WebhookDeliveryService.new(@delivery).call
    assert_equal "failed", @delivery.reload.status
  end

  test "non-retryable 400 marks as failed immediately" do
    stub_webhook(400)
    assert_no_enqueued_jobs(only: DeliverWebhookJob) do
      WebhookDeliveryService.new(@delivery).call
    end
    assert_equal "failed", @delivery.reload.status
  end

  # ── Signing ─────────────────────────────────────────────────────────────────

  test "request sends v1 HMAC signature" do
    stub_webhook(200)
    WebhookDeliveryService.new(@delivery).call
    assert_requested(:post, ENDPOINT_URL) do |req|
      req.headers["X-Webhook-Signature"]&.start_with?("v1=")
    end
  end

  test "during rotation grace period includes both v1 and v0 signatures" do
    @endpoint.update!(
      previous_signing_secret: "whsec_old_secret",
      previous_secret_expires_at: 5.minutes.from_now
    )
    stub_webhook(200)
    WebhookDeliveryService.new(@delivery).call
    assert_requested(:post, ENDPOINT_URL) do |req|
      sig = req.headers["X-Webhook-Signature"]
      sig.include?("v1=") && sig.include?("v0=")
    end
  end

  test "after grace period expires only v1 signature is sent" do
    @endpoint.update!(
      previous_signing_secret: "whsec_old_secret",
      previous_secret_expires_at: 1.minute.ago
    )
    stub_webhook(200)
    WebhookDeliveryService.new(@delivery).call
    assert_requested(:post, ENDPOINT_URL) do |req|
      sig = req.headers["X-Webhook-Signature"]
      sig.include?("v1=") && !sig.include?("v0=")
    end
  end

  # ── Headers ─────────────────────────────────────────────────────────────────

  test "sends required webhook headers" do
    stub_webhook(200)
    WebhookDeliveryService.new(@delivery).call
    assert_requested(:post, ENDPOINT_URL) do |req|
      req.headers["Content-Type"] == "application/json" &&
        req.headers["User-Agent"] == "WebhookHub/1.0" &&
        req.headers["X-Webhook-Id"] == @event.id &&
        req.headers["X-Webhook-Timestamp"].present?
    end
  end

  private

  def stub_webhook(status, body: "OK")
    stub_request(:post, ENDPOINT_URL).to_return(status: status, body: body, headers: {})
  end
end
