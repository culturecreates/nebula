class EntityController < ApplicationController
  # Show an entity /entity?uri=
  def show
    adid = params[:adid] ||= "K1-3"
    uri = "http://kg.artsdata.ca/resource/#{adid}" 
    @entity = Entity.new(entity_uri: uri)
    @entity.load_graph
    #@entity.load_shacl_into_graph("shacl_artsdata.ttl") 
  end
end
