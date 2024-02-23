require 'net/http'
require 'uri'

class ReconcileController < ApplicationController

  # Reconcile
  # GET /reconcile/query?query=&type=&postalCode=
  def query
    required = [:query]
    if required.all? { |k| params.key? k }
      @query = params[:query]
      @type = params[:type]
      @externalUri = params[:externalUri] # pass through to view for link button
      @postalCode = params[:postalCode] # restrict reconiliation to a postal code

      redirect_to entity_path(uri: @query) if @query.starts_with?("http") || @query.match?(/^K.*-.*$/)
      
      uri = URI.parse("https://api.artsdata.ca/recon") 
      request = Net::HTTP::Get.new(uri)
      request["Content-Type"] = "application/json"

      body_hash = {
        "query" => @query,
        "type" =>  @type
      }
      if @postalCode
        body_hash["properties"] = [{pid: "schema:address/schema:postalCode", v: @postalCode}]
      end
      request.body = JSON.dump(body_hash)
  
      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      if response.code == "200"
        @result = JSON.parse(response.body)
      else
        flash.alert = "Error: #{response.code} - #{response.message}"
        redirect_back(fallback_location: root_path)
      end
    else
      flash.alert = "Missing a required param. Required list: #{required}"
      redirect_back(fallback_location: root_path)
    end
  end

  # def postal_code
  #   required = [:postal_code]
  #   if required.all? { |k| params.key? k }
  #     @externalUri = params[:externalUri] # pass through to view for link button
    
  #     # work on creating a SPARQL that responds like con.
      
  #     @result = JSON.parse(response.body)
  #   else
  #     flash.alert = "Missing a required param. Required list: #{required}"
  #     redirect_back(fallback_location: root_path)
  #   end
  # end
end