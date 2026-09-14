class PagesController < ApplicationController
  def vocabularies
  end

  def events
  end

  def data_dumps
    @data_dumps = ArtsdataMcpService.new.dumps
  end
end