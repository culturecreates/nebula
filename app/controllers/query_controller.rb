class QueryController < ApplicationController

  def show
    sparql = SPARQL::Client.new("http://db.artsdata.ca/repositories/artsdata")
    query =  SparqlLoader.load('custom')
    @solutions = sparql.query(query)
  end
end
