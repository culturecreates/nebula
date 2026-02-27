class ValidateController < ApplicationController

  def show
    uri = params[:uri]
    class_to_mint = params[:classToMint]
    mint_endpoint = Rails.application.config.artsdata_mint_endpoint

    # Call Artsdata API to get the RDF graph for the entity
    url = "#{mint_endpoint}/preview?uri=#{CGI.escape(uri)}&classToMint=#{class_to_mint}"
    
    begin
      response = HTTParty.get(url)
      raise "Mint API #{response.code}: #{response.message}" if response['status'] != 'success'
    rescue => e
      flash.now.alert = "Error calling Mint Preview API: #{e.message.truncate(100)}"
    end
   
    body = JSON.parse(response.body)
    @entity = Entity.new(entity_uri: "http://new.uri")
    if body['status'] == "success"
      @report = body['message']
      jsonld_data = body['data']
      @entity.graph = RDF::Graph.new do |graph|
        RDF::Reader.for(:jsonld).new(jsonld_data.to_json, rdfstar: true)  {|reader| graph << reader}
      end
    else
      @entity.graph = RDF::Graph.new
      flash.now.alert = "Data Error: #{body['message'].truncate(300)}"
    end
  end

end
