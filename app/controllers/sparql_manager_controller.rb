class SparqlManagerController < ApplicationController
  before_action :check_sparql_manager_access # ensure user has permissions

  def index
  
    query =  SparqlLoader.load("sparql_controller/list_sparqls")
    @sparqls = ArtsdataApi::SparqlService.client.query(query).limit(1000) # TODO: fix limit
  end

  def new
    @sparql = SparqlManager.new
  end

  # POST /sparql
  def create

    @sparql = SparqlManager.new(artifact_params, session[:handle])
    
    if @sparql.save
      flash.notice = "Created SPARQL '#{@sparql.name}'."
      redirect_to sparql_manager_index_path
    else
      render 'new'
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def artifact_params
    params.permit(:name, :description, :type)
  end

  def check_sparql_manager_access
    ensure_access("sparql_manager")
  end

end
