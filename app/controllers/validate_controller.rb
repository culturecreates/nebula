class ValidateController < ApplicationController

  def show
    uri = params[:uri] 
    @entity = Entity.new(entity_uri: uri)
    wikidata_sparql_endpoint= "https://query.wikidata.org/sparql"
    wikidata_sparql = SPARQL::Client.new(wikidata_sparql_endpoint)
    response = wikidata_sparql.query("CONSTRUCT { <#{uri}> a schema:Person; schema:name ?name ; schema:sameAs ?aduri . } WHERE { <#{uri}> ?p ?o ; <http://www.wikidata.org/prop/direct/P7627> ?adid . BIND (URI(CONCAT(\"http://kg.artsdata.ca/resource/\",?adid)) as ?aduri) }")
    @entity.graph = RDF::Graph.new << response 

    begin
      shacl = SHACL.open("app/services/shacls/mint_person.ttl")
      @report = shacl.execute(@entity.graph)
      @entity.load_graph_into_graph(@report)
    rescue => exception
      @entity =  "Error: #{exception}"
    end
   
  end


end
