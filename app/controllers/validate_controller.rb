class ValidateController < ApplicationController

  def show
    uri = params[:uri]
    class_to_mint = params[:classToMint]
    # Call Artsdata API to get the RDF graph for the entity
    mint_endpoint = Rails.application.credentials.artsdata_mint_endpoint
    url = "#{mint_endpoint}/preview?uri=#{CGI.escape(uri)}&classToMint=#{class_to_mint}"
    response = HTTParty.get(url)

    @report = JSON.parse(response.body)['message']
    @entity = Entity.new(entity_uri: "http://new.uri")
    @entity.graph = RDF::Graph.new
    body = JSON.parse(response.body)
    if body['status'] == "success"
      jsonld_data = body['data']
      @entity.graph = RDF::Graph.new do |graph|
        RDF::Reader.for(:jsonld).new(jsonld_data.to_json, rdfstar: true)  {|reader| graph << reader}
      end
    end
  end

  def wikidata
    uri = params[:uri] 
    @entity = Entity.new(entity_uri: uri)
    @class_to_mint = params[:class_to_mint] # i.e. schema:Person

    wikidata_sparql_endpoint= "https://query.wikidata.org/sparql"
    wikidata_sparql = SPARQL::Client.new(wikidata_sparql_endpoint)

    response = wikidata_sparql.query(sparql_by_class_to_mint(@class_to_mint, uri))
    @entity.graph = RDF::Graph.new << response 

    ## TODO: Call Artsdata API Preview endpoint to get the SHACL report
   
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
