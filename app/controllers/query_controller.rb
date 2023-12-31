class QueryController < ApplicationController

  def show
    @sparql_file = params[:sparql] ||= "custom/scenepro-orgs"
    substitute_list = if params[:placeholder] 
                        ["PLACEHOLDER", params[:placeholder]]
                      else 
                        []
                      end
    ["API", params[:api]].each { |item| substitute_list << item } if params[:api]

    sparql = SPARQL::Client.new("http://db.artsdata.ca/repositories/artsdata")
    query =  SparqlLoader.load(@sparql_file, substitute_list)
    @solutions = sparql.query(query).limit(1000)
  end
end
