require 'test_helper'

class UpdateStatementRankSparqlTest < ActiveSupport::TestCase
  GRAPH_NAME_URI = "http://kg.artsdata.ca/graph/test"
  BASE_SUBJECT_URI = "<http://kg.artsdata.ca/resource/K23-300>"
  BASE_PREDICATE_URI = "<http://schema.org/address>"
  BASE_OBJECT_LITERAL = "\"123 Main St\""
  OLD_PREDICATE_URI = "<http://www.w3.org/ns/prov#wasDerivedFrom>"
  NEW_PREDICATE_URI = "<http://www.w3.org/ns/prov#hadPrimarySource>"
  ANNOTATION_OBJECT_URI = "<http://kg.artsdata.ca/graph/source1>"

  def load_sparql(base_object_ntriples: BASE_OBJECT_LITERAL, path_where: "")
    SparqlLoader.load(
      "entity_model/update_statement_rank",
      [
        "GRAPH_NAME_URI_PLACEHOLDER", GRAPH_NAME_URI,
        "# PATH_WHERE_PLACEHOLDER", path_where,
        "<BASE_SUBJECT_PLACEHOLDER>", BASE_SUBJECT_URI,
        "<BASE_PREDICATE_PLACEHOLDER>", BASE_PREDICATE_URI,
        "?BASE_OBJECT_PLACEHOLDER", base_object_ntriples,
        "<OLD_PREDICATE_PLACEHOLDER>", OLD_PREDICATE_URI,
        "<NEW_PREDICATE_PLACEHOLDER>", NEW_PREDICATE_URI,
        "?ANNOTATION_OBJECT_PLACEHOLDER", ANNOTATION_OBJECT_URI
      ]
    )
  end

  test "substitutes all placeholders" do
    sparql = load_sparql

    refute_match(/GRAPH_NAME_URI_PLACEHOLDER/, sparql)
    refute_match(/BASE_SUBJECT_PLACEHOLDER/, sparql)
    refute_match(/BASE_PREDICATE_PLACEHOLDER/, sparql)
    refute_match(/BASE_OBJECT_PLACEHOLDER/, sparql)
    refute_match(/OLD_PREDICATE_PLACEHOLDER/, sparql)
    refute_match(/NEW_PREDICATE_PLACEHOLDER/, sparql)
    refute_match(/ANNOTATION_OBJECT_PLACEHOLDER/, sparql)
  end

  # --- Execution against real RDF data ---

  def setup
    @graph_uri = RDF::URI(GRAPH_NAME_URI)
    @base_subject = RDF::URI("http://kg.artsdata.ca/resource/K23-300")
    @base_predicate = RDF::URI("http://schema.org/address")
    @base_object = RDF::Literal("123 Main St")
    @old_predicate = RDF::URI("http://www.w3.org/ns/prov#wasDerivedFrom")
    @new_predicate = RDF::URI("http://www.w3.org/ns/prov#hadPrimarySource")
    @annotation_object = RDF::URI("http://kg.artsdata.ca/graph/source1")

    @repository = RDF::Repository.new
    @base_statement = RDF::Statement(@base_subject, @base_predicate, @base_object)
    @repository.insert(RDF::Statement(@base_statement, @old_predicate, @annotation_object, graph_name: @graph_uri))
  end

  def execute_update_statement_rank
    sparql = load_sparql
    SPARQL::Grammar.parse(sparql, update: true).execute(@repository)
  end

  test "removes the old-rank annotation and inserts the new-rank annotation" do
    execute_update_statement_rank

    refute @repository.has_statement?(RDF::Statement(@base_statement, @old_predicate, @annotation_object, graph_name: @graph_uri))
    assert @repository.has_statement?(RDF::Statement(@base_statement, @new_predicate, @annotation_object, graph_name: @graph_uri))
  end
end

# A blank-node base_object (the annotated statement's object) has the same
# unreferenceable-label problem as a blank-node base_subject or delete_statement's object:
# GraphDB assigns it a fresh identity on every request, so it must be left as a bound SPARQL
# variable instead of substituted by its N-Triples label.
class UpdateStatementRankWithBlankNodeObjectSparqlTest < ActiveSupport::TestCase
  GRAPH_NAME_URI = "http://kg.artsdata.ca/graph/test"

  def setup
    @graph_uri = RDF::URI(GRAPH_NAME_URI)
    @subject = RDF::URI("http://kg.artsdata.ca/resource/K23-300")
    @address_predicate = RDF::URI("http://schema.org/address")
    @old_predicate = RDF::URI("http://www.w3.org/ns/prov#wasDerivedFrom")
    @new_predicate = RDF::URI("http://www.w3.org/ns/prov#hadPrimarySource")

    @repository = RDF::Repository.new

    @address = RDF::Node.new
    @source = RDF::URI("http://kg.artsdata.ca/graph/source1")
    @base_statement = RDF::Statement(@subject, @address_predicate, @address)
    @repository.insert(RDF::Statement(@subject, @address_predicate, @address, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@base_statement, @old_predicate, @source, graph_name: @graph_uri))

    # a sibling blank-object annotated statement that must survive, disambiguated by its own
    # (old_predicate, annotation_object) pairing rather than any literal blank-node label
    @other_address = RDF::Node.new
    @other_source = RDF::URI("http://kg.artsdata.ca/graph/source2")
    @other_base_statement = RDF::Statement(@subject, @address_predicate, @other_address)
    @repository.insert(RDF::Statement(@subject, @address_predicate, @other_address, graph_name: @graph_uri))
    @repository.insert(RDF::Statement(@other_base_statement, @old_predicate, @other_source, graph_name: @graph_uri))
  end

  def execute_update_statement_rank(annotation_object:)
    sparql = SparqlLoader.load(
      "entity_model/update_statement_rank",
      [
        "GRAPH_NAME_URI_PLACEHOLDER", GRAPH_NAME_URI,
        "# PATH_WHERE_PLACEHOLDER", "",
        "<BASE_SUBJECT_PLACEHOLDER>", @subject.to_ntriples,
        "<BASE_PREDICATE_PLACEHOLDER>", @address_predicate.to_ntriples,
        # ?BASE_OBJECT_PLACEHOLDER deliberately left unsubstituted (blank base_object case)
        "<OLD_PREDICATE_PLACEHOLDER>", @old_predicate.to_ntriples,
        "<NEW_PREDICATE_PLACEHOLDER>", @new_predicate.to_ntriples,
        "?ANNOTATION_OBJECT_PLACEHOLDER", annotation_object.to_ntriples
      ]
    )
    SPARQL::Grammar.parse(sparql, update: true).execute(@repository)
  end

  test "swaps the rank of the annotation on the correct blank-object statement" do
    execute_update_statement_rank(annotation_object: @source)

    refute @repository.has_statement?(RDF::Statement(@base_statement, @old_predicate, @source, graph_name: @graph_uri))
    assert @repository.has_statement?(RDF::Statement(@base_statement, @new_predicate, @source, graph_name: @graph_uri))
  end

  test "leaves the sibling blank-object statement's annotation untouched" do
    execute_update_statement_rank(annotation_object: @source)

    assert @repository.has_statement?(RDF::Statement(@other_base_statement, @old_predicate, @other_source, graph_name: @graph_uri))
    refute @repository.has_statement?(RDF::Statement(@other_base_statement, @new_predicate, @other_source, graph_name: @graph_uri))
  end
end
