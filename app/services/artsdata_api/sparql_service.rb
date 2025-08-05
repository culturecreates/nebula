module ArtsdataApi

  # Use the standard Ruby SPARQL client
  # TODO: Can the ArtsdataApi::V2::Client be replaced with this?
  class SparqlService

    def self.sparql_endpoint
      "#{Rails.application.config.graph_api_endpoint}/repositories/#{Rails.application.credentials.graph_repository}"
    end

    def self.client
      SPARQL::Client.new(sparql_endpoint)
    end

    def self.update_client
      SPARQL::Client.new("#{sparql_endpoint}/statements", headers: {
          "Authorization" => "Basic #{Rails.application.credentials.graph_db_basic_auth}"
        }
      )
    end

  end

end