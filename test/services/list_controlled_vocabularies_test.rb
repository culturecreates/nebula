require "test_helper"
require "rdf"
require "sparql"

class ListControlledVocabulariesTest < ActiveSupport::TestCase
  def setup
    # Load the SPARQL query
    @sparql_query = SparqlLoader.load("list_controlled_vocabularies")
    
    # Load the test fixture data
    fixture_path = Rails.root.join("test", "fixtures", "files", "controlled_vocabularies.ttl")
    @graph = RDF::Graph.load(fixture_path, format: :turtle)
  end

  test "SPARQL query should be loaded successfully" do
    assert_not_nil @sparql_query
    assert @sparql_query.is_a?(String)
    assert @sparql_query.include?("skos:ConceptScheme")
    assert @sparql_query.include?("skos:prefLabel")
  end

  test "should return only Artsdata controlled vocabularies with labels" do
    # Execute the SPARQL query against the test data
    solutions = SPARQL.execute(@sparql_query, @graph)
    
    # Convert solutions to array of URIs
    vocabularies = solutions.map { |solution| solution[:cv].to_s }.uniq
    
    # Should return exactly 3 Artsdata vocabularies
    assert_equal 3, vocabularies.length
    
    # Should include the three Artsdata vocabularies
    assert_includes vocabularies, "http://kg.artsdata.ca/resource/ArtsdataEventTypes"
    assert_includes vocabularies, "http://kg.artsdata.ca/resource/ArtsdataOrganizationTypes"
    assert_includes vocabularies, "http://kg.artsdata.ca/resource/ArtsdataGenres"
    
    # Should NOT include the non-Artsdata vocabulary
    assert_not_includes vocabularies, "http://example.com/other/vocabulary"
    
    # Verify labels are returned
    solutions.each do |solution|
      assert solution[:label].present?, "Expected label to be present for #{solution[:cv]}"
    end
  end

  test "should return labels with language tags" do
    solutions = SPARQL.execute(@sparql_query, @graph)
    
    # Find English and French labels for Event Types
    event_types_solutions = solutions.select { |s| s[:cv].to_s.include?("ArtsdataEventTypes") }
    
    # Should have both English and French labels
    assert event_types_solutions.length >= 2, "Expected at least 2 labels (en and fr)"
    
    # Check that labels have language information
    labels_with_lang = event_types_solutions.select { |s| s[:label].respond_to?(:language) && s[:label].language }
    assert labels_with_lang.length >= 2, "Expected labels with language tags"
  end

  test "should filter by artsdata.ca/resource domain" do
    solutions = SPARQL.execute(@sparql_query, @graph)
    
    # All results should contain "artsdata.ca/resource" in the URI
    solutions.each do |solution|
      assert solution[:cv].to_s.include?("artsdata.ca/resource"),
             "Expected URI to contain 'artsdata.ca/resource' but got: #{solution[:cv]}"
    end
  end
end
