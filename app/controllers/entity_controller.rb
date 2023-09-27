class EntityController < ApplicationController
  # Show an entity /entity?uri=
  def show
    uri = params[:uri] ||= "K1-3"
    uri = "http://kg.artsdata.ca/resource/#{uri}"if uri.starts_with?("K")

    @entity = Entity.new(entity_uri: uri)
    @entity.load_graph
    #@entity.load_shacl_into_graph("shacl_artsdata.ttl") 
  end
end
