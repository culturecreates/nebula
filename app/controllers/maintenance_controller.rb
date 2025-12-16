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
                  formated_items = ""
                  add_list = items.select{ |item| item["action"] == "add" }
                  unless add_list.empty?
                  formated_items << "<h4>Updates</h4> <ul>"
                    items.select{ |item| item["action"] == "add" }.each do |item|
                      formated_items << format_display(item) 
                    end
                    formated_items << "</ul>"
                  end
                  delete_list = items.select{ |item| item["action"] == "delete" }
                  unless delete_list.empty?
                    formated_items << "<h4>Deletes</h4> <ul>"
                    delete_list.each do |item|
                      formated_items << format_display(item) 
                    end
                    formated_items << "</ul>"
                  end
                  if items.empty?
                    formated_items << "<p>Nothing to update from Wikidata.</p>"
                  end
                  formated_items
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

  def format_display(item)
    if item["object"].to_s.start_with?("_") || item["object"].to_s.include?("#")
      "<li>#{item["predicate"].to_s.split("/").last} #{"(secondary derivation)" if item["claim"] == "derived" }:</li>"
    else
      if item["subject"].to_s.start_with?("_") || item["subject"].to_s.include?("#")
        "<li class='ms-4'>#{item["predicate"].to_s.split("/").last.split("#").last}: <b>#{item["object"].to_s.split("/").last}</b> #{"(secondary derivation)" if item["claim"] == "derived" }</li>"
      else
        "<li>#{item["predicate"].to_s.split("/").last.split("#").last}: <b>#{item["object"].to_s.split("/").last}</b> #{"(secondary derivation)" if item["claim"] == "derived" }</li>"
      end
    end
  end

end
