require "test_helper"

class QueryControllerTest < ActionDispatch::IntegrationTest
  test "should accept description parameter" do
    # Mock the SPARQL service to avoid external dependencies
    mock_solutions = []
    ArtsdataGraph::SparqlService.client.stubs(:query).returns(mock_solutions)
    
    get query_show_path, params: { 
      sparql: "custom/upcoming-events", 
      title: "Test Report",
      description: "reports.upcoming_events.description"
    }
    
    assert_response :success
    assert_includes @response.body, "Test Report"
  end
  
  test "should render view without description when not provided" do
    # Mock the SPARQL service to avoid external dependencies
    mock_solutions = []
    ArtsdataGraph::SparqlService.client.stubs(:query).returns(mock_solutions)
    
    get query_show_path, params: { 
      sparql: "custom/upcoming-events", 
      title: "Test Report"
    }
    
    assert_response :success
    assert_includes @response.body, "Test Report"
  end
end
