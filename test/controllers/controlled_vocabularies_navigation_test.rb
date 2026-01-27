require "test_helper"

class ControlledVocabulariesNavigationTest < ActionDispatch::IntegrationTest
  test "navigation should display controlled vocabularies dynamically" do
    # Mock the SPARQL service to return test data
    mock_solutions = [
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataEventTypes") },
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataOrganizationTypes") },
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataGenres") }
    ]
    
    ArtsdataGraph::SparqlService.client.stubs(:query).returns(mock_solutions)
    
    get root_path
    
    assert_response :success
    
    # Check that the navigation contains the controlled vocabularies
    assert_includes @response.body, "Controlled Vocabularies"
    assert_includes @response.body, "Event Types"
    assert_includes @response.body, "Organization Types"
    assert_includes @response.body, "Genres"
    
    # Check that the URIs are properly encoded in the links
    assert_includes @response.body, CGI.escape("http://kg.artsdata.ca/resource/ArtsdataEventTypes")
  end
  
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
