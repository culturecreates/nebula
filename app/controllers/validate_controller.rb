class ValidateController < ApplicationController

  def show
    uri = params[:uri] 
    @entity = Entity.new(entity_uri: uri)
    # Call Artsdata API to get the RDF graph for the entity
    mint_endpoint = Rails.application.credentials.artsdata_mint_endpoint
    url = "#{mint_endpoint}/test_event?uri=#{CGI.escape(uri)}"
    response = HTTParty.get(url)
    @entity.graph = RDF::Graph.new
    @entity.graph.from_jsonld(JSON.parse(response.body)['data'].to_json)
  end

  def wikidata
    uri = params[:uri] 
    @entity = Entity.new(entity_uri: uri)
    @class_to_mint = params[:class_to_mint] # i.e. schema:Person

    wikidata_sparql_endpoint= "https://query.wikidata.org/sparql"
    wikidata_sparql = SPARQL::Client.new(wikidata_sparql_endpoint)

    response = wikidata_sparql.query(sparql_by_class_to_mint(@class_to_mint, uri))
    @entity.graph = RDF::Graph.new << response 
    @entity.replace_blank_nodes # first level
    begin
      shacl = SHACL.open(shacl_by_class_to_mint(@class_to_mint))
      @report = shacl.execute(@entity.graph)
      @entity.load_graph_into_graph(@report)
    rescue => exception
      @entity =  "Error: #{exception}"
    end
   
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
