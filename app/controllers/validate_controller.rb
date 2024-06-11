class ValidateController < ApplicationController

  def show
    uri = params[:uri] 
    @entity = Entity.new(entity_uri: uri)
    wikidata_sparql_endpoint= "https://query.wikidata.org/sparql"
    wikidata_sparql = SPARQL::Client.new(wikidata_sparql_endpoint)
    response = wikidata_sparql.query(<<-SPARQL)
      CONSTRUCT { 
        <#{uri}> a schema:Person ; 
        schema:name ?name ; 
        schema:sameAs ?aduri ;
        schema:description ?desc ;
        schema:gender ?gender ;
        schema:occupation ?occupation ;
        schema:birthDate ?birth_date ;
        schema:birthPlace ?birth_place ;
        schema:url ?url ;
        schema:sameAs ?isniuri , ?music_brainz .
      } 
      WHERE { 
        <#{uri}> <http://www.w3.org/2000/01/rdf-schema#label> ?name . 
        filter (lang(?name) = 'en' || lang(?name) = 'fr')

        OPTIONAL { 
          <#{uri}>  schema:description ?desc . 
          filter (lang(?desc) = 'en' || lang(?desc) = 'fr') 
        }
          
        OPTIONAL { 
          <#{uri}> <http://www.wikidata.org/prop/direct/P7627> ?adid  .
          BIND (URI(CONCAT(\"http://kg.artsdata.ca/resource/\",?adid)) as ?aduri) 
        }
        OPTIONAL { <#{uri}> <http://www.wikidata.org/prop/direct/P21> ?gender .}
        OPTIONAL { <#{uri}> <http://www.wikidata.org/prop/direct/P106> ?occupation .}
        OPTIONAL { <#{uri}> <http://www.wikidata.org/prop/direct/P19> ?birth_place .}
        OPTIONAL { <#{uri}> <http://www.wikidata.org/prop/direct/P569> ?birth_date .}
        OPTIONAL { <#{uri}> <http://www.wikidata.org/prop/direct/P856> ?url .}
        OPTIONAL { 
          <#{uri}> <http://www.wikidata.org/prop/direct/P213> ?isni .
          BIND (URI(CONCAT(\"https://isni.org/isni/\",?isni)) as ?isniuri)
        }
        OPTIONAL { <#{uri}> <http://www.wikidata.org/prop/direct-normalized/P434> ?music_brainz .
      }
    SPARQL
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
