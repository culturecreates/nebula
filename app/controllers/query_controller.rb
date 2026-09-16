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
    permitted_params = params.permit(:sparql, :title, :description, :graph, :template, :constructs, :format, :locale, :uri)
    sparql_file = params[:sparql] 
    title =  params[:title] ||=  params[:sparql].split("/").last&.humanize&.gsub(".sparql", "")
    description = params[:description]

    # Placeholders in SPARQL query
    graph = params[:graph]
    template = params[:template]
    uri = params[:uri]
    construct_files = params[:constructs].split(",") if params[:constructs]

    begin
      @query = SparqlLoader.load(sparql_file, ["GRAPH_PLACEHOLDER", graph, "TEMPLATE_PLACEHOLDER", template, "URI_PLACEHOLDER", uri])
    rescue Errno::ENOENT
      # sparql= (or a file in constructs=) names a .sparql file that's been
      # removed/renamed since the link was shared - a 500 for a report that
      # simply doesn't exist anymore isn't useful to whoever followed it.
      # Suggest similarly-named reports from the same GitHub-hosted list
      # GithubController#sparqls already shows, in case this one was just renamed.
      @missing_sparql = sparql_file
      @suggestions = suggest_similar_sparqls(sparql_file)
      return render(plain: "This report is no longer available.", status: :not_found) if request.format.symbol == :csv
      return render(:not_found, status: :not_found)
    end

    solutions = if !construct_files
                  begin
                    ArtsdataGraph::SparqlService.client.query(@query).limit(1000)
                  rescue StandardError => e # SPARQL::Client::ClientError and SPARQL::Client::ServerError
                    flash.alert = e.message[0..100] + (e.message.length > 100 ? "..." : "")
                    return redirect_to root_path,  data: { turbo: false }
                  end
                else
                  SPARQL.execute(@query,local_graph(construct_files, ArtsdataGraph::SparqlService.client) )
                end

    respond_to do |format|
      format.html {
        render :show, locals: {title: title, description: description, solutions: solutions, permitted_params: permitted_params}
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
          row << sanitize(term_value(solution[key]), tags: ['p','br','em','strong','h1','h2','h3','h4','h5','h6','ul','ol','li','blockquote','code'])
        end
        csv << row
      end
    end

  end

  # A bound SPARQL variable isn't always an RDF::Literal/RDF::URI (both
  # define #value) - a query can legitimately bind a blank node too (e.g.
  # list_organizations.sparql's ?uri), and RDF::Node has no #value, which
  # raised NoMethodError and 500'd the whole CSV export over one row.
  def term_value(term)
    return nil if term.nil?
    term.respond_to?(:value) ? term.value : term.to_s
  end

  # Same GitHub-hosted list GithubController#sparqls shows, fuzzy-matched
  # against the missing report's name so a broken/renamed link can still
  # point at whatever's closest today. Best-effort: an unreachable GitHub
  # just means no suggestions, not another error on top of the first one.
  def suggest_similar_sparqls(missing_name, limit: 5)
    uri = URI("https://api.github.com/repos/artsdata-stewards/artsdata-actions/contents/queries")
    candidates = GithubService.info(nil, uri)
    return [] unless candidates.is_a?(Array)

    candidates = candidates.select { |c| c["download_url"].present? } # skip directories
    missing_tokens = tokenize(missing_name)

    candidates
      .map { |c| [sparql_name_similarity(missing_tokens, c["name"]), c] }
      .select { |score, _| score > 0 }
      .sort_by { |score, _| -score }
      .first(limit)
      .map(&:last)
  rescue StandardError
    []
  end

  def sparql_name_similarity(missing_tokens, candidate_filename)
    candidate_tokens = tokenize(candidate_filename.to_s.sub(/\.sparql\z/, ""))
    return 0.0 if missing_tokens.empty? || candidate_tokens.empty?

    (missing_tokens & candidate_tokens).size.to_f / (missing_tokens | candidate_tokens).size
  end

  def tokenize(name)
    name.to_s.downcase.split(/[^a-z0-9]+/).reject(&:empty?).uniq
  end

end
