require 'net/http'
require 'uri'

class ReconcileController < ApplicationController

  def batch; end

  # Reconcile - returns only Artsdata URIs
  # GET /reconcile/query?query=&type=&postalCode=
  # https://wikidata.reconci.link/en/api
  def query
    required = [:query]
    if required.all? { |k| params.key? k }
      @route_name = params[:routeName] ||= 'entity_path' # default is to call entity_path
      @query = params[:query] # pass through to view
      @type = params[:type] # pass through to view
      @externalUri = params[:externalUri] # pass through to view for link button
      @postalCode = params[:postalCode] # restrict reconciliation to a postal code
      match = params[:match] || false # to set to return only matches
      

      redirect_to entity_path(uri: @query) if @query.starts_with?("http") || @query.match?(/^K.*-.*$/)

      @query.squish! # remove extra spaces and newlines
      recon_uri = params[:reconEndpoint] || Rails.application.credentials.artsdata_recon_endpoint
      recon_service = ReconService.new(recon_uri)
      response = recon_service.query_party(params)
    
      if response.code.to_s.include?("200")
        @result = JSON.parse(response.body)
        @result = @result["q0"]["result"] if @result["q0"] 
        if match
          @result.select! { |r| r["match"] == true }
        end
      else
        flash.alert = "Error: #{response.code} - #{response.message}"
        redirect_back(fallback_location: root_path)
      end
    else
      flash.alert = "Missing a required param. Required list: #{required}"
      redirect_back(fallback_location: root_path)
    end
  end

  # Query skipping recon service by using luc:name and include URIs outside of artsdata.ca
  def query_non_authoritative
    required = [:query]
    if required.all? { |k| params.key? k }
      @query = params[:query] # pass through to view
     

    else
      flash.alert = "Missing a required param. Required list: #{required}"
      redirect_back(fallback_location: root_path)
    end
    
  end
end