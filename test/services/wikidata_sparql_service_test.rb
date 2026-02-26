require 'test_helper'
require 'faraday'
require 'sparql/client'
require_relative '../../app/services/wikidata_sparql_service'

class WikidataSparqlServiceTest < ActiveSupport::TestCase

  test "client instantiates correctly" do
    # Test that the client can be created
    client = WikidataSparqlService.client
    assert_not_nil client
    assert_instance_of SPARQL::Client, client
  end
end
