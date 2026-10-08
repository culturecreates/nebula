require 'test_helper'

# Mirrors the graph shape artsdata-api's MaintenanceService#add_dataset_log (refresh-in-memory
# refactor) actually writes: a <uri>_dataset node accumulating one prov:wasInfluencedBy per
# refresh, and per-activity prov:Activity/rdfs:comment plus per-statement <<s p o>>
# prov:wasGeneratedBy|wasInvalidatedBy <activity> RDF-star annotations - all in the logs graph.
# ?activity (not its rdfs:comment text) is what this query surfaces - see
# app/services/sparqls/query_controller/history_logs.sparql for why: it links into the activity's
# own page, which already shows everything it carries, including that comment.
#
# ?source is looked up separately, best-effort, from the entity's CURRENT claim annotation in the
# core graph (<<entity property value>> prov:wasDerivedFrom|hadPrimarySource ?source) - see the
# .sparql file for why that's the only place a source for an asserted change survives, and why its
# lookup opens its own sibling GRAPH <core> per branch instead of nesting it inside GRAPH <logs>.
class HistoryLogsSparqlTest < ActiveSupport::TestCase
  ENTITY_URI = "http://kg.artsdata.ca/resource/K23-300"
  LOGS_GRAPH = RDF::URI("http://kg.artsdata.ca/logs")
  CORE_GRAPH = RDF::URI("http://kg.artsdata.ca/core")

  def load_sparql
    SparqlLoader.load("query_controller/history_logs", ["URI_PLACEHOLDER", ENTITY_URI])
  end

  def execute
    sparql = load_sparql
    SPARQL::Grammar.parse(sparql).execute(@repository)
  end

  def setup
    @repository = RDF::Repository.new
    @entity = RDF::URI(ENTITY_URI)
    @dataset = RDF::URI("#{ENTITY_URI}_dataset")
    @activity = RDF::URI("#{ENTITY_URI}_refresh_2026-01-01T00:00:00Z")
    @agent = RDF::URI("http://kg.artsdata.ca/resource/K1-editor")
    @source = RDF::URI("http://www.wikidata.org/entity/Q1")

    @repository.insert(RDF::Statement(@dataset, RDF::Vocab::PROV.wasInfluencedBy, @activity, graph_name: LOGS_GRAPH))

    @repository.insert(RDF::Statement(@activity, RDF.type, RDF::Vocab::PROV.Activity, graph_name: LOGS_GRAPH))
    @repository.insert(RDF::Statement(@activity, RDF::Vocab::PROV.startedAtTime, RDF::Literal::DateTime.new("2026-01-01T00:00:00Z"), graph_name: LOGS_GRAPH))
    @repository.insert(RDF::Statement(@activity, RDF::Vocab::PROV.wasAssociatedWith, @agent, graph_name: LOGS_GRAPH))
    # Still written by add_dataset_log and still dereferencable off ?activity's own page, even
    # though this query no longer selects it directly.
    @repository.insert(RDF::Statement(@activity, RDF::Vocab::RDFS.comment, RDF::Literal("Updated claims:\n+schema:image: http://example.org/image.jpg (secondary Q1)"), graph_name: LOGS_GRAPH))

    @added_statement = RDF::Statement(@entity, RDF::URI("http://schema.org/name"), RDF::Literal("New Name"))
    @deleted_statement = RDF::Statement(@entity, RDF::URI("http://schema.org/name"), RDF::Literal("Old Name"))
    @repository.insert(RDF::Statement(@added_statement, RDF::Vocab::PROV.wasGeneratedBy, @activity, graph_name: LOGS_GRAPH))
    @repository.insert(RDF::Statement(@deleted_statement, RDF::Vocab::PROV.wasInvalidatedBy, @activity, graph_name: LOGS_GRAPH))

    # The added statement is still the live asserted value, so it still carries its own current
    # claim annotation in the core graph - this is the only place ?source can come from.
    @repository.insert(RDF::Statement(@added_statement, RDF::Vocab::PROV.wasDerivedFrom, @source, graph_name: CORE_GRAPH))

    # A decoy current annotation on an unrelated property, to catch ?source leaking into rows
    # whose ?property/?value aren't actually bound (the bare no-op-refresh row).
    decoy_statement = RDF::Statement(@entity, RDF::URI("http://schema.org/image"), RDF::Literal("http://example.org/decoy.jpg"))
    @repository.insert(RDF::Statement(decoy_statement, RDF::Vocab::PROV.hadPrimarySource, RDF::URI("http://example.org/decoy-source"), graph_name: CORE_GRAPH))
  end

  test "substitutes the URI placeholder" do
    refute_match(/URI_PLACEHOLDER/, load_sparql)
  end

  test "returns one row per direct asserted property change with the activity's date and uri" do
    solutions = execute

    added_row = solutions.find { |s| s[:action] == RDF::Vocab::PROV.wasGeneratedBy }
    assert added_row, "expected a row for the added statement"
    assert_equal RDF::URI("http://schema.org/name"), added_row[:property]
    assert_equal RDF::Literal("New Name"), added_row[:value]
    assert_equal RDF::Literal::DateTime.new("2026-01-01T00:00:00Z"), added_row[:log_date]
    assert_equal @activity, added_row[:activity]

    deleted_row = solutions.find { |s| s[:action] == RDF::Vocab::PROV.wasInvalidatedBy }
    assert deleted_row, "expected a row for the deleted statement"
    assert_equal RDF::Literal("Old Name"), deleted_row[:value]
    assert_equal @activity, deleted_row[:activity]
  end

  test "resolves source for an asserted row that's still the live claimed value" do
    solutions = execute

    added_row = solutions.find { |s| s[:action] == RDF::Vocab::PROV.wasGeneratedBy }
    assert_equal @source, added_row[:source]
  end

  test "leaves source unbound for an asserted row with no current claim annotation, without leaking an unrelated one" do
    solutions = execute

    deleted_row = solutions.find { |s| s[:action] == RDF::Vocab::PROV.wasInvalidatedBy }
    assert_nil deleted_row[:source]
  end


  test "accumulates rows across multiple past refreshes" do
    earlier_activity = RDF::URI("#{ENTITY_URI}_refresh_2025-01-01T00:00:00Z")
    @repository.insert(RDF::Statement(@dataset, RDF::Vocab::PROV.wasInfluencedBy, earlier_activity, graph_name: LOGS_GRAPH))
    @repository.insert(RDF::Statement(earlier_activity, RDF::Vocab::PROV.startedAtTime, RDF::Literal::DateTime.new("2025-01-01T00:00:00Z"), graph_name: LOGS_GRAPH))
    @repository.insert(RDF::Statement(earlier_activity, RDF::Vocab::PROV.wasAssociatedWith, @agent, graph_name: LOGS_GRAPH))

    solutions = execute

    log_dates = solutions.map { |s| s[:log_date] }.uniq
    assert_includes log_dates, RDF::Literal::DateTime.new("2026-01-01T00:00:00Z")
    assert_includes log_dates, RDF::Literal::DateTime.new("2025-01-01T00:00:00Z")

    bare_row = solutions.find { |s| s[:log_date] == RDF::Literal::DateTime.new("2025-01-01T00:00:00Z") }
    assert_equal earlier_activity, bare_row[:activity]
    assert_nil bare_row[:property]
    assert_nil bare_row[:source]
  end
end
