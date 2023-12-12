class QueryController < ApplicationController

  def show
    @sparql_file = params[:sparql] ||= "custom/scenepro-orgs"
    sparql = SPARQL::Client.new("http://db.artsdata.ca/repositories/artsdata")
    query =  SparqlLoader.load(@sparql_file)
    @solutions = sparql.query(query).limit(1000)
  end
end
