class DereferenceController < ApplicationController

  def card
    @frame_id = params[:frame_id]
    @uri = params[:uri] ||= "http://kg.artsdata.ca/resource/K1-3"
    @entity = Entity.new(entity_uri: @uri)
    @entity.dereference
  end
end
