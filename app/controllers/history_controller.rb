class HistoryController < ApplicationController

  def show
    @uri = params[:uri]
    @entity = Entity.new(entity_uri: @uri)
    @history = @entity.history
    if @history.nil?
      flash[:alert] = "Entity has no history"
      redirect_to root_path
      return
    end
  end
end
