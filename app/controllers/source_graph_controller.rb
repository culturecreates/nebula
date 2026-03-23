class SourceGraphController < ApplicationController

  # Show info about the source graph of an entity URI
  def show 
    entity_uri = params[:uri]
    @entity = Entity.new(entity_uri: entity_uri)
    source_info = @entity.load_source_graph_info
    @sources = source_info 
   
  end
end
