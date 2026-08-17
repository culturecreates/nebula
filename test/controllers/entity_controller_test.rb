require "test_helper"

class EntityControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Entity#artsdata_update_client memoizes on a class variable, so it must be
    # cleared between tests or a later test would reuse an earlier test's mock.
    Entity.send(:class_variable_set, :@@artsdata_update_client, nil) if Entity.class_variable_defined?(:@@artsdata_update_client)

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
        "<SUBJECT_PLACEHOLDER>", "<http://kg.artsdata.ca/resource/K23-300>",
        "<PREDICATE_PLACEHOLDER>", "<http://schema.org/name>",
        "<OBJECT_PLACEHOLDER>", "\"Sample name\"@en"
      ]
    )

    assert_nothing_raised do
      SPARQL::Grammar.parse(sparql, update: true)
    end
  end

  test "statement_objects partial should include conditional statement delete form" do
    partial = File.read(Rails.root.join("app/views/application/_statement_objects.html.erb"))
    assert_includes partial, "local_assigns[:graph_name_uri].present?"
    assert_includes partial, "local_assigns[:triple_inverted]"
    assert_includes partial, "delete_entity_statement_path"
    assert_includes partial, "submit->confirm#confirm"
  end

  test "update_statement_rank redirects with notice on success" do
    @mock_update_client.stubs(:update).returns(true)

    patch update_entity_statement_rank_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "http://kg.artsdata.ca/graph/test",
      base_subject_ntriples: "<http://kg.artsdata.ca/resource/K23-300>",
      base_predicate_ntriples: "<http://schema.org/name>",
      base_object_ntriples: "\"Sample name\"@en",
      old_predicate_ntriples: "<http://www.w3.org/ns/prov#wasDerivedFrom>",
      new_predicate_ntriples: "<http://www.w3.org/ns/prov#hadPrimarySource>",
      annotation_object_ntriples: "<http://kg.artsdata.ca/graph/source1>"
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Updated statement rank/, flash[:notice])
  end

  test "update_statement_rank redirects with alert on invalid graph uri" do
    @mock_update_client.expects(:update).never

    patch update_entity_statement_rank_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "javascript:alert(1)",
      base_subject_ntriples: "<http://kg.artsdata.ca/resource/K23-300>",
      base_predicate_ntriples: "<http://schema.org/name>",
      base_object_ntriples: "\"Sample name\"@en",
      old_predicate_ntriples: "<http://www.w3.org/ns/prov#wasDerivedFrom>",
      new_predicate_ntriples: "<http://www.w3.org/ns/prov#hadPrimarySource>",
      annotation_object_ntriples: "<http://kg.artsdata.ca/graph/source1>"
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Could not update statement rank/, flash[:alert])
  end

  test "update_statement_rank SPARQL should be syntactically valid after substitution" do
    sparql = SparqlLoader.load(
      "entity_model/update_statement_rank",
      [
        "GRAPH_NAME_URI_PLACEHOLDER", "http://kg.artsdata.ca/graph/test",
        "<BASE_SUBJECT_PLACEHOLDER>", "<http://kg.artsdata.ca/resource/K23-300>",
        "<BASE_PREDICATE_PLACEHOLDER>", "<http://schema.org/name>",
        "<BASE_OBJECT_PLACEHOLDER>", "\"Sample name\"@en",
        "<OLD_PREDICATE_PLACEHOLDER>", "<http://www.w3.org/ns/prov#wasDerivedFrom>",
        "<NEW_PREDICATE_PLACEHOLDER>", "<http://www.w3.org/ns/prov#hadPrimarySource>",
        "<ANNOTATION_OBJECT_PLACEHOLDER>", "<http://kg.artsdata.ca/graph/source1>"
      ]
    )

    assert_nothing_raised do
      SPARQL::Grammar.parse(sparql, update: true)
    end
  end

  test "annotations partial should include conditional rank and delete menu" do
    partial = File.read(Rails.root.join("app/views/application/_annotations.html.erb"))
    assert_includes partial, "local_assigns[:graph_name_uri].present?"
    assert_includes partial, "update_entity_statement_rank_path"
    assert_includes partial, "delete_entity_statement_path"
    assert_includes partial, "Normal rank"
    assert_includes partial, "Primary rank"
    assert_includes partial, "fa-ellipsis-vertical"
    assert_includes partial, "annotation-menu-toggle"
    assert_includes partial, "annotation-menu"
    assert_includes partial, 'data-bs-popper-config=\'{"strategy": "fixed"}\''
  end
end
