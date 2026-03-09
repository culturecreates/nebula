class HistoryController < ApplicationController

  def show
    @uri = params[:uri] + (if params[:uri].ends_with?("_dataset") then "" else "_dataset" end)
    redirect_to entity_path(uri: @uri)
 
    # TODO: implement history page
    # @entity = Entity.new(entity_uri: @uri)
    # @history = @entity.history
    # if @history.nil?
    #   flash[:alert] = "Entity has no history"
    #   redirect_to root_path
    #   return
    # end
  end
end
