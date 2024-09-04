class ArtifactController < ApplicationController

  def index
    databus_account = params[:databus_account] || "CAPACOA"
    redirect_to query_show_path(sparql: "artifact_controller/list_artifacts", databus_account: databus_account, title: "#{databus_account} Artifacts")
  end

  def new
    @artifact = Artifact.new
  end

  # POST /artifact
  def create

    @artifact = Artifact.new(artifact_params)
    
    if @artifact.save
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
