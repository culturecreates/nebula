class QueryController < ApplicationController
  require 'csv'

  # GET /query
  # Pass constructs with a list of comma separated construct sparqls.
  # If contructs are passed, then the sparql parameter will use the local graph created by the contrucuts.
  # Otherwise, the sparql will execute on the remote sparql endpoint.
  # Example: GET /query
  #   ?constructs=custom/scenepro-construct,custom/scenepro-construct-artsdata,custom/scenepro-construct-wikidata
  #   &sparql=custom/scenepro-query&title=ScenePro
  def show
    params.required(:sparql)
    permitted_params = params.permit(:sparql, :title, :graph, :constructs, :format, :locale)
    sparql_file = params[:sparql] 
    title =  params[:title] ||=  params[:sparql].split("/").last
    graph = params[:graph]
    construct_files = params[:constructs].split(",") if params[:constructs]

    sparql_endpoint = "#{Rails.application.credentials.graph_api_endpoint}/repositories/#{Rails.application.credentials.graph_repository}"
    sparql_client = SPARQL::Client.new(sparql_endpoint)
    query =  SparqlLoader.load(sparql_file, ["GRAPH_PLACEHOLDER", graph])
    solutions = if !construct_files
                  sparql_client.query(query).limit(1000)
                else
                  SPARQL.execute(query,local_graph(construct_files,sparql_client) )
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
          row << solution[key]&.value 
        end
        csv << row
      end
    end
    
  end

end
