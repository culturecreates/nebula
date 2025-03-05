class MintController < ApplicationController
  before_action :temporarily_disable # :authenticate_user! # ensure user has permissions
  before_action :set_authority, only: [:preview, :link] # known as publisher in Artsdata API
  include DereferenceHelper 

  # show data before minting a new Artsdata URI
  # GET /mint/preview
  #   externalUri (required)
  #   classToMint
  #   label
  #   language
  #   reference = the prov#wasDerivedFrom URI of the entity
  #   postalCode
  #   startDate
  def preview
    required = [:externalUri]
    if required.all? { |k| params.key? k } && @authority
      @externalUri = params[:externalUri]
      @classToMint = params[:classToMint]

      @label = params[:label]
      @reference =  params[:reference]

      # get extra data about the entity when only externalUri is provided
      # Need: 
      # - reference (i.e. artifact)
      # - label (i.e. name)
      # - language (of name)
      # - classToMint (i.e. type)
      # - postalCode
      # - startDate
      @entity = Entity.new(entity_uri: @externalUri)
      @entity.load_card
      
    
      if !@reference
        reference = {
          subject: RDF::URI(@externalUri),
          predicate: RDF::URI("http://www.w3.org/ns/prov#wasDerivedFrom"),
          object: nil
        }
        @reference =  @entity.graph.query(reference)&.first&.object&.value
      end

      if !@label
        @label = @entity.label&.value
      end
      
      @language = @entity&.label&.language 
      
      if !@classToMint
        @classToMint = @entity.top_level_type 
      end
      
      # if classToMint was passed in as a parameter wihtout a full URI, add schema.org prefix
      if !@classToMint&.starts_with?("http") 
        @classToMint = "http://schema.org/" + @classToMint
      end

      @postalCode = @entity.card[:postal_code]
      @startDate =  @entity.card[:start_date]
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
      artsdata_link_endpoint = Rails.application.credentials.artsdata_link_endpoint
      uri = URI.parse(artsdata_link_endpoint) 

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

  # Mint an existing Wikidata URI
  # GET /mint/wikidata?wikidata_id=&classToMint=
  def wikidata
    #mapping table for wikidata types
    @wikidata_place_type = "Q17350442"
    @wikidata_person_type = "Q5"
    @wikidata_organization_type = "Q43229"

    # Search wikidata
    #  - reconile name and type against wikidata(even when the user entered a QID) 
    #    and show other close matches incase there are duplicates in Wikidata
    if params[:wikidata_search].present?
     
      @wikidata_data = {}
      if params[:wikidata_search] =~ /\AQ\d+\z/ # Wikidata ID
        @wikidata_data[:label] = params[:wikidata_search]
      elsif params[:wikidata_search] =~ /\Ahttp/ # Wikidata URI
        qid = params[:wikidata_search].split("/").last
        @wikidata_data[:label] = convert_id_to_name(qid)
      else # Wikidata label
        @wikidata_data[:label] = params[:wikidata_search] 
      end
      @wikidata_data[:type] = params[:type] if params[:type]
    end
   
    # Continue after user selects a wikidata entity from initial search results
    if params[:uri].present? 
      @external_uri = "http://www.wikidata.org/entity/#{params[:uri]}"
      @class_to_mint = map_wikidata_type_to_schema(params[:type])

      # call wikidata sparql to get more data
      sparql = SPARQL::Client.new("https://query.wikidata.org/sparql")
      select_query = <<-SPARQL
        select * where {
          <http://www.wikidata.org/entity/#{params[:uri]}> rdfs:label ?label .
          OPTIONAL {
            <http://www.wikidata.org/entity/#{params[:uri]}> schema:description ?desc . 
            filter (lang(?desc) = 'en' || lang(?desc) = 'fr') 
          }
          filter (lang(?label) = 'en' || lang(?label) = 'fr') 
        }
      SPARQL
      solutions = sparql.query(select_query)
      @label = solutions.map { |s| s.label.to_s if s.bound?(:label) }.first 
      @description = solutions.map { |s| s.desc.to_s if s.bound?(:desc) }.first 
      @language = "en"
      @reference = "http://www.wikidata.org/entity/#{params[:uri]}"
      @group = 'http://wikidata.org'
    end


  end

  private

  def convert_id_to_name(wikidata_id)
    sparql = SPARQL::Client.new("https://query.wikidata.org/sparql")
    select_query = "select * where {<http://www.wikidata.org/entity/#{wikidata_id}> rdfs:label ?label. filter (lang(?label) = 'en' || lang(?label) = 'fr') }"
    solutions = sparql.query(select_query)
    solutions.first.label.to_s if solutions.first&.bound?(:label)
  end

  def map_wikidata_type_to_schema(wikidata_type)
    if wikidata_type == @wikidata_place_type
      "schema:Place"
    elsif wikidata_type == @wikidata_person_type
      "schema:Person"
    elsif wikidata_type == @wikidata_organization_type
      "schema:Organization"
    end
  end

  def set_authority
    return unless params[:externalUri]

    externalUri = params[:externalUri]
    if externalUri.starts_with?("http://scenepro.ca")
      @authority = "http://kg.artsdata.ca/resource/K14-90"
    elsif externalUri.starts_with?("http://kg.footlight.io") || externalUri.starts_with?("http://lod.footlight.io")
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