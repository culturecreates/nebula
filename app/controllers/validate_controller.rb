class ValidateController < ApplicationController

  def show
    uri = params[:uri] 
    @entity = Entity.new(entity_uri: uri)
    @entity.load_graph
    begin
      shacl = SHACL.open("app/services/shacls/mint_person.ttl")
      @report = shacl.execute(@entity.graph)
      @entity.load_graph_into_graph(@report)
    rescue => exception
      @entity =  "Error: #{exception}"
    end
   
  end
end
