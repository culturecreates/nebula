require "test_helper"

class ArtifactControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mock_client = mock('sparql_client')
    @mock_update_client = mock('sparql_update_client')
    ArtsdataGraph::SparqlService.stubs(:client).returns(@mock_client)
    ArtsdataGraph::SparqlService.stubs(:update_client).returns(@mock_update_client)

    # Stub session to provide the account required by the controller
    ArtifactController.any_instance.stubs(:session).returns(
      { 'accounts' => ['testaccount'], 'handle' => 'testuser' }.with_indifferent_access
    )
  end

  # ---------------------------------------------------------------------------
  # SPARQL file validations
  # ---------------------------------------------------------------------------

  test "list_artifacts SPARQL file should exist" do
    assert File.exist?(Rails.root.join("app/services/sparqls/artifact_controller/list_artifacts.sparql")),
           "list_artifacts.sparql file is missing"
  end

  test "list_artifacts SPARQL should contain the schema prefix" do
    sparql = File.read(Rails.root.join("app/services/sparqls/artifact_controller/list_artifacts.sparql"))
    assert_match(/PREFIX\s+schema:\s*<http:\/\/schema\.org\/>/, sparql,
                 "list_artifacts.sparql is missing the schema: PREFIX declaration")
  end

  test "list_artifacts SPARQL should contain the ado prefix" do
    sparql = File.read(Rails.root.join("app/services/sparqls/artifact_controller/list_artifacts.sparql"))
    assert_match(/PREFIX\s+ado:\s*<http:\/\/kg\.artsdata\.ca\/ontology\/>/, sparql,
                 "list_artifacts.sparql is missing the ado: PREFIX declaration")
  end

  test "list_artifacts SPARQL should contain the DATABUS_ACCOUNT placeholder" do
    sparql = File.read(Rails.root.join("app/services/sparqls/artifact_controller/list_artifacts.sparql"))
    assert_includes sparql, "DATABUS_ACCOUNT",
                    "list_artifacts.sparql is missing the DATABUS_ACCOUNT placeholder"
  end

  test "list_artifacts SPARQL should be syntactically valid" do
    sparql = SparqlLoader.load("artifact_controller/list_artifacts", ["DATABUS_ACCOUNT", "testaccount"])
    assert_nothing_raised do
      SPARQL::Grammar.parse(sparql)
    end
  end

  # ---------------------------------------------------------------------------
  # index action
  # ---------------------------------------------------------------------------

  test "index should respond successfully with mocked SPARQL service" do
    mock_solutions = []
    mock_solutions.stubs(:variable_names).returns([])
    mock_result = mock('query_result')
    mock_result.stubs(:limit).returns(mock_solutions)
    @mock_client.stubs(:query).returns(mock_result)

    get artifact_index_path
    assert_response :success
  end

  test "index should redirect to root when the SPARQL query raises an error" do
    @mock_client.stubs(:query).raises(StandardError.new("SPARQL connection error"))

    get artifact_index_path
    assert_redirected_to root_path
    assert_match(/SPARQL connection error/, flash[:alert])
  end

  # ---------------------------------------------------------------------------
  # new action
  # ---------------------------------------------------------------------------

  test "new should respond successfully" do
    get new_artifact_path
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # create action
  # ---------------------------------------------------------------------------

  test "create should redirect to artifact index on success" do
    Artifact.any_instance.stubs(:save).returns(true)
    Artifact.any_instance.stubs(:name).returns("test-artifact")

    post artifact_index_path, params: {
      name: "Test Artifact",
      description: "A test artifact",
      type: "spreadsheet-a10s",
      sheet_url: "https://docs.google.com/spreadsheets/d/test"
    }

    assert_redirected_to artifact_index_path
    assert_match(/Created artifact/, flash[:notice])
  end

  test "create should render new when save fails" do
    Artifact.any_instance.stubs(:save).returns(false)

    post artifact_index_path, params: {
      name: "",
      description: "A test artifact",
      type: "spreadsheet-a10s"
    }

    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # show action
  # ---------------------------------------------------------------------------

  test "show should respond successfully with automint status" do
    artifact_uri = "http://kg.artsdata.ca/databus/testaccount/group/artifact"

    mock_select = mock('select_query')
    mock_select.stubs(:where).returns(mock_select)
    mock_select.stubs(:execute).returns([])
    @mock_client.stubs(:select).returns(mock_select)
    @mock_client.stubs(:query).returns([])

    get artifact_path(id: 'show'), params: { artifactUri: artifact_uri }
    assert_response :success
  end

  test "show should display graph metadata values when available" do
    artifact_uri = "http://kg.artsdata.ca/databus/testaccount/group/artifact"
    graph_uri = "http://kg.artsdata.ca/testaccount/group/artifact"
    rating_uri = RDF::URI("#{graph_uri}#endorsementRating")
    mock_select = Object.new
    mock_select.define_singleton_method(:where) do |triple_pattern|
      @last_subject = triple_pattern[0]
      @last_predicate = triple_pattern[1]
      self
    end
    mock_select.define_singleton_method(:execute) do
      schema = RDF::Vocab::SCHEMA
      automint = RDF::URI("http://kg.artsdata.ca/ontology/automint")
      solution_class = Struct.new(:o)
      literal_class = Struct.new(:value)
      literal_solution = ->(value) { [solution_class.new(literal_class.new(value))] }

      if @last_predicate == automint
        literal_solution.call("true")
      elsif @last_subject == RDF::URI(graph_uri) && @last_predicate == schema.name
        literal_solution.call("Graph Name")
      elsif @last_subject == RDF::URI(graph_uri) && @last_predicate == schema.maintainer
        literal_solution.call("https://example.org/maintainer")
      elsif @last_subject == RDF::URI(graph_uri) && @last_predicate == schema.contentRating
        [solution_class.new(rating_uri)]
      elsif @last_subject == rating_uri && @last_predicate == schema.ratingValue
        literal_solution.call("4")
      elsif @last_subject == rating_uri && @last_predicate == schema.ratingExplanation
        literal_solution.call("Trusted source")
      else
        []
      end
    end
    @mock_client.stubs(:select).returns(mock_select)
    @mock_client.stubs(:query).returns([])

    get artifact_path(id: "show"), params: { artifactUri: artifact_uri }

    assert_response :success
    assert_match(/Graph Metadata/, response.body)
    assert_match(/Name/, response.body)
    assert_match(/Maintainer/, response.body)
    assert_match(/Rating Value/, response.body)
    assert_match(/Rating Explanation/, response.body)
    assert_includes response.body, "Graph Name"
    assert_includes response.body, "https://example.org/maintainer"
    assert_match(/Trusted source/, response.body)
  end

  # ---------------------------------------------------------------------------
  # toggle_auto_minting action
  # ---------------------------------------------------------------------------

  test "toggle_auto_minting should set an enabled notice and redirect" do
    @mock_update_client.stubs(:update)

    post toggle_auto_minting_artifact_index_path, params: {
      graph: "http://kg.artsdata.ca/testaccount/group/artifact",
      new_boolean: "true"
    }

    assert_match(/enabled/, flash[:notice])
    assert_response :redirect
  end

  test "toggle_auto_minting should set a disabled notice and redirect" do
    @mock_update_client.stubs(:update)

    post toggle_auto_minting_artifact_index_path, params: {
      graph: "http://kg.artsdata.ca/testaccount/group/artifact",
      new_boolean: "false"
    }

    assert_match(/disabled/, flash[:notice])
    assert_response :redirect
  end

  test "toggle_auto_minting should set an alert flash when the SPARQL update fails" do
    @mock_update_client.stubs(:update).raises(StandardError.new("SPARQL update error"))

    post toggle_auto_minting_artifact_index_path, params: {
      graph: "http://kg.artsdata.ca/testaccount/group/artifact",
      new_boolean: "true"
    }

    assert_match(/Failed to toggle Auto-Minting/, flash[:alert])
    assert_response :redirect
  end

  # ---------------------------------------------------------------------------
  # update_graph_metadata action
  # ---------------------------------------------------------------------------

  test "update_graph_metadata should set notice and redirect on success" do
    @mock_update_client.stubs(:update)

    post update_graph_metadata_artifact_index_path, params: {
      graph: "http://kg.artsdata.ca/testaccount/group/artifact",
      graph_name: "My graph",
      maintainer: "https://example.org/org",
      rating_value: "5",
      rating_explanation: "Great quality"
    }

    assert_match(/updated/, flash[:notice])
    assert_response :redirect
  end

  test "update_graph_metadata should reject invalid maintainer URL" do
    post update_graph_metadata_artifact_index_path, params: {
      graph: "http://kg.artsdata.ca/testaccount/group/artifact",
      maintainer: "not-a-url"
    }

    assert_match(/maintainer must be a valid URL/, flash[:alert])
    assert_response :redirect
  end

  test "update_graph_metadata should set deleted notice when delete button is used" do
    @mock_update_client.stubs(:update)

    post update_graph_metadata_artifact_index_path, params: {
      graph: "http://kg.artsdata.ca/testaccount/group/artifact",
      delete_metadata: "true"
    }

    assert_match(/deleted/, flash[:notice])
    assert_response :redirect
  end

  test "update_graph_metadata should allow blank values and clear metadata" do
    @mock_update_client.stubs(:update)

    post update_graph_metadata_artifact_index_path, params: {
      graph: "http://kg.artsdata.ca/testaccount/group/artifact",
      graph_name: "",
      maintainer: "",
      rating_value: "",
      rating_explanation: ""
    }

    assert_match(/updated/, flash[:notice])
    assert_response :redirect
  end

  test "update_graph_metadata should set alert on SPARQL update error" do
    @mock_update_client.stubs(:update).raises(StandardError.new("SPARQL update error"))

    post update_graph_metadata_artifact_index_path, params: {
      graph: "http://kg.artsdata.ca/testaccount/group/artifact",
      graph_name: "My graph"
    }

    assert_match(/Failed to update graph metadata/, flash[:alert])
    assert_response :redirect
  end

  # ---------------------------------------------------------------------------
  # push_latest action
  # ---------------------------------------------------------------------------

  test "push_latest should redirect with a success notice when the push succeeds" do
    mock_databus = mock('databus_service')
    # NOTE: 'push_lastest_artifact' is intentionally misspelled to match the
    # method name in DatabusService.
    mock_databus.stubs(:push_lastest_artifact).returns(true)
    mock_databus.stubs(:latest_version).returns("2024-01-01")
    DatabusService.stubs(:new).returns(mock_databus)

    post push_latest_artifact_index_path, params: {
      artifactUri: "http://kg.artsdata.ca/databus/testaccount/group/artifact"
    }

    assert_match(/Pushed latest artifact/, flash[:notice])
    assert_response :redirect
  end

  test "push_latest should redirect with an error alert when the push fails" do
    mock_databus = mock('databus_service')
    # NOTE: 'push_lastest_artifact' is intentionally misspelled to match the
    # method name in DatabusService.
    mock_databus.stubs(:push_lastest_artifact).returns(false)
    mock_databus.stubs(:latest_version).returns(nil)
    mock_databus.stubs(:errors).returns(["API Error: 500"])
    DatabusService.stubs(:new).returns(mock_databus)

    post push_latest_artifact_index_path, params: {
      artifactUri: "http://kg.artsdata.ca/databus/testaccount/group/artifact"
    }

    assert_match(/Error pushing/, flash[:alert])
    assert_response :redirect
  end

  # ---------------------------------------------------------------------------
  # push_version action
  # ---------------------------------------------------------------------------

  test "push_version should redirect with a success notice when load succeeds" do
    mock_databus = mock('databus_service')
    mock_databus.stubs(:push_version).returns(true)
    DatabusService.stubs(:new).returns(mock_databus)

    post push_version_artifact_index_path, params: {
      artifactUri: "http://kg.artsdata.ca/databus/testaccount/group/artifact",
      artifactVersionUri: "http://kg.artsdata.ca/databus/testaccount/group/artifact/2024-01-01#Dataset"
    }

    assert_match(/Loaded artifact version/, flash[:notice])
    assert_response :redirect
  end

  test "push_version should redirect with an error alert when load fails" do
    mock_databus = mock('databus_service')
    mock_databus.stubs(:push_version).returns(false)
    mock_databus.stubs(:errors).returns(["API Error: 500"])
    DatabusService.stubs(:new).returns(mock_databus)

    post push_version_artifact_index_path, params: {
      artifactUri: "http://kg.artsdata.ca/databus/testaccount/group/artifact",
      artifactVersionUri: "http://kg.artsdata.ca/databus/testaccount/group/artifact/2024-01-01#Dataset"
    }

    assert_match(/Error loading/, flash[:alert])
    assert_response :redirect
  end

  # ---------------------------------------------------------------------------
  # list_artifact_versions SPARQL file validations
  # ---------------------------------------------------------------------------

  test "list_artifact_versions SPARQL file should exist" do
    assert File.exist?(Rails.root.join("app/services/sparqls/artifact_controller/list_artifact_versions.sparql")),
           "list_artifact_versions.sparql file is missing"
  end

  test "list_artifact_versions SPARQL should contain the ARTIFACT_URI placeholder" do
    sparql = File.read(Rails.root.join("app/services/sparqls/artifact_controller/list_artifact_versions.sparql"))
    assert_includes sparql, "ARTIFACT_URI",
                    "list_artifact_versions.sparql is missing the ARTIFACT_URI placeholder"
  end

  test "list_artifact_versions SPARQL should be syntactically valid after substitution" do
    sparql = SparqlLoader.load(
      "artifact_controller/list_artifact_versions",
      ["ARTIFACT_URI", "http://kg.artsdata.ca/databus/testaccount/group/artifact"]
    )
    assert_nothing_raised do
      SPARQL::Grammar.parse(sparql)
    end
  end

  # ---------------------------------------------------------------------------
  # destroy action
  # ---------------------------------------------------------------------------

  test "destroy should redirect to artifact index and set notice on success" do
    mock_databus = mock('databus_service')
    mock_databus.stubs(:delete_artifact).returns(true)
    DatabusService.stubs(:new).returns(mock_databus)
    @mock_update_client.stubs(:update)

    delete artifact_path(id: 'placeholder'), params: {
      artifactUri: "http://kg.artsdata.ca/databus/testaccount/group/artifact",
      graph: "http://kg.artsdata.ca/testaccount/group/artifact"
    }

    assert_redirected_to artifact_index_path
    assert_match(/Deleted artifact/, flash[:notice])
  end

  test "destroy should redirect back with an alert when deletion fails" do
    mock_databus = mock('databus_service')
    mock_databus.stubs(:delete_artifact).returns(false)
    mock_databus.stubs(:errors).returns(["Delete failed"])
    DatabusService.stubs(:new).returns(mock_databus)

    delete artifact_path(id: 'placeholder'), params: {
      artifactUri: "http://kg.artsdata.ca/databus/testaccount/group/artifact",
      graph: "http://kg.artsdata.ca/testaccount/group/artifact"
    }

    assert_match(/Could not delete/, flash[:alert])
    assert_response :redirect
  end

  test "destroy should set an alert when given an invalid graph URI" do
    mock_databus = mock('databus_service')
    mock_databus.stubs(:delete_artifact).returns(true)
    DatabusService.stubs(:new).returns(mock_databus)

    delete artifact_path(id: 'placeholder'), params: {
      artifactUri: "http://kg.artsdata.ca/databus/testaccount/group/artifact",
      graph: "not-a-valid-uri"
    }

    assert_match(/Could not delete graph/, flash[:alert])
    assert_redirected_to artifact_index_path
  end
end
