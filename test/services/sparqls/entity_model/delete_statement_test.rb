require 'test_helper'

class DeleteStatementSparqlTest < ActiveSupport::TestCase
  GRAPH_NAME_URI = "http://kg.artsdata.ca/graph/test"
  SUBJECT_URI = "<http://kg.artsdata.ca/resource/K23-300>"
  PREDICATE_URI = "<http://schema.org/sameAs>"
  OBJECT_URI = "<http://www.wikidata.org/entity/Q123>"
  OBJECT_LITERAL = "\"Sample name\"@en"

  def load_sparql(object_ntriples: OBJECT_URI)
    SparqlLoader.load(
      "entity_model/delete_statement",
      [
        "GRAPH_NAME_URI_PLACEHOLDER", GRAPH_NAME_URI,
        "<SUBJECT_PLACEHOLDER>", SUBJECT_URI,
        "<PREDICATE_PLACEHOLDER>", PREDICATE_URI,
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

  test "removes the reverse triple and its RDF-star annotation" do
    assert @repository.has_statement?(RDF::Statement(@object, @predicate, @subject, graph_name: @graph_uri))

    execute_delete_statement

    refute @repository.has_statement?(RDF::Statement(@object, @predicate, @subject, graph_name: @graph_uri))
    refute @repository.has_statement?(RDF::Statement(RDF::Statement(@object, @predicate, @subject), RDF::URI("http://ann/recordedBy"), @reverse_bnode, graph_name: @graph_uri))
    refute @repository.has_statement?(RDF::Statement(@reverse_bnode, RDF::URI("http://ann/date"), RDF::Literal("2024-01-02"), graph_name: @graph_uri))
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
