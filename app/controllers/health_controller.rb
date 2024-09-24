class HealthController < ActionController::API
  def show
    checks = {
      database: database_ok?,
      redis: redis_ok?
    }
    status = checks.values.all? ? :ok : :service_unavailable
    render json: { status: status == :ok ? "ok" : "degraded", checks: checks }, status: status
  end

  private

  def database_ok?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue StandardError
    false
  end

  def redis_ok?
    Sidekiq.redis { |r| r.ping == "PONG" }
  rescue StandardError
    false
  end
end
