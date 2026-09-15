class PagesController < ApplicationController
  def home; end

  def doc
    template = "#{I18n.locale.to_s}/#{params[:path]}"
    render template: template
  end
  
  def vocabularies
  end

  def events
  end

  def data_dumps
    service = ArtsdataMcpService.new
    @data_dumps = service.dumps
    @data_dumps_error = service.error.present?
    @mcp_endpoint = Rails.application.config.artsdata_mcp_endpoint
  end
end