class WikidataSparqlService

  def self.client(timeout: 3, open_timeout: 2)
    Rails.logger.info "Initializing Wikidata SPARQL client with endpoint #{sparql_endpoint} and user agent #{user_agent}"
    conn = Faraday.new do |f|
      f.options.timeout = timeout      # read timeout in seconds
      f.options.open_timeout = open_timeout # connection open timeout in seconds
    end
    
    SPARQL::Client.new(sparql_endpoint, http_client: conn, headers: {
        "User-Agent" => user_agent
      }
    )
  end

  def self.sparql_endpoint
    "https://query.wikidata.org/sparql"
  end

  def self.user_agent
    default_ua = SPARQL::Client::DEFAULT_HEADERS["User-Agent"] rescue "Ruby"
    "#{default_ua} (compatible; +https://artsdata.ca)"
  end

end