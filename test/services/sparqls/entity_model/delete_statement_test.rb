require 'test_helper'

class DeleteStatementSparqlTest < ActiveSupport::TestCase
  GRAPH_NAME_URI = "http://kg.artsdata.ca/graph/test"
  SUBJECT_URI = "<http://kg.artsdata.ca/resource/K23-300>"
  PREDICATE_URI = "<http://schema.org/sameAs>"
  OBJECT_URI = "<http://www.wikidata.org/entity/Q123>"
  OBJECT_LITERAL = "\"Sample name\"@en"

  def load_sparql(object_ntriples: OBJECT_URI, subject_ntriples: SUBJECT_URI, predicate_ntriples: PREDICATE_URI, path_where: "")
    SparqlLoader.load(
      "entity_model/delete_statement",
      [
        "GRAPH_NAME_URI_PLACEHOLDER", GRAPH_NAME_URI,
        "# PATH_WHERE_PLACEHOLDER", path_where,
        "<SUBJECT_PLACEHOLDER>", subject_ntriples,
        "<PREDICATE_PLACEHOLDER>", predicate_ntriples,
        "# OBJECT_CASCADE_DELETE_PLACEHOLDER", "",
        "# OBJECT_CASCADE_WHERE_PLACEHOLDER", "",
        "?OBJECT_PLACEHOLDER", object_ntriples
      ]
    )
  end

  test "substitutes all placeholders" do
    sparql = load_sparql

    refute_match(/GRAPH_NAME_URI_PLACEHOLDER/, sparql)
    refute_match(/SUBJECT_PLACEHOLDER/, sparql)
    refute_match(/PREDICATE_PLACEHOLDER/, sparql)
    refute_match(/OBJECT_PLACEHOLDER/, sparql)
  end


  # --- Execution against real RDF data ---

  def setup
    @graph_uri = RDF::URI(GRAPH_NAME_URI)
    @subject = RDF::URI("http://kg.artsdata.ca/resource/K23-300")
    @predicate = RDF::URI("http://schema.org/sameAs")
    @object = RDF::URI("http://www.wikidata.org/entity/Q123")

    @repository = RDF::Repository.new

    # the statement targeted for deletion
    @repository.insert(RDF::Statement(@subject, @predicate, @object, graph_name: @graph_uri))

    # forward RDF-star annotation, with a blank node value carrying its own properties
    @forward_bnode = RDF::Node.new
    @repository.insert(RDF::Statement(RDF::Statement(@subject, @predicate, @object), RDF::URI("http://ann/recordedBy"), @forward_bnode, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@forward_bnode, RDF::URI("http://ann/date"), RDF::Literal("2024-01-01"), graph_name: @graph_uri))

    # the reverse statement and its own RDF-star annotation (also a blank node value)
    @repository.insert(RDF::Statement(@object, @predicate, @subject, graph_name: @graph_uri))
    @reverse_bnode = RDF::Node.new
    @repository.insert(RDF::Statement(RDF::Statement(@object, @predicate, @subject), RDF::URI("http://ann/recordedBy"), @reverse_bnode, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@reverse_bnode, RDF::URI("http://ann/date"), RDF::Literal("2024-01-02"), graph_name: @graph_uri))

    # unrelated statement that must survive the delete
    @unrelated = RDF::Statement(@subject, RDF::URI("http://schema.org/name"), RDF::Literal("Keep me"), graph_name: @graph_uri)
    @repository.insert(@unrelated)
  end

  def execute_delete_statement
    sparql = load_sparql
    SPARQL::Grammar.parse(sparql, update: true).execute(@repository)
  end

  test "removes the direct triple from the repository" do
    assert @repository.has_statement?(RDF::Statement(@subject, @predicate, @object, graph_name: @graph_uri))

    execute_delete_statement

    refute @repository.has_statement?(RDF::Statement(@subject, @predicate, @object, graph_name: @graph_uri))
  end

  test "removes the forward RDF-star annotation and its blank node's own properties" do
    execute_delete_statement

    refute @repository.has_statement?(RDF::Statement(RDF::Statement(@subject, @predicate, @object), RDF::URI("http://ann/recordedBy"), @forward_bnode, graph_name: @graph_uri))
    refute @repository.has_statement?(RDF::Statement(@forward_bnode, RDF::URI("http://ann/date"), RDF::Literal("2024-01-01"), graph_name: @graph_uri))
  end

  test "leaves unrelated statements untouched" do
    execute_delete_statement

    assert @repository.has_statement?(@unrelated)
  end

  test "does not delete anything when no matching triple exists in that named graph" do
    other_graph_repository = RDF::Repository.new
    other_graph_repository.insert(RDF::Statement(@subject, @predicate, @object, graph_name: RDF::URI("http://kg.artsdata.ca/graph/other")))
    @repository = other_graph_repository

    execute_delete_statement

    assert_equal 1, @repository.count
  end
end

# A blank-node subject can't be referenced by its N-Triples label across requests (GraphDB
# assigns it a fresh, unrelated identity each time), so it must be re-bound via the join path
# that reaches it from a real subject instead. These tests exercise that resolved-path shape.
class DeleteStatementWithBlankNodePathSparqlTest < ActiveSupport::TestCase
  GRAPH_NAME_URI = "http://kg.artsdata.ca/graph/test"

  def setup
    @graph_uri = RDF::URI(GRAPH_NAME_URI)
    @subject = RDF::URI("http://kg.artsdata.ca/resource/K23-300")
    @address_predicate = RDF::URI("http://schema.org/address")
    @postal_code_predicate = RDF::URI("http://schema.org/postalCode")

    @repository = RDF::Repository.new

    # the blank node targeted for deletion, reached via one hop from a real subject
    @address = RDF::Node.new
    @repository.insert(RDF::Statement(@subject, @address_predicate, @address, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@address, @postal_code_predicate, RDF::Literal("H2X 1Y2"), graph_name: @graph_uri))

    # a sibling blank node under the same subject/predicate, with a different value, that
    # must survive: disambiguation must rely on the specific (predicate, object) being
    # deleted, not just "any blank node reachable via schema:address"
    @other_address = RDF::Node.new
    @repository.insert(RDF::Statement(@subject, @address_predicate, @other_address, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@other_address, @postal_code_predicate, RDF::Literal("H3B 2Y5"), graph_name: @graph_uri))
  end

  def execute_delete_via_path(path_where:, subject_ntriples: "?bnode_path_0", predicate_ntriples: "<http://schema.org/postalCode>", object_ntriples: "\"H2X 1Y2\"")
    sparql = SparqlLoader.load(
      "entity_model/delete_statement",
      [
        "GRAPH_NAME_URI_PLACEHOLDER", GRAPH_NAME_URI,
        "# PATH_WHERE_PLACEHOLDER", path_where,
        "<SUBJECT_PLACEHOLDER>", subject_ntriples,
        "<PREDICATE_PLACEHOLDER>", predicate_ntriples,
        "# OBJECT_CASCADE_DELETE_PLACEHOLDER", "",
        "# OBJECT_CASCADE_WHERE_PLACEHOLDER", "",
        "?OBJECT_PLACEHOLDER", object_ntriples
      ]
    )
    SPARQL::Grammar.parse(sparql, update: true).execute(@repository)
  end

  test "removes a 1-hop blank-node property resolved via the join path" do
    execute_delete_via_path(path_where: "<http://kg.artsdata.ca/resource/K23-300> <http://schema.org/address> ?bnode_path_0 .")

    refute @repository.has_statement?(RDF::Statement(@address, @postal_code_predicate, RDF::Literal("H2X 1Y2"), graph_name: @graph_uri))
  end

  test "leaves a sibling blank node with a different value untouched" do
    execute_delete_via_path(path_where: "<http://kg.artsdata.ca/resource/K23-300> <http://schema.org/address> ?bnode_path_0 .")

    assert @repository.has_statement?(RDF::Statement(@other_address, @postal_code_predicate, RDF::Literal("H3B 2Y5"), graph_name: @graph_uri))
  end

  test "removes a 2-hop nested blank-node property resolved via the join path" do
    geo = RDF::Node.new
    @repository.insert(RDF::Statement(@address, RDF::URI("http://schema.org/geo"), geo, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(geo, RDF::URI("http://schema.org/latitude"), RDF::Literal("45.5"), graph_name: @graph_uri))

    path_where = "<http://kg.artsdata.ca/resource/K23-300> <http://schema.org/address> ?bnode_path_0 .\n?bnode_path_0 <http://schema.org/geo> ?bnode_path_1 ."
    execute_delete_via_path(
      path_where: path_where,
      subject_ntriples: "?bnode_path_1",
      predicate_ntriples: "<http://schema.org/latitude>",
      object_ntriples: "\"45.5\""
    )

    refute @repository.has_statement?(RDF::Statement(geo, RDF::URI("http://schema.org/latitude"), RDF::Literal("45.5"), graph_name: @graph_uri))
  end
end

# A blank-node object has the same unreferenceable-label problem as a blank-node subject. Since
# it's bound directly by (subject, predicate) rather than via a join path, it's left as a real
# SPARQL variable and its own direct properties are cascade-deleted so the edit doesn't leave
# an orphaned, unreachable blank node behind.
class DeleteStatementWithBlankNodeObjectSparqlTest < ActiveSupport::TestCase
  GRAPH_NAME_URI = "http://kg.artsdata.ca/graph/test"

  def setup
    @graph_uri = RDF::URI(GRAPH_NAME_URI)
    @subject = RDF::URI("http://kg.artsdata.ca/resource/K23-300")
    @address_predicate = RDF::URI("http://schema.org/address")

    @repository = RDF::Repository.new

    @address = RDF::Node.new
    @repository.insert(RDF::Statement(@subject, @address_predicate, @address, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@address, RDF::URI("http://schema.org/postalCode"), RDF::Literal("H2X 1Y2"), graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@address, RDF::URI("http://schema.org/addressCountry"), RDF::Literal("CA"), graph_name: @graph_uri))

    # a real entity that's the object of another edge, and has its own data — must never be
    # cascade-deleted just because it's an object; only blank-node objects should cascade
    @sameas_subject = RDF::URI("http://kg.artsdata.ca/resource/K23-301")
    @sameas_object = RDF::URI("http://www.wikidata.org/entity/Q123")
    @repository.insert(RDF::Statement(@sameas_subject, RDF::URI("http://schema.org/sameAs"), @sameas_object, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@sameas_object, RDF::URI("http://schema.org/name"), RDF::Literal("Q123's own name"), graph_name: @graph_uri))

    @unrelated = RDF::Statement(@subject, RDF::URI("http://schema.org/name"), RDF::Literal("Keep me"), graph_name: @graph_uri)
    @repository.insert(@unrelated)
  end

  def execute_delete(subject_ntriples:, predicate_ntriples:, blank_object:)
    sparql = SparqlLoader.load(
      "entity_model/delete_statement",
      [
        "GRAPH_NAME_URI_PLACEHOLDER", GRAPH_NAME_URI,
        "# PATH_WHERE_PLACEHOLDER", "",
        "<SUBJECT_PLACEHOLDER>", subject_ntriples,
        "<PREDICATE_PLACEHOLDER>", predicate_ntriples,
        "# OBJECT_CASCADE_DELETE_PLACEHOLDER", blank_object ? "?OBJECT_PLACEHOLDER ?op ?oo ." : "",
        "# OBJECT_CASCADE_WHERE_PLACEHOLDER", blank_object ? "OPTIONAL { ?OBJECT_PLACEHOLDER ?op ?oo . }" : "",
        *(blank_object ? [] : ["?OBJECT_PLACEHOLDER", @sameas_object.to_ntriples])
      ]
    )
    SPARQL::Grammar.parse(sparql, update: true).execute(@repository)
  end

  test "removes the edge to the blank node and cascades its own direct properties" do
    execute_delete(subject_ntriples: @subject.to_ntriples, predicate_ntriples: @address_predicate.to_ntriples, blank_object: true)

    refute @repository.has_statement?(RDF::Statement(@subject, @address_predicate, @address, graph_name: @graph_uri))
    refute @repository.has_statement?(RDF::Statement(@address, RDF::URI("http://schema.org/postalCode"), RDF::Literal("H2X 1Y2"), graph_name: @graph_uri))
    refute @repository.has_statement?(RDF::Statement(@address, RDF::URI("http://schema.org/addressCountry"), RDF::Literal("CA"), graph_name: @graph_uri))
  end

  test "leaves unrelated statements untouched when the object is a blank node" do
    execute_delete(subject_ntriples: @subject.to_ntriples, predicate_ntriples: @address_predicate.to_ntriples, blank_object: true)

    assert @repository.has_statement?(@unrelated)
  end

  test "deleting an edge to a real entity never cascades into that entity's own data" do
    execute_delete(subject_ntriples: @sameas_subject.to_ntriples, predicate_ntriples: "<http://schema.org/sameAs>", blank_object: false)

    refute @repository.has_statement?(RDF::Statement(@sameas_subject, RDF::URI("http://schema.org/sameAs"), @sameas_object, graph_name: @graph_uri))
    assert @repository.has_statement?(RDF::Statement(@sameas_object, RDF::URI("http://schema.org/name"), RDF::Literal("Q123's own name"), graph_name: @graph_uri))
  end
end

# Both ends of the triple can be blank at once, e.g. deleting the edge from one nested blank
# node to another (K1 -> address -> [blank] -> geo -> [blank]): the subject needs the join-path
# resolution (root_subject/path_predicates) and the object needs the unbound-variable/cascade
# treatment, at the same time, in the same query. Exercised through Entity#delete_statement
# itself (not just the raw template) to catch any wiring bug between the two mechanisms.
class DeleteStatementWithBlankSubjectAndBlankObjectTest < ActiveSupport::TestCase
  GRAPH_NAME_URI = "http://kg.artsdata.ca/graph/test"

  def setup
    @graph_uri = RDF::URI(GRAPH_NAME_URI)
    @entity_uri = RDF::URI("http://kg.artsdata.ca/resource/K1")
    @address_predicate = RDF::URI("http://schema.org/address")
    @geo_predicate = RDF::URI("http://schema.org/geo")
    @lat_predicate = RDF::URI("http://schema.org/latitude")

    @repository = RDF::Repository.new
    @address = RDF::Node.new
    @geo = RDF::Node.new
    @repository.insert(RDF::Statement(@entity_uri, @address_predicate, @address, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@address, @geo_predicate, @geo, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@geo, @lat_predicate, RDF::Literal("45.5"), graph_name: @graph_uri))

    @entity = Entity.new(entity_uri: @entity_uri.to_s)
    repository = @repository
    @entity.define_singleton_method(:artsdata_update_client) do
      Struct.new(:repository) { def update(sparql) = SPARQL::Grammar.parse(sparql, update: true).execute(repository) || true }.new(repository)
    end
  end

  test "removes the edge between two blank nodes and cascades the object's own properties" do
    result = @entity.delete_statement(
      graph_name_uri: GRAPH_NAME_URI,
      subject: @address.to_ntriples,
      predicate: @geo_predicate.to_ntriples,
      object: @geo.to_ntriples,
      root_subject: @entity_uri.to_ntriples,
      path_predicates: [@address_predicate.to_ntriples]
    )

    assert result
    refute @repository.has_statement?(RDF::Statement(@address, @geo_predicate, @geo, graph_name: @graph_uri))
    refute @repository.has_statement?(RDF::Statement(@geo, @lat_predicate, RDF::Literal("45.5"), graph_name: @graph_uri))
    assert @repository.has_statement?(RDF::Statement(@entity_uri, @address_predicate, @address, graph_name: @graph_uri))
  end

  test "fails safely (does not delete) when the blank subject has no path" do
    result = @entity.delete_statement(
      graph_name_uri: GRAPH_NAME_URI,
      subject: @address.to_ntriples,
      predicate: @geo_predicate.to_ntriples,
      object: @geo.to_ntriples
    )

    refute result
    assert @repository.has_statement?(RDF::Statement(@address, @geo_predicate, @geo, graph_name: @graph_uri))
  end
end
