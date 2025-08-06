class EntityController < ApplicationController
  before_action :user_signed_in?, only: [:expand] 
  before_action :check_delete_entity_access, only: [:destroy] # ensure user has permissions to delete entity

  # Show an entity's asserted statements
  # /entity?uri=  --> HTML
  # /entity.ttl?uri=  --> Turtle
  # /entity.ttls?uri=  --> Turtle Star
  # /entity.jsonld?uri=&frameTemplate= --> JSON-LD (special template for schema_org)
  # /entity.jsonld?uri=  --> JSON-LD (default frame)
  # /entity.rdf?uri=  --> RDF/XML
  # /entity.jsonlds?uri=  --> JSON-LD Star
  # /entity.ttl?uri=  --> Turtle
  # /entity.ttls?uri=  --> Turtle Star
  # /entity.jsonlds?uri=  --> JSON-LD Star
  # /entity.rdf?uri=  --> RDF/XML
  def show
    uri = params[:uri] 
    uri = "http://kg.artsdata.ca/resource/#{uri}" if !uri.starts_with?(/http:|https:|urn:/)
    uri.gsub!(' ', '+')
    @entity = Entity.new(entity_uri: uri)
    
    respond_to do |format|
      format.jsonld {
        # see https://json-ld.github.io/json-ld.org/spec/latest/json-ld-api-best-practices/
        @entity.load_graph_without_triple_terms
        frame_template = params[:frameTemplate]
        frame, context, jsonld = shape(@entity, frame_template)
        if frame.present?
          framed_jsonld = JSON::LD::API.frame(jsonld, frame)
          @compacted_jsonld = JSON::LD::API.compact(framed_jsonld, context, expanded: false) # Or expand: JSON::LD::Context.new().parse(nebula_context_url)
       
          if frame_template == "schema_org" 
            render template: "entity/show_schema", formats: [:html], content_type: 'text/html'
          else
            render json: @compacted_jsonld, content_type: 'application/ld+json'
          end
        else
          flash.alert = "This JSON-LD could not be generated. [template #{frame_template}]."
          redirect_back(fallback_location: root_path) 
        end
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
        @show_add_sameas_button = true if user_signed_in?
        @target_types = [
     #     RDF::Vocab::SCHEMA.Event, 
     #     RDF::Vocab::SCHEMA.Person,
         RDF::Vocab::SCHEMA.Organization,
     #     RDF::Vocab::SCHEMA.PerformingGroup,
          RDF::Vocab::SCHEMA.Place
      ]
  
        # TODO: add SHACL validation if artsdata entity
       
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

  # DELETE /entity
  # delete an entity by URI
  # this will delete all statements about the entity
  # and all statements that are derived from it
  # /entity?uri=[canonical URI]
  def destroy
    uri = params[:uri]
    @entity = Entity.new(entity_uri: uri)
    if @entity.delete
      flash.notice = "Deleted entity #{uri}."
    else
      flash.alert = "Could not delete entity #{uri}."
    end
    redirect_back(fallback_location: root_path)
  end


  private

  def check_delete_entity_access
    ensure_access("delete_entity")
  end

  # determine the shape for JSON-LD output
  # Frame_template can be "schema_org" or nil
  def shape(entity, frame_template)
    puts "Determining shape for entity: #{entity.entity_uri} with frame template: #{frame_template}"
    if frame_template
      if frame_template == "schema_org"
        entity_class = entity.type.value.split('/').last.downcase
        entity_class = "event" if entity_class == "eventseries" # Use 'event' for schema.org EventSeries
        file_path = Rails.root.join("app","services", "frames", "schema_org", "#{entity_class}_frame.jsonld")
        begin
          raise StandardError, "no frame file for entity class #{entity_class}" unless ["event","person","place","organization"].include? entity_class 
          frame = JSON.parse(File.read(file_path)) 
        rescue StandardError => e
          puts "Error parsing frame: #{e.message}"
          return
        end
        context = "http://schema.org"
        
        # Transform graph to work with schema.org @context
        # Add location, performers and organizers
        if entity_class == "event"
          entity.load_event_nested_entities
        end
        graph = entity.graph.dup
        graph = convert_dates(graph)
        graph = convert_eventStatus(graph)
        graph = convert_eventAttendanceMode(graph)
        graph = transform_image(graph)
        graph = pick_language(graph, I18n.locale)
        jsonld = JSON::LD::API::fromRdf(graph)
      else
        puts "No matching frame template: #{e.message}"
        frame = nil
      end
    else
      frame = nil
    end
    if !frame || !frame.is_a?(Hash)
      # use default frame if no valid frame is provided
      frame = {
        '@type' => entity.type.value,
        '@id' => entity.entity_uri.to_s,
        '@embed'=> '@once' # Default is @once
      }
      # use artsdata @context if no valid frame is provided
      context = "#{request.scheme}://#{request.host_with_port}/context.jsonld"
      # use graph without any transforms if no valid frame is provided
      jsonld = JSON::LD::API::fromRdf(@entity.graph)
    end

    return [frame, context, jsonld]
  end

  def transform_image(graph)
    update_string = <<-SPARQL
      PREFIX schema: <http://schema.org/>
      DELETE {
        ?s schema:image ?image .
      }
      INSERT {
        ?s schema:image [
          a schema:ImageObject ;
          schema:url ?image_uri ;
        ]  .
      }
      WHERE {
        ?s schema:image ?image .
        FILTER NOT EXISTS { ?image a schema:ImageObject }
        BIND(URI(str(?image)) AS ?image_uri)
      }
    SPARQL
    update = SPARQL.parse(update_string, update: true)
    graph.query(update)
    return graph
  end


  def convert_eventStatus(graph)
    update_string = <<-SPARQL
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      PREFIX schema: <http://schema.org/>
      DELETE {
        ?s schema:eventStatus ?eventStatus .
      }
      INSERT {
        ?s schema:eventStatus ?eventStatus_str .
      }
      WHERE {
        ?s schema:eventStatus ?eventStatus .
        BIND(str(?eventStatus) AS ?eventStatus_str)
      }
    SPARQL
    update = SPARQL.parse(update_string, update: true)
    graph.query(update)
    return graph
  end

  def convert_eventAttendanceMode(graph)
    update_string = <<-SPARQL
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      PREFIX schema: <http://schema.org/>
      DELETE {
        ?s schema:eventAttendanceMode ?attendanceMode .
      }
      INSERT {
        ?s schema:eventAttendanceMode ?attendanceMode_str .
      }
      WHERE {
        ?s schema:eventAttendanceMode ?attendanceMode .
        BIND(str(?attendanceMode) AS ?attendanceMode_str)
      }
    SPARQL
    update = SPARQL.parse(update_string, update: true)
    graph.query(update)
    return graph
  end

  # Convert xsd:dateTime and xsd:date to schema:Date
  def convert_dates(graph)
    update_string = <<-SPARQL
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      PREFIX schema: <http://schema.org/>
      DELETE {
        ?s ?p ?o .
      }
      INSERT {
        ?s ?p ?o_new .
      }
      WHERE {
        ?s ?p ?o .
        FILTER(isLiteral(?o))
        FILTER (DATATYPE(?o) IN (xsd:dateTime, xsd:date))
        BIND(str(?o) AS ?o_str)
        BIND(STRDT(?o_str, schema:Date) AS ?o_new)
      }
    SPARQL
    update = SPARQL.parse(update_string, update: true)
    graph.query(update)
    return graph
  end


  # Add non-language tagged literal
  # TODO: use lang to set first choice language
  def pick_language(graph, lang)
    update_string = <<-SPARQL
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

      # This SPARQL ensures that all language-tagged strings have a preferred non-language tagged literal 
      # using English and then French as a fallback
      # If a language-tagged string does not have an English fallback, it will be added

      INSERT {
      ?s ?p ?o_pref 
      }
      WHERE {
        ?s ?p ?o .
        # Find all language-tagged strings
        FILTER (DATATYPE(?o) = rdf:langString)

        # Check if there is already a preferred value without a language tag
        OPTIONAL {
          ?s ?p ?o_none .
          FILTER (LANG(?o_none) = "")
        }
        # If there is no preferred value, add one using english or french as fallback
        FILTER (!BOUND(?o_none))
        OPTIONAL {
          ?s ?p ?o_primary .
          FILTER (LANG(?o_primary) = "#{lang}")
        }
        OPTIONAL {
          ?s ?p ?o_secondary .
          FILTER (LANG(?o_secondary) != "#{lang}")
        }
        BIND(STR(COALESCE(?o_primary,?o_secondary)) AS ?o_pref)

      }
    SPARQL
    update = SPARQL.parse(update_string, update: true)
    graph.query(update)
    return graph
  end
 
end
