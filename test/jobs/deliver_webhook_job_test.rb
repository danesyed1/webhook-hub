require "test_helper"

class DeliverWebhookJobTest < ActiveSupport::TestCase
  setup do
    @delivery = deliveries(:pending_delivery)
    WebMock.stub_request(:post, "https://example.com/webhooks").to_return(status: 200, body: "OK")
  end

  test "processes a pending delivery" do
    DeliverWebhookJob.new.perform(@delivery.id)
    assert_equal "delivered", @delivery.reload.status
  end

  test "does nothing if delivery is already processing (concurrent worker won the race)" do
    @delivery.update!(status: "processing")
    assert_no_difference("DeliveryAttempt.count") do
      DeliverWebhookJob.new.perform(@delivery.id)
    end
  end

  test "does nothing if delivery is already delivered" do
    @delivery.update!(status: "delivered")
    assert_no_difference("DeliveryAttempt.count") do
      DeliverWebhookJob.new.perform(@delivery.id)
    end
  end

  test "does nothing if delivery is already failed" do
    @delivery.update!(status: "failed")
    assert_no_difference("DeliveryAttempt.count") do
      DeliverWebhookJob.new.perform(@delivery.id)
    end
  end

  test "does nothing for unknown delivery id" do
    assert_no_difference("DeliveryAttempt.count") do
      DeliverWebhookJob.new.perform("00000000-0000-0000-0000-000000000000")
    end
  end

  test "two concurrent workers only deliver once" do
    # Simulate the race: both workers claim before either starts the service.
    # Only the first UPDATE should succeed.
    claimed_first  = Delivery.where(id: @delivery.id, status: "pending").update_all(status: "processing")
    claimed_second = Delivery.where(id: @delivery.id, status: "pending").update_all(status: "processing")

    assert_equal 1, claimed_first,  "first worker should claim the delivery"
    assert_equal 0, claimed_second, "second worker should be locked out"
  end
end
