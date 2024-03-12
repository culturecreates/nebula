class ResourceController < ApplicationController

  # Do content negotiation
  # Treat entire URI not only /resource/K...
  # Should process http://kg.artsdata.ca/databus and /shacl and /ontology
  # Use request header 'Accept' or add .ttl, .jsonld, .rdf to the URI to get the desired format
  # TODO: Try to replace this with rack/content_netgotiation
  def show
    uri = "http://kg.artsdata.ca" + request.path.gsub(/.jsonld|.ttl|.rdf/, "") 

    puts "request.path #{request.path}"
    
    request.format = :rdf if request.headers['Accept'].include?('application/rdf+xml')
    request.format = :jsonld if request.headers['Accept'].include?('application/ld+json')
    request.format = :ttl if request.headers['Accept'].include?('text/turtle')
    
    respond_to do |format|
      puts "request.headers['Accept']: #{request.headers['Accept']}"
      format.html { redirect_to entity_path(uri: uri), status: 303 }

      puts "checking other formats."
      @entity = Entity.new(entity_uri: uri)
      graph = @entity.load_graph
      puts "graph.count: #{graph.count}"
      format.jsonld {
        puts "rendering jsonld..."
        render json: graph.dump(:jsonld, standard_prefixes: true), content_type: 'application/ld+json'
      }
      format.ttl { 
        puts "rendering turtle..."
        render plain: graph.dump(:turtle, standard_prefixes: true), content_type: 'text/turtle'
      }
      format.rdf { 
        puts "rendering rdf..."
        render xml: graph.dump(:rdf, standard_prefixes: true), content_type: 'application/rdf+xml'
      }
      format.all { redirect_to entity_path(uri: uri) }
    end
  end
end