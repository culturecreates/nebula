class EntityController < ApplicationController
  # Show an entity's asserted statements
  # /entity?uri=
  # /entity.ttl?uri=
  # /entity.jsonld?uri=
  # /entity.rdf?uri=
  def show
    uri = params[:uri] 
    uri = "http://kg.artsdata.ca/resource/#{uri}" if !uri.starts_with?(/http:|https:|urn:/)
    uri.gsub!(' ', '+')
    @entity = Entity.new(entity_uri: uri)
    
    respond_to do |format|
      format.jsonld {
        # see https://json-ld.github.io/json-ld.org/spec/latest/json-ld-api-best-practices/
        puts "rendering jsonld..."
        nebula_context_url = "#{request.scheme}://#{request.host_with_port}/context.jsonld"
        @entity.load_graph_without_triple_terms
        expanded_jsonld = JSON::LD::API::fromRdf(@entity.graph)
        frame = JSON.parse %({"@type": {}})
        framed_jsonld = JSON::LD::API.frame(expanded_jsonld, frame)
        compacted_jsonld = JSON::LD::API.compact(framed_jsonld, JSON::LD::Context.new().parse(nebula_context_url))
        compacted_jsonld['@graph'] = compacted_jsonld['@graph'].first if compacted_jsonld['@graph'].is_a? Array
        if compacted_jsonld['@graph'].is_a? Hash
          compacted_jsonld = {'@context' => nebula_context_url}.merge(compacted_jsonld['@graph'])
        else
          compacted_jsonld['@context']= nebula_context_url
        end
        render json: compacted_jsonld, content_type: 'application/ld+json'
      }
      format.jsonlds {
        puts "rendering expanded jsonld-star..."
        @entity.load_graph
        render json: JSON::LD::API::fromRdf(@entity.graph), content_type: 'application/ld+json'
      }
      format.ttl { 
        puts "rendering turtle..."
        @entity.load_graph_without_triple_terms
        render plain: @entity.graph.dump(:turtle, standard_prefixes: true), content_type: 'text/turtle'
      }
      format.ttls { 
        puts "rendering turtle..."
        @entity.load_graph
        render plain: @entity.graph.dump(:turtle, standard_prefixes: true), content_type: 'text/turtle'
      }
      format.rdf { 
        puts "rendering rdf..."
        @entity.load_graph_without_triple_terms
        render xml: @entity.graph.dump(:rdfxml, validate: false, standard_prefixes: true), content_type: 'application/rdf+xml'
      }
      # render in entity view
      format.all { 
        @entity.load_graph
        @entity.replace_blank_nodes # first level
        @entity.replace_blank_nodes # second level
        @entity.replace_blank_subject_nodes
        # pp @entity.graph.dump(:turtle)
        # TODO: add SHACL validation
        # @entity.load_shacl_into_graph("shacl_artsdata.ttl") if @entity.graph.count > 0
       }
    end
  end

  # show all statements from all sources
  # including claimed statements from other sources that are not endorsed (quoted only)
  # /entity/expand?subject=[canonical URI]&predicate=[canonical URI]&predicate_hash=[predicate.hash]
  def expand
    uri = params[:subject]
    @predicate = RDF::URI(params[:predicate])
    @predicate_hash = params[:predicate_hash]
    @entity = Entity.new(entity_uri: uri)
    @entity.expand_entity_property(predicate: @predicate)
  end

  # unsupported claims (quoted only)
  # /entity/unsupported_claims?uri=[canonical URI]
  def unsupported_claims
    uri = params[:uri]
    @entity = Entity.new(entity_uri: uri)
    @entity.load_claims
    @entity.replace_blank_nodes # first level
  end

  # derived statements (inverse path)
  # /entity/derived_statements?uri=[canonical URI]
  def derived_statements
    uri = params[:uri]
    @entity = Entity.new(entity_uri: uri)
    @entity.load_derived_statements
   #  @entity.replace_blank_nodes # first level
  end
 
end
