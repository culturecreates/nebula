class ValidateController < ApplicationController

  def show
    uri = params[:uri] 
    @entity = Entity.new(entity_uri: uri)
    @class_to_mint = params[:class_to_mint] # i.e. schema:Person

    wikidata_sparql_endpoint= "https://query.wikidata.org/sparql"
    wikidata_sparql = SPARQL::Client.new(wikidata_sparql_endpoint)

    response = wikidata_sparql.query(sparql_by_class_to_mint(@class_to_mint, uri))
    @entity.graph = RDF::Graph.new << response 

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
    end
  end

  def shacl_by_class_to_mint(class_to_mint)
    case class_to_mint
    when "schema:Person"
      "app/services/shacls/mint_person.ttl"
    when "schema:Organization"
      "app/services/shacls/mint_organization.ttl"
    end

  end



end
