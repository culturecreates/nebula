class ArtifactController < ApplicationController
  before_action :authenticate_databus_user! # ensure user has permissions
  before_action :check_delete_graph_access, only: [:delete_graph]

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
    databus_service = DatabusService.new(@artifact_uri, user_uri)
    if databus_service.delete_artifact
      flash.notice = "Deleted all versions of artifact '#{@artifact_uri}' in Databus."
      redirect_to artifact_index_path
    else
      flash.alert = "Could not delete '#{@artifact_uri}' : #{databus_service.errors}."
      redirect_back(fallback_location: root_path)
    end
    
  end

  # DELETE /artifact/delete_graph?graph=
  def delete_graph
    @graph_uri = params[:graph]

    # Validate URI to prevent SPARQL injection: require a valid http(s) URI
    # under the expected artsdata.ca host.
    begin
      parsed = URI.parse(@graph_uri.to_s)
      unless parsed.is_a?(URI::HTTP) && parsed.host.present?
        raise URI::InvalidURIError, "must be an http/https URI"
      end
    rescue URI::InvalidURIError
      flash.alert = "Invalid graph URI format."
      return redirect_back(fallback_location: artifact_index_path)
    end

    unless @graph_uri.start_with?("http://kg.artsdata.ca/", "https://kg.artsdata.ca/")
      flash.alert = "Invalid graph URI: only graphs under kg.artsdata.ca may be deleted."
      return redirect_back(fallback_location: artifact_index_path)
    end

    begin
      # Drop the named graph from the knowledge graph
      ArtsdataGraph::SparqlService.update_client.update("DROP SILENT GRAPH <#{@graph_uri}>")
      # Remove any metadata about the graph stored in Graph_Ranking
      metadata_query = <<~SPARQL
        WITH <http://kg.artsdata.ca/Graph_Ranking>
        DELETE { <#{@graph_uri}> ?p ?o . }
        WHERE  { <#{@graph_uri}> ?p ?o . }
      SPARQL
      ArtsdataGraph::SparqlService.update_client.update(metadata_query)
      flash.notice = "Deleted graph '#{@graph_uri}' from the Artsdata Knowledge Graph."
    rescue StandardError => e
      flash.alert = "Could not delete graph '#{@graph_uri}': #{e.message}"
    end
    redirect_back(fallback_location: artifact_index_path)
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

  def check_delete_graph_access
    ensure_access("delete_graph")
  end
end
