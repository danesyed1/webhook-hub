class Rack::Attack
  RATE_LIMIT = ENV.fetch("API_RATE_LIMIT", "100").to_i

  throttle("api/events", limit: RATE_LIMIT, period: 1.minute) do |request|
    if request.path.start_with?("/api/v1/") && request.post?
      request.env["HTTP_AUTHORIZATION"]&.delete_prefix("Bearer ")&.first(16)
    end
  end

  self.throttled_responder = lambda do |_request|
    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => "60",
      "X-RateLimit-Limit" => RATE_LIMIT.to_s,
      "X-RateLimit-Reset" => (Time.now + 60).to_i.to_s
    }
    body = { error: { code: "rate_limited", message: "Too many requests. Retry after 60 seconds." } }.to_json
    [ 429, headers, [ body ] ]
  end
end
