require 'test_helper'
require 'faraday'
require 'sparql/client'
require_relative '../../app/services/wikidata_sparql_service'

class WikidataSparqlServiceTest < ActiveSupport::TestCase
  test "timeout is enforced" do
    # Use a non-routable endpoint to force a timeout
    unreachable_endpoint = "http://10.255.255.1/sparql" # TEST-NET-1, non-routable
    conn = Faraday.new do |f|
      f.options.timeout = 1
      f.options.open_timeout = 1
    end
    client = SPARQL::Client.new(unreachable_endpoint, http_client: conn, headers: {
      "User-Agent" => WikidataSparqlService.user_agent
    })

    assert_raises(Faraday::TimeoutError) do
      client.query("SELECT * WHERE { ?s ?p ?o } LIMIT 1")
    end
  end
end
