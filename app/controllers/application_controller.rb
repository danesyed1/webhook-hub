class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_user, :current_organization, :logged_in?

  before_action :require_login

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_organization
    return @current_organization if defined?(@current_organization)
    @current_organization = if params[:organization_slug]
      current_user&.organizations&.find_by(slug: params[:organization_slug])
    end
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Please sign in to continue."
    end
  end

  def require_organization_access
    unless current_organization
      redirect_to root_path, alert: "Organization not found."
    end
  end

  def current_membership
    @current_membership ||= current_user&.memberships&.find_by(organization: current_organization)
  end

  def require_owner!
    unless current_membership&.role == "owner"
      redirect_back fallback_location: root_path, alert: "Only organization owners can do that."
    end
  end
end
