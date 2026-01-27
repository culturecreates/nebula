require "test_helper"

class QueryControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Create a mock client
    @mock_client = mock('sparql_client')
    ArtsdataGraph::SparqlService.stubs(:client).returns(@mock_client)
  end
  
  test "should accept description parameter" do
    # Mock the SPARQL service to avoid external dependencies
    # Create a mock solutions object that behaves like a SPARQL result
    mock_solutions = []
    mock_solutions.stubs(:variable_names).returns([])
    mock_result = mock('query_result')
    mock_result.stubs(:limit).returns(mock_solutions)
    @mock_client.stubs(:query).returns(mock_result)
    
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
    # Create a mock solutions object that behaves like a SPARQL result
    mock_solutions = []
    mock_solutions.stubs(:variable_names).returns([])
    mock_result = mock('query_result')
    mock_result.stubs(:limit).returns(mock_solutions)
    @mock_client.stubs(:query).returns(mock_result)
    
    get query_show_path, params: { 
      sparql: "custom/upcoming-events", 
      title: "Test Report"
    }
    
    assert_response :success
    assert_includes @response.body, "Test Report"
  end
end
