class QueryController < ApplicationController

  def show
    sparql_file = params[:sparql] 
    sub_sparql = params[:sub_sparql] ||= "list_entities"
    @title =  params[:title] ||=  params[:sparql]

    # create list for SPARQL template
    substitute_list = []
    ["PLACEHOLDER", params[:placeholder]].each { |item| substitute_list << item } if params[:placeholder] 
    ["API", params[:api]].each { |item| substitute_list << item } if params[:api]
    ["SUB_SPARQL", sub_sparql].each { |item| substitute_list << item }

    sparql = SPARQL::Client.new("http://db.artsdata.ca/repositories/artsdata")
    query =  SparqlLoader.load(sparql_file, substitute_list)
    @solutions = sparql.query(query).limit(1000)
  end

  # pass a chain of SPARQL queries to the SPARQL endpoint
  # GET "query/show_chain"
  def show_chain
    construct_files = params[:constructs].split(",")
    puts construct_files
    query_file = params[:query]
    @title =  params[:title] ||=  query

    graph = RDF::Graph.new
    sparql_client = SPARQL::Client.new("http://db.artsdata.ca/repositories/artsdata")
    construct_files.each do |sparql_file|
      query =  SparqlLoader.load(sparql_file)
      graph << sparql_client.query(query)
      puts "query #{sparql_file} added #{graph.count} triples"
    end
    # apply final query to local graph
    query =  SparqlLoader.load(query_file)
    @solutions =  SPARQL.execute(query,graph)

    render :show
  end
end
