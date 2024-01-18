class MintController < ApplicationController

  before_action :authenticate_user! # ensure user is logged in

  # show tools to mint a new Artsdata URI
  # GET /mint?externalUri=&classToMint=
  def preview
    required = [:externalUri, :classToMint]
    if required.all? { |k| params.key? k }
      @externalUri = params[:externalUri]
      @classToMint = params[:classToMint]
      if @externalUri.starts_with?("http://scenepro.ca")
        @authority = "http://kg.artsdata.ca/resource/K14-90"
      else
        flash.alert = "Missing publisher authority."
        redirect_to root_path
      end
    else 
      flash.alert = "Missing a required param. Required list: #{required}"
      redirect_to root_path
    end
  end
end
