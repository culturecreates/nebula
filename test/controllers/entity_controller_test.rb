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
        "# PATH_WHERE_PLACEHOLDER", "",
        "<SUBJECT_PLACEHOLDER>", "<http://kg.artsdata.ca/resource/K23-300>",
        "<PREDICATE_PLACEHOLDER>", "<http://schema.org/name>",
        "# OBJECT_CASCADE_DELETE_PLACEHOLDER", "",
        "# OBJECT_CASCADE_WHERE_PLACEHOLDER", "",
        "?OBJECT_PLACEHOLDER", "\"Sample name\"@en"
      ]
    )

    assert_nothing_raised do
      SPARQL::Grammar.parse(sparql, update: true)
    end
  end

  test "delete_statement redirects with notice when subject is a blank node resolved via a path" do
    @mock_update_client.stubs(:update).returns(true)

    delete delete_entity_statement_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "http://kg.artsdata.ca/graph/test",
      subject_ntriples: "_:b0",
      predicate_ntriples: "<http://schema.org/postalCode>",
      object_ntriples: "\"H2X 1Y2\"",
      root_subject_ntriples: "<http://kg.artsdata.ca/resource/K23-300>",
      path_predicates: ["<http://schema.org/address>"]
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Deleted statement/, flash[:notice])
  end

  test "delete_statement redirects with alert when subject is a blank node without a path" do
    @mock_update_client.expects(:update).never

    delete delete_entity_statement_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "http://kg.artsdata.ca/graph/test",
      subject_ntriples: "_:b0",
      predicate_ntriples: "<http://schema.org/postalCode>",
      object_ntriples: "\"H2X 1Y2\""
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Could not delete statement/, flash[:alert])
  end

  test "delete_statement redirects with notice when object is a blank node" do
    @mock_update_client.stubs(:update).returns(true)

    delete delete_entity_statement_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "http://kg.artsdata.ca/graph/test",
      subject_ntriples: "<http://kg.artsdata.ca/resource/K23-300>",
      predicate_ntriples: "<http://schema.org/address>",
      object_ntriples: "_:b0"
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Deleted statement/, flash[:notice])
  end

  test "delete_statement redirects with notice when both subject and object are blank nodes" do
    @mock_update_client.stubs(:update).returns(true)

    delete delete_entity_statement_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "http://kg.artsdata.ca/graph/test",
      subject_ntriples: "_:b0",
      predicate_ntriples: "<http://schema.org/geo>",
      object_ntriples: "_:b1",
      root_subject_ntriples: "<http://kg.artsdata.ca/resource/K23-300>",
      path_predicates: ["<http://schema.org/address>"]
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Deleted statement/, flash[:notice])
  end

  test "statement_objects partial should include conditional statement delete form" do
    partial = File.read(Rails.root.join("app/views/application/_statement_objects.html.erb"))
    assert_includes partial, "local_assigns[:graph_name_uri].present?"
    assert_includes partial, "local_assigns[:triple_inverted]"
    assert_includes partial, "delete_entity_statement_path"
    assert_includes partial, "submit->confirm#confirm"
    assert_includes partial, "triple.subject.node?"
    assert_includes partial, "root_subject_ntriples"
    assert_includes partial, "path_predicates[]"
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
        "# PATH_WHERE_PLACEHOLDER", "",
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

  test "update_statement_rank redirects with notice when base subject is a blank node resolved via a path" do
    @mock_update_client.stubs(:update).returns(true)

    patch update_entity_statement_rank_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "http://kg.artsdata.ca/graph/test",
      base_subject_ntriples: "_:b0",
      base_predicate_ntriples: "<http://schema.org/postalCode>",
      base_object_ntriples: "\"H2X 1Y2\"",
      old_predicate_ntriples: "<http://www.w3.org/ns/prov#wasDerivedFrom>",
      new_predicate_ntriples: "<http://www.w3.org/ns/prov#hadPrimarySource>",
      annotation_object_ntriples: "<http://kg.artsdata.ca/graph/source1>",
      root_subject_ntriples: "<http://kg.artsdata.ca/resource/K23-300>",
      path_predicates: ["<http://schema.org/address>"]
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Updated statement rank/, flash[:notice])
  end

  test "update_statement_rank redirects with alert when base subject is a blank node without a path" do
    @mock_update_client.expects(:update).never

    patch update_entity_statement_rank_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "http://kg.artsdata.ca/graph/test",
      base_subject_ntriples: "_:b0",
      base_predicate_ntriples: "<http://schema.org/postalCode>",
      base_object_ntriples: "\"H2X 1Y2\"",
      old_predicate_ntriples: "<http://www.w3.org/ns/prov#wasDerivedFrom>",
      new_predicate_ntriples: "<http://www.w3.org/ns/prov#hadPrimarySource>",
      annotation_object_ntriples: "<http://kg.artsdata.ca/graph/source1>"
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Could not update statement rank/, flash[:alert])
  end

  test "update_statement_rank redirects with notice when base object is a blank node" do
    @mock_update_client.stubs(:update).returns(true)

    patch update_entity_statement_rank_path, params: {
      entity_uri: "http://kg.artsdata.ca/resource/K23-300",
      graph_name_uri: "http://kg.artsdata.ca/graph/test",
      base_subject_ntriples: "<http://kg.artsdata.ca/resource/K23-300>",
      base_predicate_ntriples: "<http://schema.org/address>",
      base_object_ntriples: "_:b0",
      old_predicate_ntriples: "<http://www.w3.org/ns/prov#wasDerivedFrom>",
      new_predicate_ntriples: "<http://www.w3.org/ns/prov#hadPrimarySource>",
      annotation_object_ntriples: "<http://kg.artsdata.ca/graph/source1>"
    }

    assert_redirected_to entity_path(uri: "http://kg.artsdata.ca/resource/K23-300")
    assert_match(/Updated statement rank/, flash[:notice])
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
    assert_includes partial, "true_base_subject.node?"
    assert_includes partial, "root_subject_ntriples"
    assert_includes partial, "path_predicates[]"
    assert_includes partial, "annotations_editable"
    assert_includes partial, "local_assigns[:triple_inverted]"
    assert_includes partial, "true_base_subject"
    assert_includes partial, "true_base_object"
  end

  # Mirrors app/views/entity/authorized_external_identifiers.html.erb and
  # load_authorized_external_identifiers.sparql: the WHERE clause matches the true stored
  # direction (?s schema:sameAs ?o), but the CONSTRUCT swaps it to (entity schema:sameAs
  # external) for display, and swaps the annotation's own reified subject to match. The
  # first-level annotation itself (e.g. wasDerivedFrom) must still be deletable there — its
  # delete form must target the TRUE (un-swapped) base subject/object, not the displayed one.
  test "annotation delete under a triple_inverted view targets the true (un-swapped) reified subject" do
    graph_uri = RDF::URI("http://kg.artsdata.ca/core")
    entity_uri = RDF::URI("http://kg.artsdata.ca/resource/K23-300")
    external_uri = RDF::URI("http://www.wikidata.org/entity/Q1")
    same_as = RDF::URI("http://schema.org/sameAs")
    was_derived_from = RDF::URI("http://www.w3.org/ns/prov#wasDerivedFrom")
    source = RDF::URI("http://kg.artsdata.ca/graph/source1")

    # the REAL data as actually stored in GraphDB (true direction: external sameAs entity)
    real_repository = RDF::Repository.new
    real_base_statement = RDF::Statement(external_uri, same_as, entity_uri)
    real_repository.insert(RDF::Statement(external_uri, same_as, entity_uri, graph_name: graph_uri))
    real_repository.insert(RDF::Statement(real_base_statement, was_derived_from, source, graph_name: graph_uri))

    # the LOCAL in-memory graph as CONSTRUCTed for display: swapped to entity-as-subject
    local_graph = RDF::Graph.new
    swapped_base_statement = RDF::Statement(entity_uri, same_as, external_uri)
    local_graph << RDF::Statement(entity_uri, same_as, external_uri)
    local_graph << RDF::Statement(swapped_base_statement, was_derived_from, source)

    entity = Entity.new(entity_uri: entity_uri.to_s)
    entity.graph = local_graph

    html = ApplicationController.render(
      partial: "application/statement_objects",
      locals: {
        triples: local_graph.query([entity_uri, nil, nil]),
        graph: local_graph,
        graph_name_uri: graph_uri.to_s,
        triple_inverted: true,
      },
      assigns: { entity: entity }
    )

    assert_includes html, "annotation-menu-toggle"

    annotation_delete_form = html.scan(/<form.*?<\/form>/m).find { |f| f.include?("Delete this annotation?") }
    assert annotation_delete_form, "expected the annotation's own delete form to be present"

    extract = ->(name) {
      match = annotation_delete_form.match(/name="#{name}"[^>]*value="([^"]*)"/)
      match && CGI.unescapeHTML(match[1])
    }

    # the true, un-swapped base subject/object: external as subject, entity as object
    assert_equal external_uri.to_ntriples, extract.call("subject_ntriples")
    assert_equal entity_uri.to_ntriples, extract.call("base_object_ntriples")

    entity.define_singleton_method(:artsdata_update_client) do
      Struct.new(:repository) { def update(sparql) = SPARQL::Grammar.parse(sparql, update: true).execute(repository) || true }.new(real_repository)
    end

    result = entity.delete_statement(
      graph_name_uri: graph_uri.to_s,
      subject: extract.call("subject_ntriples"),
      predicate: extract.call("predicate_ntriples"),
      object: extract.call("object_ntriples"),
      base_predicate: extract.call("base_predicate_ntriples"),
      base_object: extract.call("base_object_ntriples")
    )

    assert result
    refute real_repository.has_statement?(RDF::Statement(real_base_statement, was_derived_from, source, graph_name: graph_uri))
    assert real_repository.has_statement?(RDF::Statement(external_uri, same_as, entity_uri, graph_name: graph_uri))
  end

  test "delete icon for a nested annotation-value property stays enabled and forwards even when the containing view is triple_inverted" do
    graph_uri = RDF::URI("http://kg.artsdata.ca/graph/test")
    subject = RDF::URI("http://kg.artsdata.ca/resource/K23-300")
    predicate = RDF::URI("http://schema.org/sameAs")
    object = RDF::URI("http://www.wikidata.org/entity/Q1")

    graph = RDF::Graph.new
    graph << RDF::Statement(subject, predicate, object)
    base_statement = RDF::Statement(subject, predicate, object)

    # an annotation whose own value is a blank node with its own nested property, e.g.
    # <<subject sameAs object>> ann:recordedBy [ ann:date "2024-01-01" ]
    recorded_by = RDF::Node.new
    graph << RDF::Statement(base_statement, RDF::URI("http://ann/recordedBy"), recorded_by)
    graph << RDF::Statement(recorded_by, RDF::URI("http://ann/date"), RDF::Literal("2024-01-01"))

    entity = Entity.new(entity_uri: subject.to_s)
    entity.graph = graph

    html = ApplicationController.render(
      partial: "application/statement_objects",
      locals: {
        triples: graph.query([subject, nil, nil]),
        graph: graph,
        graph_name_uri: graph_uri.to_s,
        triple_inverted: true,
      },
      assigns: { entity: entity }
    )

    # the annotation's own action menu is now also enabled (see the test above)...
    assert_includes html, "annotation-menu-toggle"
    # ...and the nested blank-node property's delete form must still be present and forward
    assert_includes html, "http://ann/date"
    assert_match(/subject_ntriples.*value="_:/, html)
    assert_match(/name="triple_inverted".*value="false"/, html)
  end

  # Mirrors app/views/entity/authorized_external_identifiers.html.erb and
  # load_authorized_external_identifiers.sparql: the WHERE clause matches the true stored
  # direction (?s schema:sameAs ?o), but the CONSTRUCT swaps it to (entity schema:sameAs
  # external) for display, and swaps the annotation's own reified subject to match. A nested
  # annotation-value property (e.g. ann:recordedBy [ ann:date "..." ]) reuses the same blank
  # node either way, so its delete form's root_subject_ntriples must be rebuilt from the TRUE
  # (un-swapped) direction, or it won't match anything in the real graph.
  test "delete for a nested annotation-value property under a triple_inverted view targets the true (un-swapped) reified subject" do
    graph_uri = RDF::URI("http://kg.artsdata.ca/core")
    entity_uri = RDF::URI("http://kg.artsdata.ca/resource/K23-300")
    external_uri = RDF::URI("http://www.wikidata.org/entity/Q1")
    same_as = RDF::URI("http://schema.org/sameAs")
    recorded_by = RDF::URI("http://ann/recordedBy")
    date_predicate = RDF::URI("http://ann/date")

    # the REAL data as actually stored in GraphDB (true direction: external sameAs entity)
    real_repository = RDF::Repository.new
    recorded_by_bnode = RDF::Node.new
    real_base_statement = RDF::Statement(external_uri, same_as, entity_uri)
    real_repository.insert(RDF::Statement(external_uri, same_as, entity_uri, graph_name: graph_uri))
    real_repository.insert(RDF::Statement(real_base_statement, recorded_by, recorded_by_bnode, graph_name: graph_uri))
    real_repository.insert(RDF::Statement(recorded_by_bnode, date_predicate, RDF::Literal("2024-01-01"), graph_name: graph_uri))

    # the LOCAL in-memory graph as CONSTRUCTed for display: swapped to entity-as-subject, the
    # nested blank node is reused as-is (it's never part of the swap)
    local_graph = RDF::Graph.new
    swapped_base_statement = RDF::Statement(entity_uri, same_as, external_uri)
    local_graph << RDF::Statement(entity_uri, same_as, external_uri)
    local_graph << RDF::Statement(swapped_base_statement, recorded_by, recorded_by_bnode)
    local_graph << RDF::Statement(recorded_by_bnode, date_predicate, RDF::Literal("2024-01-01"))

    entity = Entity.new(entity_uri: entity_uri.to_s)
    entity.graph = local_graph

    html = ApplicationController.render(
      partial: "application/statement_objects",
      locals: {
        triples: local_graph.query([entity_uri, nil, nil]),
        graph: local_graph,
        graph_name_uri: graph_uri.to_s,
        triple_inverted: true,
      },
      assigns: { entity: entity }
    )

    nested_form = html.scan(/<form.*?<\/form>/m).find { |f| f.include?("root_subject_ntriples") }
    assert nested_form, "expected a delete form with root_subject_ntriples for the nested property"

    extract = ->(name) {
      match = nested_form.match(/name="#{name}"[^>]*value="([^"]*)"/)
      match && CGI.unescapeHTML(match[1])
    }

    # the true, un-swapped reified subject: <<external sameAs entity>>, not <<entity sameAs external>>
    assert_equal "<<#{external_uri.to_ntriples} #{same_as.to_ntriples} #{entity_uri.to_ntriples}>>", extract.call("root_subject_ntriples")

    entity.define_singleton_method(:artsdata_update_client) do
      Struct.new(:repository) { def update(sparql) = SPARQL::Grammar.parse(sparql, update: true).execute(repository) || true }.new(real_repository)
    end

    result = entity.delete_statement(
      graph_name_uri: graph_uri.to_s,
      subject: extract.call("subject_ntriples"),
      predicate: extract.call("predicate_ntriples"),
      object: extract.call("object_ntriples"),
      triple_inverted: extract.call("triple_inverted"),
      root_subject: extract.call("root_subject_ntriples"),
      path_predicates: nested_form.scan(/name="path_predicates\[\]"[^>]*value="([^"]*)"/).flatten.map { |v| CGI.unescapeHTML(v) }
    )

    assert result
    refute real_repository.has_statement?(RDF::Statement(recorded_by_bnode, date_predicate, RDF::Literal("2024-01-01"), graph_name: graph_uri))
    assert real_repository.has_statement?(RDF::Statement(real_base_statement, recorded_by, recorded_by_bnode, graph_name: graph_uri))
    assert real_repository.has_statement?(RDF::Statement(external_uri, same_as, entity_uri, graph_name: graph_uri))
  end

  test "a prov:wasGeneratedBy annotation object renders as a dereference card, not plain text" do
    subject = RDF::URI("http://kg.artsdata.ca/resource/K23-300")
    predicate = RDF::URI("http://schema.org/name")
    object = RDF::Literal("Sample")
    activity = RDF::URI("http://kg.artsdata.ca/activity/A1")

    graph = RDF::Graph.new
    graph << RDF::Statement(subject, predicate, object)
    base_statement = RDF::Statement(subject, predicate, object)
    graph << RDF::Statement(base_statement, RDF::URI("http://www.w3.org/ns/prov#wasGeneratedBy"), activity)

    entity = Entity.new(entity_uri: subject.to_s)
    entity.graph = graph

    html = ApplicationController.render(
      partial: "application/statement_objects",
      locals: {
        triples: graph.query([subject, nil, nil]),
        graph: graph,
        graph_name_uri: "http://kg.artsdata.ca/graph/test",
      },
      assigns: { entity: entity }
    )

    assert_includes html, "/dereference/card?"
    assert_includes html, CGI.escape(activity.to_s)
  end

  test "annotations partial should dereference prov:wasGeneratedBy annotation objects" do
    partial = File.read(Rails.root.join("app/views/application/_annotations.html.erb"))
    assert_includes partial, "http://www.w3.org/ns/prov#wasGeneratedBy"
    assert_includes partial, "was_generated_by"
    assert_includes partial, "dereference_card_path"
    assert_includes partial, "auto_dereference"
  end
end
