require 'test_helper'
require 'faraday'
require 'sparql/client'
require_relative '../../app/services/wikidata_sparql_service'

class WikidataSparqlServiceTest < ActiveSupport::TestCase
  test "client is configured with custom timeout settings" do
    # Test that the client can be created with custom timeout values
    client = WikidataSparqlService.client(timeout: 5, open_timeout: 3)
    assert_not_nil client
    assert_instance_of SPARQL::Client, client
  end

  test "client uses default timeout settings" do
    # Test that the client can be created with default timeout values
    client = WikidataSparqlService.client
    assert_not_nil client
    assert_instance_of SPARQL::Client, client
  end
end
