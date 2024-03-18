require 'test_helper'

class ResourceControllerTest < ActionDispatch::IntegrationTest
  test "should redirect with correct format for RDF" do
    get '/resource/K', headers: { 'Accept' => 'application/rdf+xml' }
    assert_redirected_to entity_path(uri: 'http://kg.artsdata.ca/resource/K', format: :rdf)
  end

  test "should redirect with correct format for JSON-LD" do
    get '/resource/K', headers: { 'Accept' => 'application/ld+json' }
    assert_redirected_to entity_path(uri: 'http://kg.artsdata.ca/resource/K', format: :jsonld)
  end

  test "should redirect with correct format for Turtle" do
    get '/resource/K', headers: { 'Accept' => 'text/turtle' }
    assert_redirected_to entity_path(uri: 'http://kg.artsdata.ca/resource/K', format: :ttl)
  end

  test "should redirect with correct format for HTML" do
    get '/resource/K'
    assert_redirected_to entity_path(uri: 'http://kg.artsdata.ca/resource/K', format: :html)
  end
end
