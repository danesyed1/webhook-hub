class ProjectsController < ApplicationController
  before_action :require_organization_access
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]

  def show
    @stats = @project.delivery_stats
    @recent_deliveries = @project.deliveries
      .includes(:event, :webhook_endpoint, :delivery_attempts)
      .recent
      .limit(20)
    @recent_failures = @project.deliveries.failed.includes(:event, :webhook_endpoint).recent.limit(5)
    @endpoints = @project.webhook_endpoints.includes(:event_types)
  end

  def new
    @project = current_organization.projects.new
  end

  def create
    @project = current_organization.projects.new(project_params)
    if @project.save
      EventType::SEED_TYPES.each { |name| @project.event_types.create(name:) }
      redirect_to organization_project_path(current_organization.slug, @project), notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to organization_project_path(current_organization.slug, @project), notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to organization_path(current_organization.slug), notice: "Project deleted."
  end

  private

  def set_project
    @project = current_organization.projects.find(params[:id])
  end

  def project_params
    params.expect(project: [ :name, :description ])
  end
end
