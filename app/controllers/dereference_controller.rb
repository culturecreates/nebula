class DereferenceController < ApplicationController

  # /dereference/card?uri=
  def card
    @frame_id = params[:frame_id]
    @uri = params[:uri] ||= "http://kg.artsdata.ca/resource/K1-3"
    @entity = Entity.new(entity_uri: @uri)
    @entity.load_card
  end

  # /dereference/external?uri=
  def external
    @entity = Entity.new(entity_uri: @uri)
    @entity.dereference
    render "entity/show"
  end
end
