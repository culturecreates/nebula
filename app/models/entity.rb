
class Entity
  attr_accessor :entity_uri, :graph
  @@artsdata_client = ArtsdataApi::V2::Client.new(
        graph_repository: Rails.application.credentials.graph_repository, 
        api_endpoint: Rails.application.credentials.graph_api_endpoint)

  def initialize(**h) 
    @entity_uri = h[:entity_uri]
    @graph = h[:graph]
  end

  # Try to get a label of name property
  def label
    solution = @graph.query([RDF::URI(@entity_uri), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), nil])
    return  solution.first.object.value if solution.count > 0
  
    solution = @graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/name"), nil])
    solution.first.object.value if solution.count > 0
  end

  def k_number
     return @entity_uri.split("http://kg.artsdata.ca/resource/").last
  end

  # Try to get image uri from schema.org/image property or schema.org/image/url property
  def image
    solution = @graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/image"), nil])
    if solution.count > 0
      s = solution.first.object
      if s.node? # if blank node
        image = @graph.query([s, RDF::URI("http://schema.org/url"), nil])
        image.first.object.value if image.count > 0
      else
        s.value if !s.value.end_with?("#ImageObject")
      end
    end
  end
  

  def type
    uri = @entity_uri
    graph = @graph

    query = RDF::Query.new do
      pattern [RDF::URI(uri), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
    end
    solution =  graph.query(query)
    
    type = solution&.first&.type 
    # try to return top level type
    if type
      solution.each do |s|
        type = s.type if ["http://schema.org/Place","http://schema.org/Person","http://schema.org/Organization"].include?(s.type)
      end
    end

    return type
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

  def load_graph_into_graph(graph)
    @graph << graph
  end

  def load_card
    sparql =  SparqlLoader.load('load_card', [
      'URI_PLACEHOLDER', self.entity_uri
    ])
    
    @graph = construct_turtle(sparql)

  end

  # load rdf from external URL
  def dereference
    @graph = RDF::Graph.new 
    # first try proper content negotiation
    begin
      @graph = RDF::Graph.load(self.entity_uri, rdfstar: true)
    rescue StandardError => e
      raise StandardError, "Could not detect structured data. #{e}"
    end
  end


  def expand_entity_property(predicate:)
    sparql =  SparqlLoader.load('expand_entity_property', [
      'URI_PLACEHOLDER', self.entity_uri,
      'schema:name', "<#{predicate}>"
    ])
    # puts "SPARQL: #{sparql}"
    @graph = construct_turtle(sparql)
  end

  def load_claims
    sparql =  SparqlLoader.load('load_rdfstar_claims_graph', [
      'entity_uri_placeholder', self.entity_uri
    ])
    # puts "SPARQL: #{sparql}"
    @graph = construct_turtle(sparql)
  end

  def load_derived_statements
    sparql =  SparqlLoader.load('load_rdfstar_inverse_graph', [
      'entity_uri_placeholder', self.entity_uri
    ])
    # puts "SPARQL: #{sparql}"
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


  def load_graph(language = "en")
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

  def load_graph_without_triple_terms(language = "en")
    sparql =  SparqlLoader.load('load_rdf_graph_without_triple_terms', [
                  'entity_uri_placeholder', self.entity_uri,
                  'locale_placeholder' , language
                ])
   
    response = @@artsdata_client.execute_construct_sparql(sparql)

    @graph = if response[:code] == 200
      graph = RDF::Graph.new 
      graph.from_jsonld(response[:message].to_json)
    else
      RDF::Graph.new
    end
  end


  def replace_blank_nodes
    @graph = SPARQL.execute(SparqlLoader.load('replace_blank_nodes'), @graph, update: true)
  end

  def replace_blank_subject_nodes
    # puts "before: #{pp @graph.dump(:turtle)}"
    @graph = SPARQL.execute(SparqlLoader.load('replace_blank_subject_nodes'), @graph, update: true)
    # puts "after replace blank nodes: #{pp @graph.dump(:turtle)}"
  end

  def entity_jsonld
    if @graph.count > 0
      JSON.parse(@graph.dump(:jsonld)).first
    else
      [] # return empty array
    end
  end

end