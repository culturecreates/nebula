class MintController < ApplicationController
  before_action :authenticate_user! # ensure user is logged in

  # show tools to mint a new Artsdata URI
  # GET /mint?externalUri=&classToMint=
  def preview
    required = [:externalUri, :classToMint]
    if required.all? { |k| params.key? k }
      @externalUri = params[:externalUri]
      @classToMint = params[:classToMint]
      @classToMint.prepend("http://schema.org/") if !@classToMint.starts_with?("http")
      if @externalUri.starts_with?("http://scenepro.ca")
        @authority = "http://kg.artsdata.ca/resource/K14-90"
      elsif @externalUri.starts_with?("http://kg.footlight.io") || @externalUri.starts_with?("http://api.footlight.io")
        @authority = "https://graph.culturecreates.com/id/footlight"
      elsif @externalUri.starts_with?("http://capacoa.ca")
        @authority = "https://graph.culturecreates.com/id/capacoa-admin"
      elsif @externalUri.starts_with?("https://capacoa.ca/member/")
        @authority = "https://graph.culturecreates.com/id/capacoa-admin"
      elsif @externalUri.starts_with?("http://wikidata.org")
        @authority = "http://wikidata.org"
      else 
        @authority = "http://kg.artsdata.ca/resource/K1-1"
      end
    else 
      flash.alert = "Missing a required param. Required list: #{required}"
      redirect_back(fallback_location: root_path)
    end
  end
end
