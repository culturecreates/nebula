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

  test "feeds_all should render github issue icon inline with dataset name" do
    dataset_value = "Dataset Name <a href='https://github.com/culturecreates/nebula/issues/123' title='Source log' target='_blank'><i class=\"fa-brands fa-github\" style='font-size:0.75em;'></i></a>"
    mock_solution = { dataset: RDF::Literal(dataset_value) }
    mock_solutions = [mock_solution]
    mock_solutions.stubs(:variable_names).returns([:dataset])
    mock_result = mock("query_result")
    mock_result.stubs(:limit).returns(mock_solutions)
    @mock_client.stubs(:query).returns(mock_result)

    get query_show_path, params: {
      sparql: "feeds_all",
      title: "Data Feeds"
    }

    assert_response :success
    assert_includes @response.body, "Dataset Name"
    assert_includes @response.body, "fa-brands fa-github"
    assert_includes @response.body, "https://github.com/culturecreates/nebula/issues/123"
  end
end
