class OrganizationsController < ApplicationController
  before_action :set_organization, only: [ :show, :edit, :update, :destroy ]
  before_action :require_owner!, only: [ :edit, :update, :destroy ]

  def show
    @projects = @organization.projects.includes(:webhook_endpoints)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)
    if @organization.save
      Membership.create!(user: current_user, organization: @organization, role: "owner")
      redirect_to new_organization_project_path(@organization.slug), notice: "Organization created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to organization_path(@organization.slug), notice: "Organization updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @organization.destroy
    redirect_to root_path, notice: "Organization deleted."
  end

  private

  def set_organization
    @organization = current_user.organizations.find_by!(slug: params[:slug])
  end

  def organization_params
    params.expect(organization: [ :name ])
  end
end
