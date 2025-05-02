class ArtifactController < ApplicationController
  before_action :authenticate_databus_user! # ensure user has permissions

  def index
    @databus_account = session[:accounts].first
    sparql_file =  "artifact_controller/list_artifacts"

    # Placeholders in SPARQL query
    @query =  SparqlLoader.load(sparql_file, [ "DATABUS_ACCOUNT", @databus_account.downcase])
    @artifacts = helpers.artsdata_sparql_client.query(@query).limit(1000) # TODO: fix limit
  end

  def show
    artifact_uri = params[:artifactUri]
    @artifact = Artifact.new
    @artifact.uri = artifact_uri
  end

  # POST /artifact/push_latest
  def push_latest
    @artifact_uri = params[:artifactUri]
    databus_service = DatabusService.new(@artifact_uri, helpers.user_uri)
    if databus_service.push_lastest_artifact(@artifact_uri) 
      flash.notice = "Pushed latest artifact '#{databus_service.latest_version}' to Artsdata."
    else
      flash.alert = "Error pushing '#{databus_service.latest_version}' : #{databus_service.errors}."
    end
    redirect_back(fallback_location: root_path)
  end

  def new
    @artifact = Artifact.new
  end

  # POST /artifact
  def create

    @artifact = Artifact.new(artifact_params, session[:handle])
    if @artifact.save
      flash.notice = "Created artifact '#{@artifact.name}'. You may now create versions of the artifact."
      redirect_to artifact_index_path
    else
      render 'new'
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def artifact_params
    params.permit(:name, :description, :type, :sheet_url, :webpage_url, :link_identifier)
  end
end
