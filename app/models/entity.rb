
class Entity
  attr_accessor :entity_uri, :graph, :start_date, :card, :graph_uri
  @@artsdata_client = ArtsdataApi::V2::Client.new(
        graph_repository: Rails.application.credentials.graph_repository, 
        api_endpoint: Rails.application.credentials.graph_api_endpoint)

  def initialize(**h) 
    @entity_uri = h[:entity_uri]
    @graph = h[:graph]
    @card = {}
  end

  # Try to get a label of name property
  # Return RDF::Literal that may contain language
  def label
    solution = @graph.query([RDF::URI(@entity_uri), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), nil])
    return  solution.first.object if solution.count > 0
  
    solution = @graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/name"), nil])
    solution.first.object if solution.count > 0
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
  

  # Try to get a top level type of the entity
  def top_level_type
    # The card sparql adds inferred types to additionalType
    solution =  @graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/additionalType"), :nil])
    # try to return top level type using inferred types
    top_type = nil
    solution.each do |s|
      if ["http://schema.org/Event",
          "http://schema.org/EventSeries",
          "http://schema.org/Place",
          "http://schema.org/Person",
          "http://schema.org/Organization"].include?(s.object.value)
          top_type = s.object
        break
      end
    end

    if top_type
      return top_type
    elsif solution.count > 0
      return solution.first.object
    else
      return RDF.URI("http://schema.org/Thing")
    end
  end

  def type
    solution =  @graph.query([RDF::URI(@entity_uri), RDF.type, :nil])
    type = solution&.first&.object
    solution.each do |s|
      if ["http://schema.org/Event",
          "http://schema.org/EventSeries",
          "http://schema.org/Place",
          "http://schema.org/Person",
          "http://schema.org/Organization"].include?(s.object.value)
        type = s.object
        break
      end
    end

    if type
      return type
    else
      return RDF::URI("http://schema.org/Thing")
    end
  end

  def method_missing(m,*args,&block)
    if m.to_s == 'main_image'
      ""
    else
      "missing"
    end 
  end

  def load_shacl_into_graph(shacl_name) 
    shacl = "app/services/shacls/#{shacl_name}"
    @graph << RDF::Graph.load(shacl)
  end

  def load_graph_into_graph(graph_part)
    @graph << graph_part
  end

  # Apply the contruct sparql (url) to the local graph inorder to add new triples
  def construct_sparql(sparql_url)
    sparql = SparqlLoader.load_url(sparql_url)
    puts "SPARQL contruct: #{sparql}"
    @graph = SPARQL.execute(sparql, @graph, update: true)
  end

  # Cards are short summaries of entities loaded from the triple store
  def load_card
    sparql =  SparqlLoader.load('load_card', [
      'URI_PLACEHOLDER', self.entity_uri
    ])
    @graph = construct_turtle(sparql)

    if @graph.count < 2 # then try Wikidata
      if self.entity_uri =~ /wikidata/
        sparql =  SparqlLoader.load('load_card_wikidata', [
          'URI_PLACEHOLDER', self.entity_uri
        ])
        @graph = construct_turtle(sparql,"wikidata")
      end
    end

    @card[:start_date] = graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/startDate"), nil])&.first&.object&.value
    @card[:end_date] = graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/endDate"), nil])&.first&.object&.value
    @card[:location_name] = graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/location"), nil])&.first&.object&.value
    @card[:postal_code] = graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/postalCode"), nil])&.first&.object&.value
    @card[:locality] = graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/addressLocality"), nil])&.first&.object&.value
    @card[:street_address] = graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/streetAddress"), nil])&.first&.object&.value
    @card[:disambiguating_description] = graph.query([RDF::URI(@entity_uri), RDF::URI("http://schema.org/disambiguatingDescription"), nil])&.first&.object&.value
    @card[:name_language] = graph.query([RDF::URI(@entity_uri), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), nil])&.first&.object&.language

    # calculate day span when startDate and endDate are present
    @card[:day_span] =  if  @card[:start_date] && @card[:end_date]
                          days = 1 + ( (Time.parse(@card[:end_date]) - Time.parse(@card[:start_date])) / (60 * 60 * 24)).to_i 
                          if days > 1
                            "spans #{days} days"
                          else
                            "single day"
                          end
                        end 
  end

  # load rdf from external URL
  def dereference
    @graph = RDF::Graph.new 
    # first try proper content negotiation
    begin
      options = { rdfstar: true, headers: {"User-Agent" => "artsdata-crawler" } }
      @graph = RDF::Graph.load(self.entity_uri, **options)
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

  def construct_turtle(sparql, sparql_endpoint = nil)
    if sparql_endpoint == "wikidata"
      @@wikidata_client ||= SPARQL::Client.new("https://query.wikidata.org/sparql")
      solutions = @@wikidata_client.query(sparql)
      graph = RDF::Graph.new
      solutions.each do |solution|
        graph << RDF::Statement.new(solution.subject, solution.predicate, solution.object)
      end
      graph
    else
      response = @@artsdata_client.execute_construct_turtle_star_sparql(sparql)
      if response[:code] == 200
        RDF::Graph.new do |graph|
          RDF::Turtle::Reader.new(response[:message], rdfstar: true) {|reader| graph << reader}
        end
      else
        RDF::Graph.new
      end
    end
   
    
  end


  def load_graph(language = "en")
    sparql =  SparqlLoader.load('load_rdfstar_graph', [
                  'entity_uri_placeholder', self.entity_uri,
                  'locale_placeholder' , language
                ])
    @graph = construct_turtle(sparql)
  end

  def graph_uri
    return @graph_uri if @graph_uri.present?
    
    # check if in graph already
    @graph_uri = @graph.query([RDF::URI(self.entity_uri), RDF::Vocab::SCHEMA.isPartOf, nil]).objects&.first&.to_s
    return @graph_uri if @graph_uri.present?

    # query artsdata for the graph uri
    sparql = "select ?g where { graph ?g { <#{self.entity_uri}> a ?o } }"
    response = @@artsdata_client.execute_sparql(sparql)
    @graph_uri =  if response[:code] == 200
                    response[:message].first["g"]["value"]
                  else
                    nil
                  end
    @graph_uri
  end

  def load_graph_without_triple_terms(language = "en")
    sparql =  SparqlLoader.load('load_rdf_graph_without_triple_terms', [
                  'entity_uri_placeholder', self.entity_uri,
                  'locale_placeholder' , language
                ])
   
    response = @@artsdata_client.execute_construct_turtle_sparql(sparql)

    @graph =  if response[:code] == 200
                graph = RDF::Graph.new
                RDF::Turtle::Reader.new(response[:message]) do |reader|
                  reader.each_statement do |statement|
                    graph << statement
                  end
                end
                graph
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