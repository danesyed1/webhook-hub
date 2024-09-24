class EventsController < ApplicationController
  before_action :require_organization_access
  before_action :set_project
  before_action :set_event, only: [ :show ]

  def index
    @events = @project.events.recent.includes(:deliveries).limit(50)
  end

  def show
    @deliveries = @event.deliveries.includes(:webhook_endpoint, :delivery_attempts)
  end

  private

  def set_project
    @project = current_organization.projects.find(params[:project_id])
  end

  def set_event
    @event = @project.events.find(params[:id])
  end
end
