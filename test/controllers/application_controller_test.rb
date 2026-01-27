require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "navigation should use fallback if SPARQL query fails" do
    # Mock the SPARQL service to raise an error
    ArtsdataGraph::SparqlService.client.stubs(:query).raises(StandardError.new("Connection failed"))
    
    get root_path
    
    assert_response :success
    
    # Should still display the fallback vocabularies
    assert_includes @response.body, "Controlled Vocabularies"
    assert_includes @response.body, "Event Types"
  end

end
