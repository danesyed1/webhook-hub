class DashboardController < ApplicationController
  def index
    @organizations = current_user.organizations.includes(:projects)
    @recent_deliveries = Delivery
      .joins(event: :project)
      .joins(:webhook_endpoint)
      .where(events: { project_id: current_user.organizations.flat_map { |o| o.projects.ids } })
      .includes(:event, :webhook_endpoint, :delivery_attempts)
      .recent
      .limit(10)
  end
end
