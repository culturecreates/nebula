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

  test "csv export handles a blank-node value instead of raising NoMethodError" do
    node = RDF::Node.new("node3975930")
    mock_solution = { uri: node, name: RDF::Literal("Some Org") }
    mock_solutions = [mock_solution]
    mock_solutions.stubs(:variable_names).returns([:uri, :name])
    mock_result = mock("query_result")
    mock_result.stubs(:limit).returns(mock_solutions)
    @mock_client.stubs(:query).returns(mock_result)

    get query_show_path(format: :csv), params: {
      sparql: "list_organizations",
      title: "Organizations"
    }

    assert_response :success
    assert_includes @response.body, "_:node3975930"
    assert_includes @response.body, "Some Org"
  end

  test "missing sparql file renders a friendly not-found page with fuzzy-matched suggestions" do
    GithubService.stubs(:info).returns([
      { "name" => "lavitrine-sources-refresh-rate.sparql", "download_url" => "https://raw.githubusercontent.com/artsdata-stewards/artsdata-actions/main/queries/lavitrine-sources-refresh-rate.sparql" },
      { "name" => "totally-unrelated-report.sparql", "download_url" => "https://raw.githubusercontent.com/artsdata-stewards/artsdata-actions/main/queries/totally-unrelated-report.sparql" },
      { "name" => "some-subfolder", "download_url" => nil } # directory entry, should be skipped
    ])

    get query_show_path, params: {
      sparql: "custom/lavitrine_sources_refresh_rate",
      title: "LaVitrine Pipeline"
    }

    assert_response :not_found
    assert_includes @response.body, "This report is no longer available"
    assert_includes @response.body, "lavitrine-sources-refresh-rate"
    assert_not_includes @response.body, "totally-unrelated-report"
  end

  test "missing sparql file with no GitHub match still renders the not-found page" do
    GithubService.stubs(:info).returns([
      { "name" => "totally-unrelated-report.sparql", "download_url" => "https://raw.githubusercontent.com/artsdata-stewards/artsdata-actions/main/queries/totally-unrelated-report.sparql" }
    ])

    get query_show_path, params: { sparql: "custom/does_not_exist_anywhere" }

    assert_response :not_found
    assert_includes @response.body, "This report is no longer available"
    assert_not_includes @response.body, "Did you mean"
  end

  test "missing sparql file as csv returns a plain-text not-found response" do
    get query_show_path(format: :csv), params: { sparql: "custom/does_not_exist_anywhere" }

    assert_response :not_found
    assert_equal "This report is no longer available.", @response.body
  end

  test "GitHub being unreachable degrades to the plain not-found message" do
    GithubService.stubs(:info).raises(StandardError, "connection failed")

    get query_show_path, params: { sparql: "custom/does_not_exist_anywhere" }

    assert_response :not_found
    assert_includes @response.body, "This report is no longer available"
  end
end
