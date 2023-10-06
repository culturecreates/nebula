class EntityController < ApplicationController
  # Show an entity's asserted statements
  # /entity?uri=
  def show
    uri = params[:uri] ||= "K1-3"
    uri = "http://kg.artsdata.ca/resource/#{uri}"if uri.starts_with?("K")

    if !uri.start_with?("http")
      flash.alert = "Not an Artsdata ID or URI."
      redirect_to root_path
    end
   
    @entity = Entity.new(entity_uri: uri)
    @entity.load_graph
    #@entity.load_shacl_into_graph("shacl_artsdata.ttl") 
  end

  # show all statements from all sources
  # including unclaimed statements from other sources
  # /entity/expand?subject=[canonical URI]&predicate=[canonical URI]&predicate_hash=[predicate.hash]
  def expand
    uri = params[:subject]
    predicate = params[:predicate]
    @predicate_hash = params[:predicate_hash]
    @entity = Entity.new(entity_uri: uri)
    @entity.expand_entity_property(predicate: predicate)
  end
 
end
