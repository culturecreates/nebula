
class Entity
  attr_accessor :entity_uri, :graph
  @@artsdata_client = ArtsdataApi::V2::Client.new(
        graph_repository: Rails.application.credentials.graph_repository, 
        api_endpoint: Rails.application.credentials.graph_api_endpoint)

  def initialize(**h) 
    @entity_uri = h[:entity_uri]
  end

  def method_missing(m,*args,&block)
    if m.to_s == 'main_image'
      ""
    else
      "missing"
    end 
  end

  def load_shacl_into_graph(shacl_name) 
    @shacl = "app/services/shacls/#{shacl_name}"
    @graph << RDF::Graph.load(@shacl)
  end

  def dereference
    sparql =  SparqlLoader.load('dereference', [
      'URI_PLACEHOLDER', self.entity_uri
    ])
    @graph = construct_turtle(sparql)
  end

  def expand_entity_property(predicate:)
    sparql =  SparqlLoader.load('expand_entity_property', [
      'URI_PLACEHOLDER', self.entity_uri,
      'schema:name', "<#{predicate}>"
    ])
    puts "SPARQL: #{sparql}"
    @graph = construct_turtle(sparql)
  end

  def construct_turtle(sparql)
    response = @@artsdata_client.execute_construct_turtle_star_sparql(sparql)
    if response[:code] == 200
      RDF::Graph.new do |graph|
        RDF::Turtle::Reader.new(response[:message], rdfstar: true) {|reader| graph << reader}
      end
    else
      RDF::Graph.new
    end
  end


  def load_graph(approach = "rdfstar", language = "en")
    sparql =  SparqlLoader.load('load_rdfstar_graph', [
                  'entity_uri_placeholder', self.entity_uri,
                  'locale_placeholder' , language
                ])

    response = @@artsdata_client.execute_construct_turtle_star_sparql(sparql)

    @graph = if response[:code] == 200
      RDF::Graph.new do |graph|
        RDF::Turtle::Reader.new(response[:message], rdfstar: true) {|reader| graph << reader}
      end
    else
      RDF::Graph.new
    end
  end

  def entity_jsonld
    if @graph.count > 0
      JSON.parse(@graph.dump(:jsonld)).first
    else
      [] # return empty array
    end
  end

end