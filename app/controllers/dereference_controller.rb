class DereferenceController < ApplicationController
  rescue_from StandardError, with: :failed_dereference

  # /dereference/card?uri=
  def card
    @frame_id = params[:frame_id]
    @uri = params[:uri] 
    @entity = Entity.new(entity_uri: @uri)
    @entity.load_card
  end

  # /dereference/external?uri=
  # This can be a resource that is a graph of entities on the web
  def external
    @max_entities_per_page = 40
    @entity = Entity.new(entity_uri:params[:uri])
    @entity.dereference
    @entity.replace_blank_subject_nodes
    @entity.replace_blank_nodes # first level
    @entity.replace_blank_nodes # second level
    @entity.replace_blank_nodes # third level

    
    shacl = SHACL.open( "app/services/shacls/shacl_artsdata_external.ttl")
    @report = shacl.execute(@entity.graph)
    @entity.load_graph_into_graph(@report)
  end

  private
  def failed_dereference(exception)
    flash[:alert] = exception
    redirect_back(fallback_location: root_path)
  end
end
