module Api
  class BaseController < ActionController::API
    before_action :authenticate_api_key!

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActionController::ParameterMissing, with: :bad_request

    private

    def authenticate_api_key!
      raw_key = request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
      unless raw_key.present?
        render json: { error: { code: "unauthorized", message: "API key required" } }, status: :unauthorized
        return
      end

      @current_api_key = ApiKey.authenticate(raw_key)
      unless @current_api_key
        render json: { error: { code: "unauthorized", message: "Invalid or revoked API key" } }, status: :unauthorized
        return
      end

      @current_api_key.touch_last_used!
      @current_project = @current_api_key.project

      if params[:project_id].present? && @current_project.id != params[:project_id]
        render json: { error: { code: "not_found", message: "Project not found" } }, status: :not_found
      end
    end

    def not_found
      render json: { error: { code: "not_found", message: "Resource not found" } }, status: :not_found
    end

    def bad_request(e)
      render json: { error: { code: "invalid_request", message: e.message } }, status: :bad_request
    end
  end
end
