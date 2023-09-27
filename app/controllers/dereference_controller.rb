class DereferenceController < ApplicationController

  def card
    @frame_id = params[:frame_id]
    @uri = params[:uri] ||= "http://kg.artsdata.ca/resource/K1-3"
    @label = @uri
  end
end
