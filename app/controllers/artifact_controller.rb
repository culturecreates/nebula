class ArtifactController < ApplicationController

  def index
    @artifacts = Artifact.all
  end

  def new
    @artifact = Artifact.new
  end

  def create
    @artifact = Artifact.new(artifact_params)
    if @artifact.save
      redirect_to @artifact
    else
      render 'new'
    end
  end
end
