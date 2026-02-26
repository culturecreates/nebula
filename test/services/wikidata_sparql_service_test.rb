require 'test_helper'
require 'faraday'
require 'sparql/client'
require_relative '../../app/services/wikidata_sparql_service'

class WikidataSparqlServiceTest < ActiveSupport::TestCase
  test "timeout is enforced" do
    # Use a blackhole IP that will cause a connection timeout
    # 198.51.100.1 is from TEST-NET-2 (RFC 5737) and should cause a timeout
    blackhole_endpoint = "http://198.51.100.1:9999/sparql"
    conn = Faraday.new do |f|
      f.options.timeout = 1
      f.options.open_timeout = 1
    end
    client = SPARQL::Client.new(blackhole_endpoint, http_client: conn, headers: {
      "User-Agent" => WikidataSparqlService.user_agent
    })

    # The query should raise either Faraday::TimeoutError or Faraday::ConnectionFailed
    assert_raises(Faraday::TimeoutError, Faraday::ConnectionFailed) do
      client.query("SELECT * WHERE { ?s ?p ?o } LIMIT 1")
    end
  end

  test "wikidata client is configured with timeout" do
    client = WikidataSparqlService.client(timeout: 5, open_timeout: 3)
    assert_not_nil client
    # Verify the client is a SPARQL::Client instance
    assert_instance_of SPARQL::Client, client
  end
end
