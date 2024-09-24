module Api
  module V1
    class EventsController < Api::BaseController
      def create
        unless params[:type].present?
          render json: { error: { code: "invalid_request", message: "Event type is required" } }, status: :unprocessable_entity
          return
        end

        event = @current_project.events.create!(
          event_type: params[:type],
          payload: params[:data].to_unsafe_h || {},
          status: "queued"
        )

        endpoints = @current_project.webhook_endpoints.enabled.select do |ep|
          ep.subscribes_to?(event.event_type)
        end

        deliveries = endpoints.map do |endpoint|
          Delivery.create!(
            event:,
            webhook_endpoint: endpoint,
            status: "pending",
            next_attempt_at: Time.current
          )
        end

        deliveries.each { |d| DeliverWebhookJob.perform_later(d.id) }

        render json: {
          id: event.id,
          type: event.event_type,
          status: event.status,
          delivery_count: deliveries.count
        }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: { code: "invalid_request", message: e.message } }, status: :unprocessable_entity
      end
    end
  end
end
