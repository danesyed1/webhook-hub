class RegistrationsController < ApplicationController
  skip_before_action :require_login

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      org_name = params[:organization_name].presence || "#{@user.name}'s Organization"
      org = Organization.create!(name: org_name)
      Membership.create!(user: @user, organization: org, role: "owner")
      EventType::SEED_TYPES.each { |name| org.projects.first&.event_types&.create(name:) }

      session[:user_id] = @user.id
      redirect_to new_organization_project_path(org.slug), notice: "Welcome to WebhookHub! Create your first project."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :name, :email, :password, :password_confirmation ])
  end
end
