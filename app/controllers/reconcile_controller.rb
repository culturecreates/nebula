require 'net/http'
require 'uri'

class ReconcileController < ApplicationController

  # Reconcile
  # GET /reconcile/query?query=&type=&postalCode=
  # https://wikidata.reconci.link/en/api

  def query
    required = [:query]
    if required.all? { |k| params.key? k }
      @route_name = params[:routeName] ||= 'entity_path' # default is to call entity_path
      @query = params[:query] # pass through to view
      @type = params[:type] # pass through to view
      @externalUri = params[:externalUri] # pass through to view for link button
      @postalCode = params[:postalCode] # restrict reconiliation to a postal code
      

      redirect_to entity_path(uri: @query) if @query.starts_with?("http") || @query.match?(/^K.*-.*$/)
      recon_uri = params[:reconEndpoint] || Rails.application.credentials.artsdata_recon_endpoint
      recon_service = ReconService.new(recon_uri)
      response = recon_service.query_party(params)
    
      if response.code.to_s.include?("200")

      
      # uri = URI.parse(Rails.application.credentials.recon_endpoint) 
      # request = Net::HTTP::Get.new(uri)
      # request["Content-Type"] = "application/json"

      # body_hash = {
      #   "query" => @query,
      #   "type" =>  @type
      # }
      # if @postalCode
      #   body_hash["properties"] = [{pid: "schema:address/schema:postalCode", v: @postalCode}]
      # end
      # request.body = JSON.dump(body_hash)
  
      # req_options = {
      #   use_ssl: uri.scheme == "https",
      # }

      # response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      #   http.request(request)
      # end
     # if response.code == "200"
        @result = JSON.parse(response.body)
        @result = @result["q0"] if @result["q0"] 
        # puts "@result: #{@result}"
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