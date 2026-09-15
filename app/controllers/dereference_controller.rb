class DereferenceController < ApplicationController
  rescue_from StandardError, with: :failed_dereference
  before_action :user_signed_in!, only: [:external] # ensure user has permissions
  # This action is only ever loaded via <turbo-frame src="..."> from
  # within this app's own pages (entity/statement/annotation views,
  # reconcile results, mint preview) - never embedded on third-party
  # sites. Turbo still fetches and discards the full document around the
  # matched frame, so a lean layout (no nav bar, no meta helpers) cuts
  # real render time and payload on what is this app's hottest endpoint,
  # since a single busy entity page can fan out into many card requests
  # (one per triple whose object is a URI).
  layout "embed", only: [:card]

  # /dereference/card?uri=
  def card
    @frame_id = params[:frame_id]
    @uri = params[:uri]
    # Card data (name, dates, address) doesn't need per-request freshness,
    # and the same popular URIs (venues, performers, organizations) get
    # dereferenced repeatedly across many different pages - cache the
    # loaded entity to skip the SPARQL round-trip on repeat hits.
    @entity = Rails.cache.fetch(["dereference_card", @uri], expires_in: 10.minutes) do
      entity = Entity.new(entity_uri: @uri)
      entity.load_card
      entity
    end
  end

  # /dereference/external[.jsonld]?uri=
  # This can be a resource that is a graph of entities on the web
  def external
    @shacl_url = params[:shacl] || "app/services/shacls/shacl_artsdata_external.ttl"
    @post_sparql = params[:post_sparql] # example:"https://raw.githubusercontent.com/culturecreates/artsdata-score/main/sparql/score.sparql"
    @max_entities_per_page = 40
    @entity = Entity.new(entity_uri:params[:uri])
    @entity.dereference
    
    shacl = SHACL.open(@shacl_url)
    @report = shacl.execute(@entity.graph)
    @entity.load_graph_into_graph(@report)
    # SPARQL to run after dereferencing (post dereferce)
    if @post_sparql
      sparql_url = @post_sparql
      @entity.construct_sparql(sparql_url)
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
