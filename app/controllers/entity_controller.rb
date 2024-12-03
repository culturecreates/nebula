class EntityController < ApplicationController
  before_action :authenticate_user!, only: [:expand] 

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
        nebula_context_url = "#{request.scheme}://#{request.host_with_port}/context.jsonld"
        @entity.load_graph_without_triple_terms
        jsonld = JSON::LD::API::fromRdf(@entity.graph)
        if @entity.type && @entity.type != "http://schema.org/Thing"
          frame = JSON.parse %({"@type": "#{@entity.type.value}",  "@embed": "@once"}) # Default is @once
          jsonld = JSON::LD::API.frame(jsonld, frame)
        end
        compacted_jsonld = JSON::LD::API.compact(jsonld, JSON::LD::Context.new().parse(nebula_context_url))
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
        puts "rendering turtle-star..."
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
        @show_expand_button = true if user_signed_in?
        # TODO: add SHACL validation if artsdata entity
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
  end

  # derived statements (inverse path)
  # /entity/derived_statements?uri=[canonical URI]
  def derived_statements
    uri = params[:uri]
    @entity = Entity.new(entity_uri: uri)
    @entity.load_derived_statements
  end
 
end
