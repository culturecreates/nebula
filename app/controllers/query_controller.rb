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
end
