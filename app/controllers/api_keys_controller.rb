class ApiKeysController < ApplicationController
  before_action :require_organization_access
  before_action :set_project
  before_action :set_api_key, only: [ :destroy ]

  def index
    @api_keys = @project.api_keys.order(created_at: :desc)
  end

  def create
    api_key, raw_key = ApiKey.generate_for(@project)
    api_key.name = params.dig(:api_key, :name).presence || "API Key"
    if api_key.save
      flash[:raw_key] = raw_key
      redirect_to organization_project_api_keys_path(current_organization.slug, @project),
                  notice: "API key created. Copy it now — it won't be shown again."
    else
      @api_keys = @project.api_keys
      flash[:alert] = "Failed to create API key."
      redirect_to organization_project_api_keys_path(current_organization.slug, @project)
    end
  end

  def destroy
    @api_key.revoke!
    redirect_to organization_project_api_keys_path(current_organization.slug, @project),
                notice: "API key revoked."
  end

  private

  def set_project
    @project = current_organization.projects.find(params[:project_id])
  end

  def set_api_key
    @api_key = @project.api_keys.find(params[:id])
  end
end
