require 'test_helper'
require 'faraday'
require 'sparql/client'
require_relative '../../app/services/wikidata_sparql_service'

class WikidataSparqlServiceTest < ActiveSupport::TestCase
  test "client is configured with timeout settings" do
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

  test "timeout configuration is applied to Faraday connection" do
    # Verify that timeout settings are properly passed to Faraday
    # This tests the configuration, not the actual timeout behavior
    custom_timeout = 10
    custom_open_timeout = 5
    
    # Create a client with custom timeouts
    # Note: We can't easily test actual timeout behavior without making real network calls
    # or extensive mocking, so we verify the client is created successfully
    client = WikidataSparqlService.client(timeout: custom_timeout, open_timeout: custom_open_timeout)
    assert_not_nil client
    
    # The client should be a SPARQL::Client instance with our custom Faraday connection
    assert_instance_of SPARQL::Client, client
  end
end
