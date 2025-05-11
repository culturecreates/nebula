class ResourceController < ApplicationController

  # Do content negotiation
  # Treat entire URI not only /resource/K...
  # Should process http://kg.artsdata.ca/databus and /shacl and /ontology
  # Use request header 'Accept'
  # TODO: Try to replace this with rack/content_netgotiation
  def show
    uri = "http://kg.artsdata.ca" + request.path # allow testing on domains like localhost
    format =  if request.headers['Accept']&.include?('application/rdf+xml')
                :rdf
              elsif request.headers['Accept']&.include?('application/ld+json')
                :jsonld 
              elsif request.headers['Accept']&.include?('text/turtle')
                :ttl
              else
                :html
              end
    redirect_to entity_url(uri: uri, format: format, protocol: 'https'), status: 303
  end
end