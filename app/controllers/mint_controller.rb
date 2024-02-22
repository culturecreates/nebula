class MintController < ApplicationController
  before_action :authenticate_user! # ensure user is logged in
  before_action :set_authority, only: [:preview, :link] # known as publisher in Artsdata API
  include DereferenceHelper 

  # show tools to mint a new Artsdata URI
  # GET /mint/preview?externalUri=&classToMint=
  def preview
    required = [:externalUri]
    if required.all? { |k| params.key? k } && @authority
      @externalUri = params[:externalUri]
      @classToMint = params[:classToMint]
      @label = params[:label]

      # get extra data about the entity
      # replace this with a SHACL validation
      @entity = Entity.new(entity_uri: @externalUri)
      @entity.load_card
      solution =  dereference_helper(@externalUri)
      
      if !@label
        @label = solution.label if solution.bound?(:label)
      end

      if !@classToMint
        @classToMint = solution.type if solution.bound?(:type)
      end
      if  !@classToMint.starts_with?("http") 
        @classToMint = "http://schema.org/" + @classToMint
      end


      @postalCode = solution.postalCode if solution.bound?(:postalCode)
      @startDate = solution.startDate if solution.bound?(:startDate)
    else 
      flash.now.alert = "Missing a required param. Required list: #{required}"
    end
  end

  # Link to an existing Artsdata URI
  # GET /mint/link?externalUri=&classToMint=&adUri=&
  def link 
    required = [:externalUri, :classToMint, :adUri]
    if required.all? { |k| params.key? k } && @authority
      @externalUri = params[:externalUri]
      @classToMint =  if params[:classToMint].starts_with?("http") 
                        params[:classToMint]
                      else
                        "http://schema.org/" + params[:classToMint]
                      end
      @adUri = params[:adUri]

      # call link in mint service
      uri = URI.parse("https://api.artsdata.ca/link") 

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({
          "publisher" => @authority,
          "externalUri" => @externalUri,
          "classToLink" => @classToMint,
          "adUri" => @adUri
      })
      
      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      @result = JSON.parse(response.body)
      if @result["status"] == "success"
        flash.notice = "Successfully linked #{@externalUri} to #{@adUri}"
      else  
        flash.alert = "Failed to link #{@externalUri} to #{@adUri}.  #{@result}"
      end
      redirect_back(fallback_location: root_path)
    else
      flash.alert = "Missing a required param. Required list: #{required}"
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def set_authority
    externalUri = params[:externalUri]
    return unless params[:externalUri]

    if externalUri.starts_with?("http://scenepro.ca")
      @authority = "http://kg.artsdata.ca/resource/K14-90"
    elsif externalUri.starts_with?("http://kg.footlight.io") || externalUri.starts_with?("http://api.footlight.io")
      @authority = "https://graph.culturecreates.com/id/footlight"
    elsif externalUri.starts_with?("http://capacoa.ca")
      @authority = "https://graph.culturecreates.com/id/capacoa-admin"
    elsif externalUri.starts_with?("https://capacoa.ca/member/")
      @authority = "https://graph.culturecreates.com/id/capacoa-admin"
    elsif externalUri.starts_with?("http://wikidata.org")
      @authority = "http://wikidata.org" 
    elsif externalUri.starts_with?("https://ipaa.ca")
      @authority = "http://kg.artsdata.ca/resource/K14-165"
    else 
      @authority = "http://kg.artsdata.ca/resource/K1-1"
    end
  end

end