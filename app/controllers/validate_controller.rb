class ValidateController < ApplicationController

  def show
    uri = params[:uri]
    class_to_mint = params[:classToMint]
    mint_endpoint = Rails.application.config.artsdata_mint_endpoint

    # Call Artsdata API to get the RDF graph for the entity
    url = "#{mint_endpoint}/preview?uri=#{CGI.escape(uri)}&classToMint=#{class_to_mint}"
    
    # COMMON CODE
    begin
      response = HTTParty.get(url)
      raise "Mint API #{response.code}: #{response.message}" if response['status'] != 'success'
    rescue => e
      flash.now.alert = "Error calling Mint Preview API: #{e.message.truncate(100)}"
    end
   
    body = JSON.parse(response.body)
    @entity = Entity.new(entity_uri: "http://new.uri")
    if body['status'] == "success"
      @report = body['message']
      jsonld_data = body['data']
      @entity.graph = RDF::Graph.new do |graph|
        RDF::Reader.for(:jsonld).new(jsonld_data.to_json, rdfstar: true)  {|reader| graph << reader}
      end
    else
      @entity.graph = RDF::Graph.new
      flash.now.alert = "Data Error: #{body['message'].truncate(100)}"
    end
  end

  def wikidata
    uri = params[:uri] 
    @class_to_mint = params[:class_to_mint] # i.e. schema:Person
    mint_endpoint = Rails.application.config.artsdata_mint_endpoint


    
    begin
      
      ## Build graph from Wikidata
      #
      #### Move to Artsdata API
      wikidata_sparql_endpoint= "https://query.wikidata.org/sparql"
      wikidata_sparql = SPARQL::Client.new(wikidata_sparql_endpoint)
      response = wikidata_sparql.query(sparql_by_class_to_mint(@class_to_mint, uri))
      entity = Entity.new(entity_uri: uri)
      entity.graph = RDF::Graph.new << response 
      facts = CGI.escape(entity.graph.dump(:jsonld).squish)
      #######
      # end move
      #########

      ## Call Artsdata Preview with facts (JSON-LD) from Wikidata
      url = "#{mint_endpoint}/preview?classToMint=#{@class_to_mint}&facts=#{facts}"
      
      # COMMON CODE
      response = HTTParty.get(url)
      raise "Mint API Error: #{response.code} - #{response.message}" if response.code != 200
      
      
      
      
      body = JSON.parse(response.body)
      @report = body['message']
      @entity = Entity.new(entity_uri: "http://new.uri")
      if body['status'] == "success"
        jsonld_data = body['data']
        @entity.graph = RDF::Graph.new do |graph|
          RDF::Reader.for(:jsonld).new(jsonld_data.to_json, rdfstar: true)  {|reader| graph << reader}
        end
      end
    rescue => e
      flash.now.alert = "Error: #{e.message}"
    end
    render :show
  end

  # TODO: Remove because this was moved to Artsdata API
  def sparql_by_class_to_mint(class_to_mint, uri)
    case class_to_mint
    when "schema:Person"
      SparqlLoader.load("validate_controller/external_person_data", ["EXTERNAL_URI", uri])
    when "schema:Organization"
      SparqlLoader.load("validate_controller/external_organization_data", ["EXTERNAL_URI", uri])
    when "schema:Place"
      SparqlLoader.load("validate_controller/external_place_data", ["EXTERNAL_URI", uri])
    end
  end

  def shacl_by_class_to_mint(class_to_mint)
    case class_to_mint
    when "schema:Person"
      "app/services/shacls/mint_person.ttl"
    when "schema:Organization"
      "app/services/shacls/mint_organization.ttl"
    when "schema:Place"
      "app/services/shacls/mint_place.ttl"
    end

  end



end
