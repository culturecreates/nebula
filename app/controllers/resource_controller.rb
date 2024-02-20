class ResourceController < ApplicationController
  def show
    artsdata_id = params[:id]

    # TODO: this should not be necessary, but it is for now. 
    # Try to replace with rack/content_netgotiation
    request.format = :rdf if request.headers['Accept'].include?('application/rdf+xml')
    request.format = :jsonld if request.headers['Accept'].include?('application/ld+json')
    request.format = :ttl if request.headers['Accept'].include?('text/turtle')
    
    respond_to do |format|
      puts "request.headers['Accept']: #{request.headers['Accept']}"
      format.html { redirect_to entity_path(uri: artsdata_id) }

      puts "checking other formats."
      @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/#{artsdata_id}")
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
      format.all { redirect_to entity_path(uri: artsdata_id) }
    end
  end
end