require 'net/http'
require 'uri'

class ReconcileController < ApplicationController
  before_action :check_minting_access, only: [:batch] # ensure user has permissions

  def batch
    @user_uri = user_uri
    @reconciliation_service_endpoint = Rails.application.config.artsdata_recon_endpoint
    @mint_service_endpoint = Rails.application.config.artsdata_mint_endpoint
    @link_service_endpoint = Rails.application.config.artsdata_link_endpoint
  end

  # Reconcile - calls a Reconciliation API v0.2 API with a query and returns results
  # Main params:
  #   - query (required) : the reconciliation query string to match against (e.g. name of a person, place, or organization)
  #   - reconEndpoint : Reconciliation API v0.2 endpoint to send the query to, default is set to Artsdata Reconciliation API
  #   - type : the type to reconcile against (e.g. Person, Place, Organization)
  #   - postalCode : to restrict reconciliation to a postal code (if supported by the Reconciliation API)
  #   - match : set to true to return only results with a high confidence match
  #   
  # Optional params (not used in reconciliation API): pass through to the view for display and linking
  #   - routeName : the named route to use when clicking a match results in the view, default is entity_path. Set to "wikidata_path" when using "mint from Wikidata" feature.
  #   - externalUri : the external URI of the entity being reconciled, used for link buttons in the view
  #   - dataset : the source graph (void:inDataset) URI of the entity being reconciled, used for link buttons in the view
  # 
  # Common Reconciliation API endpoints: 
  #   - Artsdata: https://api.artsdata.ca/recon
  #   - Wikidata: https://wikidata.reconci.link/en/api
  # 
  # GET /reconcile/query
  def query
    required = [:query]
    if required.all? { |k| params.key? k }
      @query = params[:query] # pass through to view
      recon_uri = params[:reconEndpoint] || Rails.application.config.artsdata_recon_endpoint_v0
      @type = params[:type] # pass through to view
      @postalCode = params[:postalCode] # restrict reconciliation to a postal code
      match = params[:match] || false # to set to return only matches
      
      @route_name = params[:routeName] ||= 'entity_path' # default is to call entity_path
      @externalUri = params[:externalUri] # pass through to view for link button
      @dataset = params[:dataset] # pass through to view for link button
      
      # If the query looks like an Artsdata URI or an entity ID, skip reconciliation and go straight to the entity page
      redirect_to entity_path(uri: @query) if @query.starts_with?("http") || @query.match?(/^K.*-.*$/)

      # remove extra spaces and newlines
      @query.squish! 
      
      recon_service = ReconService.new(recon_uri)
      response = recon_service.query_party(query: @query, type: @type, postalCode: @postalCode)
    
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

  private

  # Check if the user has access the the minting feature
  def check_minting_access
    ensure_access("minting")
  end
end