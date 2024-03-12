class EntityController < ApplicationController
  # Show an entity's asserted statements
  # /entity?uri=
  def show
    uri = params[:uri] 
    uri = "http://kg.artsdata.ca/resource/#{uri}" if !uri.starts_with?(/http:|https:|urn:/)

   
    @entity = Entity.new(entity_uri: uri)
    @entity.load_graph 
    @entity.replace_blank_nodes # first level
    @entity.replace_blank_nodes # second level
    @entity.replace_blank_subject_nodes
    # pp @entity.graph.dump(:turtle)
    # TODO: add SHACL validation
    # @entity.load_shacl_into_graph("shacl_artsdata.ttl") if @entity.graph.count > 0
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
