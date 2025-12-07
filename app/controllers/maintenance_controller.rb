class MaintenanceController < ApplicationController
  before_action :check_refresh_access, only: [:refresh_entity] # ensure user has permissions

  def refresh_entity
    artsdata_uri = params[:uri]
    dryrun = ActiveModel::Type::Boolean.new.cast(params[:dryrun])
    publisher = user_uri
    # Call Artsdata API to refresh entity data
    api_endpoint = Rails.application.config.artsdata_maintenance_endpoint + "/refresh_entity"
    response = HTTParty.post(api_endpoint,
      body: {
        uri: artsdata_uri,
        publisher: publisher,
        dryrun: dryrun
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    if dryrun
      message = if response.code != 200
        "Failed. Error: #{response.body.truncate(1000)}"
      else
        items = JSON.parse(response.body)['logs']
        formated_items = "<h4> Updates</h4><ul>"
        items.each do |item|
          formated_items << "<li>#{item.to_s}</li>"
        end
        formated_items << "</ul>"
      end
      render json: { message: message }
    else
      if response.code != 200
        flash[:alert] = "Failed. Error: #{response.body.truncate(1000)}"
      else
        flash[:notice] = "Successfully refreshed #{artsdata_uri}."
      end
      render json: { redirect_url: entity_path(uri: artsdata_uri) }
    end
  end

    private

  # Check if the user has access the the minting feature
  def check_refresh_access
    ensure_access("refresh_entity")
  end
end
