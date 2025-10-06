class ValidateController < ApplicationController

  def show
    uri = params[:uri]
    class_to_mint = params[:classToMint]
    # Call Artsdata API to get the RDF graph for the entity
    mint_endpoint = Rails.application.config.artsdata_mint_endpoint
    url = "#{mint_endpoint}/preview?uri=#{CGI.escape(uri)}&classToMint=#{class_to_mint}"
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
    @entity = Entity.new(entity_uri: uri)
    @class_to_mint = params[:class_to_mint] # i.e. schema:Person
    begin
      ## Build graph from Wikidata
      wikidata_sparql_endpoint= "https://query.wikidata.org/sparql"
      wikidata_sparql = SPARQL::Client.new(wikidata_sparql_endpoint)
      response = wikidata_sparql.query(sparql_by_class_to_mint(@class_to_mint, uri))
      @entity.graph = RDF::Graph.new << response 

      ## Call Artsdata Preview with facts (JSON-LD) from Wikidata
      mint_endpoint = Rails.application.config.artsdata_mint_endpoint
      facts = CGI.escape(@entity.graph.dump(:jsonld).squish)
      
      url = "#{mint_endpoint}/preview?classToMint=#{@class_to_mint}&facts=#{facts}"
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
