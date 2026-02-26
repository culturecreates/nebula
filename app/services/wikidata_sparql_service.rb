class WikidataSparqlService

  def self.client
    SPARQL::Client.new(sparql_endpoint, headers: {
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