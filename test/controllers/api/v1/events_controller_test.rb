require "test_helper"

class Api::V1::EventsControllerTest < ActionDispatch::IntegrationTest
  RAW_KEY = "wh_live_testkey000000000000000000000000000000000000"
  PROJECT_ID = "01900000-0000-7000-8000-000000000030"

  def auth_headers
    { "Authorization" => "Bearer #{RAW_KEY}", "Content-Type" => "application/json" }
  end

  test "creates event and returns 201 with valid key" do
    assert_difference("Event.count", 1) do
      post "/api/v1/projects/#{PROJECT_ID}/events",
        params: { type: "order.created", data: { order_id: "ord_x" } }.to_json,
        headers: auth_headers
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "order.created", body["type"]
    assert_equal "queued", body["status"]
    assert body["id"].present?
  end

  test "enqueues delivery jobs for subscribed endpoints" do
    assert_enqueued_with(job: DeliverWebhookJob) do
      post "/api/v1/projects/#{PROJECT_ID}/events",
        params: { type: "order.created", data: {} }.to_json,
        headers: auth_headers
    end
  end

  test "returns 0 deliveries for event type with no subscribed endpoints" do
    post "/api/v1/projects/#{PROJECT_ID}/events",
      params: { type: "order.updated", data: {} }.to_json,
      headers: auth_headers
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 0, body["delivery_count"]
  end

  test "returns 401 with no auth header" do
    post "/api/v1/projects/#{PROJECT_ID}/events",
      params: { type: "order.created", data: {} }.to_json,
      headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal "unauthorized", body["error"]["code"]
  end

  test "returns 401 with invalid API key" do
    post "/api/v1/projects/#{PROJECT_ID}/events",
      params: { type: "order.created", data: {} }.to_json,
      headers: { "Authorization" => "Bearer wh_live_bogus", "Content-Type" => "application/json" }
    assert_response :unauthorized
  end

  test "returns 401 with revoked API key" do
    api_keys(:default_key).revoke!
    post "/api/v1/projects/#{PROJECT_ID}/events",
      params: { type: "order.created", data: {} }.to_json,
      headers: auth_headers
    assert_response :unauthorized
  ensure
    api_keys(:default_key).update!(revoked_at: nil)
  end

  test "returns 422 when event type is missing" do
    post "/api/v1/projects/#{PROJECT_ID}/events",
      params: { data: { order_id: "ord_x" } }.to_json,
      headers: auth_headers
    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "invalid_request", body["error"]["code"]
  end

  test "returns 404 for unknown project" do
    post "/api/v1/projects/00000000-0000-0000-0000-000000000000/events",
      params: { type: "order.created", data: {} }.to_json,
      headers: auth_headers
    assert_response :not_found
  end

  test "touches last_used_at on API key after successful request" do
    key = api_keys(:default_key)
    assert_nil key.last_used_at
    post "/api/v1/projects/#{PROJECT_ID}/events",
      params: { type: "order.created", data: {} }.to_json,
      headers: auth_headers
    assert_not_nil key.reload.last_used_at
  end
end
