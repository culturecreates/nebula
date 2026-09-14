class PagesController < ApplicationController
  def vocabularies
  end

  def events
  end

  def data_dumps
    service = ArtsdataMcpService.new
    @data_dumps = service.dumps
    @data_dumps_error = service.error.present?
  end
end