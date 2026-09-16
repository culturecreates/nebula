class SourceGraphController < ApplicationController

  # Show info about the source graph of an entity URI
  def show
    entity_uri = params[:uri]
    @entity = Entity.new(entity_uri: entity_uri)
    @sources = Rails.cache.fetch(["source_graph_show", entity_uri, I18n.locale], expires_in: 15.minutes) do
      @entity.load_source_graph_info
    end
  end
end
