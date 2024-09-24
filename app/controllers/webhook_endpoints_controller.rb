class WebhookEndpointsController < ApplicationController
  before_action :require_organization_access
  before_action :set_project
  before_action :set_endpoint, only: [ :show, :edit, :update, :destroy, :toggle, :rotate_secret, :test ]

  def index
    @endpoints = @project.webhook_endpoints.includes(:event_types)
  end

  def show
    @stats = @endpoint.delivery_stats
    @recent_deliveries = @endpoint.deliveries
      .includes(:event, :delivery_attempts)
      .recent
      .limit(20)
    @event_types = @project.event_types
  end

  def new
    @endpoint = @project.webhook_endpoints.new
    @event_types = @project.event_types
  end

  def create
    @endpoint = @project.webhook_endpoints.new(endpoint_params)
    if @endpoint.save
      sync_event_types(@endpoint)
      redirect_to organization_project_endpoint_path(current_organization.slug, @project, @endpoint),
                  notice: "Endpoint created."
    else
      @event_types = @project.event_types
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @event_types = @project.event_types
  end

  def update
    if @endpoint.update(endpoint_params)
      sync_event_types(@endpoint)
      redirect_to organization_project_endpoint_path(current_organization.slug, @project, @endpoint),
                  notice: "Endpoint updated."
    else
      @event_types = @project.event_types
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @endpoint.destroy
    redirect_to organization_project_endpoints_path(current_organization.slug, @project),
                notice: "Endpoint deleted."
  end

  def toggle
    @endpoint.update!(enabled: !@endpoint.enabled)
    status = @endpoint.enabled ? "enabled" : "disabled"
    redirect_back fallback_location: organization_project_endpoint_path(current_organization.slug, @project, @endpoint),
                  notice: "Endpoint #{status}."
  end

  def rotate_secret
    new_secret = @endpoint.rotate_secret!
    flash[:secret] = new_secret
    redirect_to organization_project_endpoint_path(current_organization.slug, @project, @endpoint),
                notice: "Signing secret rotated. Copy it now — it won't be shown again."
  end

  def test
    event = @project.events.create!(
      event_type: params[:event_type] || "test.event",
      payload: params[:payload].present? ? JSON.parse(params[:payload]) : { "test" => true },
      status: "queued"
    )

    delivery = Delivery.create!(
      event:,
      webhook_endpoint: @endpoint,
      next_attempt_at: Time.current
    )

    DeliverWebhookJob.perform_later(delivery.id)

    redirect_to organization_project_delivery_path(current_organization.slug, @project, delivery),
                notice: "Test event sent."
  rescue JSON::ParserError
    redirect_back fallback_location: organization_project_endpoint_path(current_organization.slug, @project, @endpoint),
                  alert: "Invalid JSON payload."
  end

  private

  def set_project
    @project = current_organization.projects.find(params[:project_id])
  end

  def set_endpoint
    @endpoint = @project.webhook_endpoints.find(params[:id])
  end

  def endpoint_params
    params.expect(webhook_endpoint: [ :name, :url, :description, :enabled ])
  end

  def sync_event_types(endpoint)
    selected_ids = params[:event_type_ids].to_a.map(&:to_s)
    endpoint.endpoint_event_types.destroy_all
    selected_ids.each do |type_id|
      et = @project.event_types.find_by(id: type_id)
      endpoint.endpoint_event_types.create(event_type: et) if et
    end
  end
end
