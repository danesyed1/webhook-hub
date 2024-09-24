class DeliveriesController < ApplicationController
  before_action :require_organization_access
  before_action :set_project
  before_action :set_delivery, only: [ :show, :retry ]

  def index
    @deliveries = @project.deliveries
      .includes(:event, :webhook_endpoint, :delivery_attempts)
      .recent
      .limit(50)
  end

  def show
    @attempts = @delivery.delivery_attempts.order(:attempt_number)
    @event = @delivery.event
    @endpoint = @delivery.webhook_endpoint
  end

  def retry
    if @delivery.status == "failed"
      new_delivery = Delivery.find_or_create_by!(
        event: @delivery.event,
        webhook_endpoint: @delivery.webhook_endpoint
      ) do |d|
        d.status = "pending"
        d.attempt_count = 0
        d.next_attempt_at = Time.current
      end

      new_delivery.update!(status: "pending", next_attempt_at: Time.current) if new_delivery.status == "failed"
      DeliverWebhookJob.perform_later(new_delivery.id)
      redirect_to organization_project_delivery_path(current_organization.slug, @project, new_delivery),
                  notice: "Delivery retry queued."
    else
      redirect_back fallback_location: organization_project_delivery_path(current_organization.slug, @project, @delivery),
                    alert: "Only failed deliveries can be retried."
    end
  end

  private

  def set_project
    @project = current_organization.projects.find(params[:project_id])
  end

  def set_delivery
    @delivery = @project.deliveries.find(params[:id])
  end
end
