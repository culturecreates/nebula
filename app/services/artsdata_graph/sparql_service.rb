module ArtsdataGraph

  # Use the standard Ruby SPARQL client
  # TODO: Can the ArtsdataGraph::V2::Client be replaced with this?
  class SparqlService

    def self.client
      SPARQL::Client.new(sparql_endpoint, headers: {
          "User-Agent" => user_agent
        }
      )
    end

    def self.update_client
      SPARQL::Client.new("#{sparql_endpoint}/statements", headers: {
          "User-Agent" => user_agent,
          "Authorization" => "Basic #{Rails.application.credentials.graph_db_basic_auth}"
        }
      )
    end

    def self.sparql_endpoint
      "#{Rails.application.config.graph_api_endpoint}/repositories/#{Rails.application.credentials.graph_repository}"
    end

    def self.user_agent
      default_ua = SPARQL::Client::DEFAULT_HEADERS["User-Agent"] rescue "Ruby"
      "#{default_ua} (compatible; ArtsdataGraph::SparqlService; +https://artsdata.ca)"
    end

  end

end