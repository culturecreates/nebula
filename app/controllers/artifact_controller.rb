class ArtifactController < ApplicationController
  before_action :authenticate_databus_user! # ensure user has permissions

  def index
    @databus_account = session[:accounts].first
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
      flash.notice = "Created artifact '#{@artifact.name}'. You may now load the artifact as a dataset into Artsdata."
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
