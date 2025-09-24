class QueryController < ApplicationController
  require 'csv'
  include ActionView::Helpers::SanitizeHelper
  
  # GET /query
  # Pass 'constructs=' param with a list of comma separated construct sparqls.
  # If contructs are passed, then the 'sparql=' param will use the local graph created by the constructs.
  # Otherwise, the 'sparql=' param will execute on the remote sparql endpoint.
  # Example: GET /query
  #   ?constructs=custom/scenepro-construct,custom/scenepro-construct-artsdata,custom/scenepro-construct-wikidata
  #   &sparql=custom/scenepro-query
  #   &title=ScenePro
  def show
    params.required(:sparql)
    permitted_params = params.permit(:sparql, :title, :graph, :constructs, :format, :locale)
    sparql_file = params[:sparql] 
    title =  params[:title] ||=  params[:sparql].split("/").last&.humanize&.gsub(".sparql", "")

    # Placeholders in SPARQL query
    graph = params[:graph]
    construct_files = params[:constructs].split(",") if params[:constructs]
    
    @query =  SparqlLoader.load(sparql_file, ["GRAPH_PLACEHOLDER", graph])

    solutions = if !construct_files
                  begin
                    ArtsdataApi::SparqlService.client.query(@query).limit(1000)
                  rescue StandardError => e # SPARQL::Client::ClientError and SPARQL::Client::ServerError
                    flash.alert = e.message[0..100] + (e.message.length > 100 ? "..." : "")
                    return redirect_to root_path,  data: { turbo: false }
                  end
                else
                  SPARQL.execute(@query,local_graph(construct_files, ArtsdataApi::SparqlService.client) )
                end

    respond_to do |format|
      format.html {
        render :show, locals: {title: title, solutions: solutions, permitted_params: permitted_params}
      }
      format.csv {
        send_data csv_data(solutions), type: 'text/csv; charset=utf-8; header=present', disposition: "attachment; filename=#{sparql_file}.csv"
      }
    end
  end







  private

  def local_graph(construct_files = [],sparql_client)
    graph = RDF::Graph.new
    construct_files.each do |file|
      query =  SparqlLoader.load(file)
      graph << sparql_client.query(query)
      puts "#{graph.count} triples after construct #{file}"
    end
    return graph
  end
 

  def csv_data(solutions)
    keys = solutions.variable_names
    CSV.generate(headers: true) do |csv|
      csv << keys
      solutions.each do |solution|
        row = []
        keys.each do |key|
          row << sanitize(solution[key]&.value, tags: ['p','br','em','strong','h1','h2','h3','h4','h5','h6','ul','ol','li','blockquote','code'])
        end
        csv << row
      end
    end
    
  end

end
