require 'net/http'

class JobStatusController < ApplicationController
  def index
    # Only fetch job status in staging and production
    if Rails.env.production? || Rails.env.staging?
      begin
        endpoint = "#{Rails.application.config.artsdata_databus_endpoint.sub('/databus', '')}/sidekiq/jobs"
        response = Net::HTTP.get_response(URI.parse(endpoint))
        
        if response.code.to_i == 200
          render json: JSON.parse(response.body), status: :ok
        else
          render json: { error: "Failed to fetch job status" }, status: :service_unavailable
        end
      rescue StandardError => e
        Rails.logger.error "Job status fetch error: #{e.message}"
        render json: { error: "Failed to fetch job status" }, status: :service_unavailable
      end
    else
      # Return empty result for development and test environments
      render json: { queues: [{ name: "default", size: 0, jobs: [] }], processing: [] }, status: :ok
    end
  end
end
