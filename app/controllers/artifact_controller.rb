class ArtifactController < ApplicationController
  before_action :authenticate_user! # ensure user is logged in

  def index
    @databus_account = params[:databus_account] || "capacoa"
    # redirect_to query_show_path(sparql: "artifact_controller/list_artifacts", databus_account: databus_account, title: "#{databus_account} Artifacts")
   
    sparql_file =  "artifact_controller/list_artifacts"

    # Placeholders in SPARQL query
    query =  SparqlLoader.load(sparql_file, [ "DATABUS_ACCOUNT", @databus_account.downcase])
    @artifacts = helpers.artsdata_sparql_client.query(query).limit(1000) # TODO: fix limit
   
      
  end

  def new
    @artifact = Artifact.new
  end

  # POST /artifact
  def create

    @artifact = Artifact.new(artifact_params, session[:handle])
    
    if @artifact.save
      flash.notice = "Created artifact '#{@artifact.name}'. Load action #{@artifact.artifact_create_action_uri}"
      redirect_to artifact_index_path
    else
      render 'new'
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def artifact_params
    params.permit(:name, :description, :type, :sheet_url)
  end
end
