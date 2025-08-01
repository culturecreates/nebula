module ApplicationHelper

  # Returns the Github callback URL based on the environment
  def github_url
    "https://github.com/login/oauth/authorize?client_id=#{Rails.application.credentials.CLIENT_ID}&redirect_uri=#{request.base_url}/github/callback"
  end

  def display_warning(message)
    "<i style='color: red'>#{message}</i>".html_safe
  end

  def humanize_url(url)
    url.split("/").last.split(".").first.humanize
  end

  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    str = "Artsdata"
    str += " DEV" if Rails.env.development?
    if page_title.present?
      str = "#{page_title} | #{str}"
    end
    str.html_safe
  end

  def og_meta_properties(og_title, og_image)
    og_properties = ''
    if og_title.present?
      og_properties += "<meta property='og:title' content='#{og_title}' />"
    end
    if og_image.present?
      og_properties += "<meta property='og:image' content='#{og_image}' />"
    end
    og_properties.html_safe
  end

  def meta_alternate_links(uri)
    alternate_links = ''
    if uri.present?
      alternate_links += "<link rel='alternate' type='application/ld+json' href='/entity.jsonld?uri=#{uri}' />"
      alternate_links += "<link rel='alternate' type='text/turtle' href='/entity.ttl?uri=#{uri}' />"
      # TODO: Add turtle star 
    end
    alternate_links.html_safe
  end


  def use_prefix(uri)
    return if uri.blank?

    uri = uri.value if uri.class != String
    uri_compact = uri.gsub("http://schema.org/","schema:")
      .gsub("https://schema.org/","schemas:")
      .gsub("http://kg.artsdata.ca/resource/","ad:")
      .gsub("http://kg.artsdata.ca/ontology/","ado:")
      .gsub("http://kg.artsdata.ca/databus/","databus:")
      .gsub("http://kg.footlight.io/resource/","footlight-console:")
      .gsub("http://lod.footlight.io/resource/","footlight-cms:")
      .gsub("http://www.w3.org/1999/02/22-rdf-syntax-ns#","rdf:")
      .gsub("http://www.w3.org/2000/01/rdf-schema#","rdfs:")
      .gsub("http://www.w3.org/2002/07/owl#","owl:")
      .gsub("http://www.w3.org/2004/02/skos/core#","skos:")
      .gsub("http://www.w3.org/ns/prov#","prov:")
      .gsub("http://www.w3.org/ns/shacl#","shacl:")
      .gsub("http://www.wikidata.org/entity/","wd:")
      .gsub("http://www.w3.org/2001/XMLSchema#", "xsd:")
      .gsub("http://example.org/","ex:")
      .gsub("http://scenepro.ca#","sp:")
      .gsub("http://purl.org/dc/terms/","dc:")
      .gsub("http://xmlns.com/foaf/0.1/","foaf:")
      .gsub("http://dataid.dbpedia.org/ns/core#","dataid:")
      .gsub("http://rdfs.org/ns/void#","void:")
      .gsub("http://www.w3.org/ns/dcat#","dcat:")
      .gsub("http://ogp.me/ns#", "og:")
      .gsub("http://purl.org/vocab/vann/", "vann:")
      .gsub("http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#","ebucore:")

    if uri_compact.present?
      return uri_compact
    else
      return uri
    end
  end

  def sparql_endpoint
    "#{Rails.application.config.graph_api_endpoint}/repositories/#{Rails.application.credentials.graph_repository}"
  end

  # Use the standard Ruby SPARQL client
  # TODO: Can the ArtsdataApi::V2::Client be replaced with this?
  def artsdata_sparql_client
    SPARQL::Client.new(sparql_endpoint)
  end

  def artsdata_sparql_update_client
    SPARQL::Client.new("#{sparql_endpoint}/statements", headers: {
        "Authorization" => "Basic #{Rails.application.credentials.graph_db_basic_auth}"
      }
    )
  end

  # sets a limit on the number of dereferences per table.
  # Note that derived statements are a separate table.
  # The offset is used to ensure that multiple tables have different frame_ids
  def auto_dereference(string)
    @max ||= 8
    if @frame_id
      @frame_id += 1 
      return false if @frame_id >  @offset +  @max
      return false if string.include?("wikidata.org")
    else
      @offset = rand(1000..9999)
      @frame_id = @offset
    end
    return true
  end

  # For UI portion of schema:Action
  def setup_action(o, p)
    @httpMethod = o.to_s if p.to_s == "http://schema.org/httpMethod"
    @httpBody = o.to_s if p.to_s == "http://schema.org/httpBody"
    @url = o.to_s if p.to_s == "http://schema.org/urlTemplate"
  end

  def user_uri
    if session[:handle].present?
      "https://github.com/#{session[:handle]}#this"
    end
  end

  def generate_action_div
    if @url
      escaped_http_body = CGI.escapeHTML(@httpBody&.gsub('{{PublisherWebID}}', user_uri))
      <<-HTML.html_safe
        <div
          data-controller="githubapi"
          data-githubapi-token-value="#{session[:token]}"
          data-githubapi-url-value="#{@url}"
          data-githubapi-method-value="#{@httpMethod}"
          data-githubapi-httpbody-value="#{escaped_http_body}"
        >
          <button
            data-githubapi-target="button"
            class="btn btn-danger m-3"
            data-action="githubapi#runAction"
          >Run Action</button>

          <p class="m-3" data-githubapi-target="result">
          </p>
        </div>
      HTML
    end
  end

  def dump_jsonld(subject, graph)
    solutions = graph.query([subject, nil, nil])
    sub_graph = RDF::Graph.new
    solutions.each do |solution|
      # For each solution, we need to check if the object is a blank node
      if solution.object.is_a?(RDF::Node)
        # If it is a blank node, we need to find all triples where this blank node is the subject
        sub_solutions = graph.query([solution.object, nil, nil])
        sub_solutions.each do |sub_solution|
          # Add these triples to the main graph
          sub_graph << sub_solution
        end
      else
        # If it's not a blank node, just add the original triple to the sub_graph
        sub_graph << solution
      end
    end
     # Serialize the graph into JSON-LD
    sub_graph.dump(:jsonld, standard_prefixes: true)
 
  end
        
    
end
