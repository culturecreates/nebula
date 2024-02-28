class ResourceController < ApplicationController
  def show
   # treat entire URI not only http://kg.artsdata.ca/resource/...
   # should process http://kg.artsdata.ca/databus/ and  http://kg.artsdata.ca/shacl/ as well
    uri = "http://kg.artsdata.ca" + request.path 

    puts "request.path #{request.path}"
    # TODO: Try to replace with rack/content_netgotiation
    request.format = :rdf if request.headers['Accept'].include?('application/rdf+xml')
    request.format = :jsonld if request.headers['Accept'].include?('application/ld+json')
    request.format = :ttl if request.headers['Accept'].include?('text/turtle')
    
    respond_to do |format|
      puts "request.headers['Accept']: #{request.headers['Accept']}"
      format.html { redirect_to entity_path(uri: uri) }

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