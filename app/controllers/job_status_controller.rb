require 'net/http'

class JobStatusController < ApplicationController
  def index
    # Only fetch job status in staging and production
    if Rails.env.production? || Rails.env.staging?
      # The nav bar polls this every 10s from every open tab; cache the
      # upstream fetch briefly so many concurrent polls collapse into one
      # actual outbound request instead of each blocking its own Puma
      # thread on a ~0.5-4s Net::HTTP call.
      result = Rails.cache.fetch("job_status", expires_in: 5.seconds) do
        begin
          endpoint = "#{Rails.application.config.artsdata_databus_endpoint.sub('/databus', '')}/sidekiq/jobs"
          response = Net::HTTP.get_response(URI.parse(endpoint))

          if response.code.to_i == 200
            { status: :ok, body: JSON.parse(response.body) }
          else
            { status: :service_unavailable, body: { error: "Failed to fetch job status" } }
          end
        rescue StandardError => e
          Rails.logger.error "Job status fetch error: #{e.message}"
          { status: :service_unavailable, body: { error: "Failed to fetch job status" } }
        end
      end
      render json: result[:body], status: result[:status]
    else
      # Return empty result for development and test environments
      render json: { queues: [{ name: "default", size: 0, jobs: [] }], processing: [] }, status: :ok
    end
  end
end
