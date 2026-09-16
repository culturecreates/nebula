module ApplicationHelper

  # Returns the Github callback URL based on the environment
  def github_url
    "https://github.com/login/oauth/authorize?client_id=#{Rails.application.credentials.CLIENT_ID}&redirect_uri=#{request.base_url}/github/callback"
  end

  def display_warning(message)
    "<i style='color: red'>#{message}</i>".html_safe
  end

  def humanize_url(url)
    return if url.blank?
    url.split("/").last.split(".").first.humanize
  end

  def safe_external_url(url)
    return if url.blank?

    parsed_url = URI.parse(url)
    return parsed_url.normalize.to_s if parsed_url.is_a?(URI::HTTP) || parsed_url.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    nil
  end

  # Builds { "@context" => context_url, "@graph" => [...] } describing each dump as a
  # dcat:Distribution. `context_url` must point at a dereferenceable JSON-LD context
  # document (see public/context/dump-distribution.jsonld) rather than embedding the
  # context object inline - a lot of third-party tooling that scans pages for JSON-LD
  # (browser extensions, link-preview/social-share bots) assumes "@context" is always a
  # plain string and calls string methods on it directly; an inline object value breaks
  # those tools with something like "r[\"@context\"].toLowerCase is not a function".
  # Only dumps with a safe (http/https) download_url are included - a Distribution
  # without a working downloadURL isn't worth advertising. Returns nil when there's
  # nothing to advertise, so callers can skip the <script> tag entirely.
  def data_dumps_jsonld(dumps, context_url:)
    nodes = Array(dumps).filter_map do |dump|
      download_url = safe_external_url(dump[:download_url])
      next if download_url.blank?

      id = dump[:distribution_uri].presence || dump[:resource_uri]
      next if id.blank?

      {
        "id" => id,
        "type" => "dcat:Distribution",
        "name" => dump[:title],
        "comment" => dump[:description],
        "version" => dump[:version],
        "isVersionOf" => dump[:artifact_uri].presence || dump[:data_dump_uri],
        "mediaType" => dump[:media_type],
        "downloadURL" => download_url,
        "byteSize" => dump[:byte_size]
      }.select { |_, v| v.present? }
    end

    return if nodes.empty?

    { "@context" => context_url, "@graph" => nodes }
  end

  # Renders the JSON-LD as a CSP-nonce'd <script> tag, or nil if there's nothing to render.
  # json_escape (ERB::Util, mixed into every view) neutralizes "</script>", "<", ">", "&"
  # inside the JSON before marking it html_safe - required because title/description
  # strings come from an external MCP server response and a literal "</script>" would
  # otherwise break out of the tag. Do NOT use raw(...)/.html_safe alone here.
  def data_dumps_jsonld_script_tag(dumps)
    context_url = "#{request.scheme}://#{request.host_with_port}/context/dump-distribution.jsonld"
    jsonld = data_dumps_jsonld(dumps, context_url: context_url)
    return if jsonld.blank?

    tag.script(
      json_escape(jsonld.to_json).html_safe,
      type: "application/ld+json",
      nonce: content_security_policy_nonce
    )
  end

  def meta_description_tag(description)
    description = description.to_s.strip
    return if description.blank?

    tag.meta(name: "description", content: description)
  end

  def canonical_link_tag(url)
    # content_for(:canonical_url) do...end (used for the locale-conditional URL in
    # data_dumps.html.erb) captures the block's rendered whitespace/newlines along with
    # its output, so the value needs stripping before it lands in an href attribute.
    url = url.to_s.strip
    return if url.blank?

    tag.link(rel: "canonical", href: url)
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
      .gsub("https://schema.org/","schema-https:")
      .gsub("http://kg.artsdata.ca/resource/","adr:")
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

  

  # sets a limit on the number of dereferences per table.
  # Note that derived statements are a separate table.
  # The offset is used to ensure that multiple tables have different frame_ids
  def auto_dereference(string)
    @max ||= 3
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

  def generate_action_div
    if @url
      escaped_http_body = CGI.escapeHTML(@httpBody&.gsub('{{PublisherWebID}}', controller.user_uri))
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
      sub_graph << solution
      # For each solution, we need to check if the object is a blank node
      if solution.object.is_a?(RDF::Node)
        # If it is a blank node, we need to find all triples where this blank node is the subject
        sub_solutions = graph.query([solution.object, nil, nil])
        sub_solutions.each do |sub_solution|
          # Add these triples to the main graph
          sub_graph << sub_solution
        end
      end
    end
     # Serialize the graph into JSON-LD
    sub_graph.dump(:jsonld, standard_prefixes: true)
 
  end

  def make_hash(*args)
    "f#{Digest::SHA256.hexdigest(args.join.to_s)[0, 16]}"
  end
        
end
