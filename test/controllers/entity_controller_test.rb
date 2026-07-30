require "test_helper"

class EntityControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mock_update_client = mock("sparql_update_client")
    ArtsdataGraph::SparqlService.stubs(:update_client).returns(@mock_update_client)
    EntityController.any_instance.stubs(:session).returns(
      { "teams" => [{ "10808270" => "Artsdata Admins" }] }.with_indifferent_access
    )
  end

  test "delete_statement redirects with notice on success" do
    @mock_update_client.stubs(:update).returns(true)

    delete delete_entity_statement_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "http://kg.artsdata.ca/graph/test",
      subject_ntriples: "<http://kg.artsdata.ca/resource/K23-300>",
      predicate_ntriples: "<http://schema.org/name>",
      object_ntriples: "\"Sample name\"@en"
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Deleted statement/, flash[:notice])
  end

  test "delete_statement redirects with alert on invalid graph uri" do
    @mock_update_client.expects(:update).never

    delete delete_entity_statement_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "javascript:alert(1)",
      subject_ntriples: "<http://kg.artsdata.ca/resource/K23-300>",
      predicate_ntriples: "<http://schema.org/name>",
      object_ntriples: "\"Sample name\"@en"
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Could not delete statement/, flash[:alert])
  end

  test "delete_statement SPARQL should be syntactically valid after substitution" do
    sparql = SparqlLoader.load(
      "entity_model/delete_statement",
      [
        "GRAPH_NAME_URI_PLACEHOLDER", "http://kg.artsdata.ca/graph/test",
        "SUBJECT_PLACEHOLDER", "<http://kg.artsdata.ca/resource/K23-300>",
        "PREDICATE_PLACEHOLDER", "<http://schema.org/name>",
        "OBJECT_PLACEHOLDER", "\"Sample name\"@en"
      ]
    )

    assert_nothing_raised do
      SPARQL::Grammar.parse(sparql, update: true)
    end
  end

  test "statement_objects partial should include conditional statement delete form" do
    partial = File.read(Rails.root.join("app/views/application/_statement_objects.html.erb"))
    assert_includes partial, "local_assigns[:graph_name_uri].present?"
    assert_includes partial, "delete_entity_statement_path"
    assert_includes partial, "submit->confirm#confirm"
  end
end
