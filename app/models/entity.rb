
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