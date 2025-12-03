class MaintenanceController < ApplicationController
  before_action :check_refresh_access, only: [:refresh_entity] # ensure user has permissions

  def refresh_entity
    artsdata_uri = params[:uri]
    dryrun = params[:dryrun] ||= false
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
    if response.code != 200
      flash[:alert] = "Failed to request entity refresh for #{artsdata_uri} from publisher #{publisher}. Error: #{response.body.truncate(100)}"
      redirect_to entity_path(uri: artsdata_uri) 
    else
      redirect_to entity_path(uri: artsdata_uri), notice: "#{dryrun ? "Dry run." : "Success."} logs: #{JSON.parse(response.body)['logs'].to_s.truncate(1000)}"
    end 
  
    
  end

    private

  # Check if the user has access the the minting feature
  def check_refresh_access
    ensure_access("refresh_entity")
  end
end
