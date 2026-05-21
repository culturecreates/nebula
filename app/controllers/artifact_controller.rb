class ArtifactController < ApplicationController
  GRAPH_METADATA_RATING_FRAGMENT = "endorsementRating".freeze

  before_action :authenticate_databus_user! # ensure user has permissions

  def index
    @databus_account = session[:accounts].first
    sparql_file =  "artifact_controller/list_artifacts"

    # Placeholders in SPARQL query
    @query =  SparqlLoader.load(sparql_file, [ "DATABUS_ACCOUNT", @databus_account.downcase])
    @artifacts =  begin
                    ArtsdataGraph::SparqlService.client.query(@query).limit(1000)  # TODO: fix limit
                  rescue StandardError => e # SPARQL::Client::ClientError and SPARQL::Client::ServerError
                    flash.alert = e.message[0..100] + (e.message.length > 100 ? "..." : "")
                    return redirect_to root_path,  data: { turbo: false }
                  end
  end

  def show
    @artifact = Artifact.find(params[:artifactUri])
    @automint_status = get_automint_status( @artifact.graph)
    @graph_metadata = get_graph_metadata(@artifact.graph)
  end

  def get_automint_status(graph)
    subject = RDF::URI(graph)
    automint = RDF::URI("http://kg.artsdata.ca/ontology/automint")
    response = ArtsdataGraph::SparqlService.client.select.where([subject, automint, :o]).execute

    return response.first&.o&.value == "true"
  end
  
  def toggle_auto_minting
    graph = params[:graph]
    new_boolean = params[:new_boolean]

 
    # Construct the SPARQL query to update the triple
    query = <<-SPARQL
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      WITH <http://kg.artsdata.ca/Graph_Ranking>
      DELETE {
        <#{graph}> <http://kg.artsdata.ca/ontology/automint> ?boolean .
      }
      INSERT {
        <#{graph}> <http://kg.artsdata.ca/ontology/automint> "#{new_boolean.to_s}"^^xsd:boolean  .
      }
      WHERE {
      OPTIONAL {
          <#{graph}> <http://kg.artsdata.ca/ontology/automint> ?boolean .
        } 
      }
    SPARQL

    begin
      ArtsdataGraph::SparqlService.update_client.update(query)
      flash.notice = "Auto-Minting has been #{new_boolean == "true" ? 'enabled' : 'disabled'}."
    rescue StandardError => e
      flash.alert = "Failed to toggle Auto-Minting: #{e.message}"
    end
    redirect_back(fallback_location: root_path)
  end

  def get_graph_metadata(graph)
    subject = RDF::URI(graph)
    schema = RDF::Vocab::SCHEMA
    rating_node = get_object_term(subject, schema.contentRating)

    {
      name: get_object_value(subject, schema.name),
      maintainer: get_object_value(subject, schema.maintainer),
      rating_value: rating_node ? get_object_value(rating_node, schema.ratingValue) : nil,
      rating_explanation: rating_node ? get_object_value(rating_node, schema.ratingExplanation) : nil
    }
  end

  def update_graph_metadata
    graph = params[:graph].to_s
    graph_name = params[:graph_name].to_s.strip
    maintainer = params[:maintainer].to_s.strip
    rating_value = params[:rating_value].to_s.strip
    rating_explanation = params[:rating_explanation].to_s.strip
    deleting = params[:delete_metadata] == "true"

    unless valid_graph_uri?(graph)
      flash.alert = "Failed to update graph metadata: invalid graph URI."
      return redirect_back(fallback_location: root_path)
    end

    if !deleting && maintainer.present? && !valid_http_uri?(maintainer)
      flash.alert = "Failed to update graph metadata: maintainer must be a valid URL."
      return redirect_back(fallback_location: root_path)
    end

    graph_name = "" if deleting
    maintainer = "" if deleting
    rating_value = "" if deleting
    rating_explanation = "" if deleting

    graph_term = sparql_uri(graph)
    rating_uri = "#{graph}##{GRAPH_METADATA_RATING_FRAGMENT}"
    rating_term = sparql_uri(rating_uri)
    schema_name = sparql_uri(RDF::Vocab::SCHEMA.name.to_s)
    schema_maintainer = sparql_uri(RDF::Vocab::SCHEMA.maintainer.to_s)
    schema_content_rating = sparql_uri(RDF::Vocab::SCHEMA.contentRating.to_s)
    schema_rating_value = sparql_uri(RDF::Vocab::SCHEMA.ratingValue.to_s)
    schema_rating_explanation = sparql_uri(RDF::Vocab::SCHEMA.ratingExplanation.to_s)
    schema_endorsement_rating = sparql_uri(RDF::Vocab::SCHEMA.EndorsementRating.to_s)
    rdf_type = sparql_uri(RDF.type.to_s)
    insert_triples = []
    insert_triples << "#{graph_term} #{schema_name} #{sparql_string_literal(graph_name)} ." if graph_name.present?
    insert_triples << "#{graph_term} #{schema_maintainer} #{sparql_uri(maintainer)} ." if maintainer.present?

    if rating_value.present? || rating_explanation.present?
      insert_triples << "#{graph_term} #{schema_content_rating} #{rating_term} ."
      insert_triples << "#{rating_term} #{rdf_type} #{schema_endorsement_rating} ."
      insert_triples << "#{rating_term} #{schema_rating_value} #{sparql_string_literal(rating_value)} ." if rating_value.present?
      insert_triples << "#{rating_term} #{schema_rating_explanation} #{sparql_string_literal(rating_explanation)} ." if rating_explanation.present?
    end

    query = <<~SPARQL
      WITH <http://kg.artsdata.ca/Graph_Ranking>
      DELETE {
        #{graph_term} #{schema_name} ?old_name .
        #{graph_term} #{schema_maintainer} ?old_maintainer .
        #{graph_term} #{schema_content_rating} ?old_rating .
        ?old_rating ?old_rating_p ?old_rating_o .
      }
      INSERT {
        #{insert_triples.join("\n")}
      }
      WHERE {
        OPTIONAL { #{graph_term} #{schema_name} ?old_name . }
        OPTIONAL { #{graph_term} #{schema_maintainer} ?old_maintainer . }
        OPTIONAL {
          #{graph_term} #{schema_content_rating} ?old_rating .
          OPTIONAL { ?old_rating ?old_rating_p ?old_rating_o . }
        }
      }
    SPARQL

    begin
      ArtsdataGraph::SparqlService.update_client.update(query)
      flash.notice = deleting ? "Graph metadata has been deleted." : "Graph metadata has been updated."
    rescue StandardError => e
      flash.alert = "Failed to update graph metadata: #{e.message}"
    end

    redirect_back(fallback_location: root_path)
  end

  # POST /artifact/push_latest
  def push_latest
    @artifact_uri = params[:artifactUri]
    databus_service = DatabusService.new(@artifact_uri, user_uri)
    if databus_service.push_lastest_artifact(@artifact_uri) 
      flash.notice = "Pushed latest artifact '#{databus_service.latest_version}' to Artsdata."
    else
      flash.alert = "Error pushing '#{databus_service.latest_version}' : #{databus_service.errors}."
    end
    redirect_back(fallback_location: root_path)
  end

  # DELETE /artifact?artifactUri=
  def destroy
    @artifact_uri = params[:artifactUri]
    @graph_uri = params[:graph]
    databus_service = DatabusService.new(@artifact_uri, user_uri)
    if databus_service.delete_artifact
      delete_graph_from_kg(@graph_uri)
      flash.notice = "Deleted artifact '#{@artifact_uri}' and its graph from Artsdata."
      redirect_to artifact_index_path
    else
      flash.alert = "Could not delete '#{@artifact_uri}' : #{databus_service.errors}."
      redirect_back(fallback_location: root_path)
    end
  end

  def new
    @artifact = Artifact.new
  end

  # POST /artifact
  def create

    @artifact = Artifact.new(artifact_params, user_uri)
    if @artifact.save
      flash.notice = "Created artifact '#{@artifact.name}'. You may now create versions of the artifact."
      redirect_to artifact_index_path
    else
      render 'new'
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def artifact_params
    params.permit(:name, :description, :type, :sheet_url, :webpage_url, :link_identifier)
  end

  def get_object_value(subject, predicate)
    response = ArtsdataGraph::SparqlService.client.select.where([subject, predicate, :o]).execute
    response.first&.o&.value
  end

  def get_object_term(subject, predicate)
    response = ArtsdataGraph::SparqlService.client.select.where([subject, predicate, :o]).execute
    response.first&.o
  end

  def sparql_string_literal(value)
    RDF::Literal(value.to_s).to_ntriples
  end

  def sparql_uri(value)
    RDF::URI(value.to_s).to_ntriples
  end

  def valid_http_uri?(value)
    parsed = URI.parse(value)
    parsed.is_a?(URI::HTTP) && parsed.host.present?
  rescue URI::InvalidURIError
    false
  end

  def valid_graph_uri?(value)
    parsed = URI.parse(value.to_s)
    parsed.is_a?(URI::HTTP) && parsed.host.present? &&
      value.start_with?("http://kg.artsdata.ca/", "https://kg.artsdata.ca/")
  rescue URI::InvalidURIError
    false
  end

  def delete_graph_from_kg(graph_uri)
    return if graph_uri.blank?

    begin
      parsed = URI.parse(graph_uri.to_s)
      unless parsed.is_a?(URI::HTTP) && parsed.host.present? &&
             graph_uri.start_with?("http://kg.artsdata.ca/", "https://kg.artsdata.ca/")
        raise URI::InvalidURIError, "invalid or disallowed graph URI"
      end
    rescue URI::InvalidURIError
      flash.alert = "Could not delete graph: invalid URI."
      return
    end

    begin
      ArtsdataGraph::SparqlService.update_client.update("DROP SILENT GRAPH <#{graph_uri}>")
      metadata_query = <<~SPARQL
        WITH <http://kg.artsdata.ca/Graph_Ranking>
        DELETE { <#{graph_uri}> ?p ?o . }
        WHERE  { <#{graph_uri}> ?p ?o . }
      SPARQL
      ArtsdataGraph::SparqlService.update_client.update(metadata_query)
    rescue StandardError => e
      flash.alert = "#{flash[:alert]} Could not delete graph '#{graph_uri}': #{e.message}".strip
    end
  end
end
