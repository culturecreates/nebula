class ValidateController < ApplicationController

  def show
    uri = params[:uri]
    class_to_mint = params[:classToMint]
    mint_endpoint = Rails.application.config.artsdata_mint_endpoint

    # Call Artsdata API to get the RDF graph for the entity
    url = "#{mint_endpoint}/preview?uri=#{CGI.escape(uri)}&classToMint=#{class_to_mint}"
    
    @entity = Entity.new(entity_uri: "http://new.uri")
    @entity.graph = RDF::Graph.new

    # Always render the turbo-frame (even on failure) so the loading spinner
    # in the page is replaced by the error message.
    begin
      response = HTTParty.get(url, timeout: 15)
      body = JSON.parse(response.body)
      raise "Mint API #{response.code}: #{response.message}" unless body.is_a?(Hash)

      if body['status'] == "success"
        @report = body['message']
        @entity.graph = RDF::Graph.new do |graph|
          RDF::Reader.for(:jsonld).new(body['data'].to_json, rdfstar: true) { |reader| graph << reader }
        end
      else
        flash.now.alert = "Data Error: #{body['message'].to_s.truncate(300)}"
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
      flash.now.alert = "Error calling Mint Preview API: the request timed out"
    rescue => e
      flash.now.alert = "Error calling Mint Preview API: #{e.message.truncate(100)}"
    end
  end

end
