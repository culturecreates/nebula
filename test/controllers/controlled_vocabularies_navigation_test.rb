require "test_helper"

class ControlledVocabulariesNavigationTest < ActionDispatch::IntegrationTest
  test "navigation should display controlled vocabularies dynamically" do
    # Mock the SPARQL service to return test data with labels
    mock_solutions = [
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataEventTypes"), 
        label: RDF::Literal.new("Event Types", language: :en) },
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataEventTypes"), 
        label: RDF::Literal.new("Types d'événements", language: :fr) },
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataOrganizationTypes"), 
        label: RDF::Literal.new("Organization Types", language: :en) },
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataOrganizationTypes"), 
        label: RDF::Literal.new("Types d'organisations", language: :fr) },
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataGenres"), 
        label: RDF::Literal.new("Genres", language: :en) },
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataGenres"), 
        label: RDF::Literal.new("Genres", language: :fr) }
    ]
    
    # Create a mock query result that responds to limit
    mock_result = mock('query_result')
    mock_result.stubs(:limit).returns(mock_solutions)
    
    ArtsdataGraph::SparqlService.client.stubs(:query).returns(mock_result)
    
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
  
  test "navigation should display French labels when locale is fr" do
    # Mock the SPARQL service to return test data with labels
    mock_solutions = [
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataEventTypes"), 
        label: RDF::Literal.new("Event Types", language: :en) },
      { cv: RDF::URI.new("http://kg.artsdata.ca/resource/ArtsdataEventTypes"), 
        label: RDF::Literal.new("Types d'événements", language: :fr) }
    ]
    
    # Create a mock query result that responds to limit
    mock_result = mock('query_result')
    mock_result.stubs(:limit).returns(mock_solutions)
    
    ArtsdataGraph::SparqlService.client.stubs(:query).returns(mock_result)
    
    get root_path, params: { locale: 'fr' }
    
    assert_response :success
    
    # Check that the navigation contains the French label
    assert_includes @response.body, "Types d&#39;événements"
  end
end
