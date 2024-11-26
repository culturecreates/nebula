class DereferenceController < ApplicationController
  rescue_from StandardError, with: :failed_dereference
  before_action :authenticate_user!, only: [:external] # ensure user has permissions

  # /dereference/card?uri=
  def card
    @frame_id = params[:frame_id]
    @uri = params[:uri] 
    @entity = Entity.new(entity_uri: @uri)
    @entity.load_card
  end

  # /dereference/external[.jsonld]?uri=
  # This can be a resource that is a graph of entities on the web
  def external
    @shacl_url = params[:shacl] || "app/services/shacls/shacl_artsdata_external.ttl"
    @post_sparql = params[:post_sparql] # example:"https://raw.githubusercontent.com/culturecreates/artsdata-score/main/sparql/score.sparql"
    @max_entities_per_page = 40
    @entity = Entity.new(entity_uri:params[:uri])
    @entity.dereference
    @entity.replace_blank_subject_nodes
    @entity.replace_blank_nodes # first level
    @entity.replace_blank_nodes # second level
    @entity.replace_blank_nodes # third level
    
    shacl = SHACL.open(@shacl_url)
    @report = shacl.execute(@entity.graph)
    @entity.load_graph_into_graph(@report)

    # SPARQL to run after dereferencing (post dereferce)
    if @post_sparql
      sparql_url = @post_sparql
      @entity.construct_sparql(sparql_url)
      @entity.replace_blank_nodes # first level
    end
    respond_to do |format|
      format.jsonld {
        puts "rendering jsonld..."
        render json: JSON::LD::API::fromRdf(@entity.graph), content_type: 'application/ld+json'
      }
      format.all { }
    end

  end

  private
  def failed_dereference(exception)
     # Get the format of the initial request
    request_format = request.format.symbol
    if request_format == :jsonld
      render json: { error: exception }, status: :internal_server_error
      return
    end
    flash[:alert] = exception
    redirect_back(fallback_location: root_path)
  end
end
