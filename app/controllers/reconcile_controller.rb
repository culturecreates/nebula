require 'net/http'
require 'uri'

class ReconcileController < ApplicationController

  # Reconcile
  # GET /reconcile/query?query=&type=
  def query
    required = [:query]
    if required.all? { |k| params.key? k }
      @externalUri = params[:externalUri] # pass through to view for link button
      uri = URI.parse("https://api.artsdata.ca/recon") 
      request = Net::HTTP::Get.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({
          "query" => params[:query],
          "type" => params[:type]
      })
      
      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      @result = JSON.parse(response.body)
    else
      flash.alert = "Missing a required param. Required list: #{required}"
      redirect_back(fallback_location: root_path)
    end
  end

  def postal_code
    required = [:postal_code]
    if required.all? { |k| params.key? k }
      @externalUri = params[:externalUri] # pass through to view for link button
    
      # work on creating a SPARQL that responds like con.
      
      @result = JSON.parse(response.body)
    else
      flash.alert = "Missing a required param. Required list: #{required}"
      redirect_back(fallback_location: root_path)
    end
  end
end