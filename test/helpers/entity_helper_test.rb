require 'test_helper'
include EntityHelper

class EntityHelperTest < ActionView::TestCase

  test "authorized_external_identifier_sources returns the external URIs asserting sameAs the entity" do
    entity_uri = "http://kg.artsdata.ca/resource/K1"
    external_uri = "http://www.wikidata.org/entity/Q1"

    Entity.any_instance.stubs(:load_authorized_external_identifiers)
    Entity.any_instance.stubs(:graph).returns(
      RDF::Graph.new << RDF::Statement(RDF::URI(entity_uri), RDF::URI("http://schema.org/sameAs"), RDF::URI(external_uri))
    )

    entity = Entity.new(entity_uri: entity_uri)
    sources = authorized_external_identifier_sources(entity)

    assert_equal [RDF::URI(external_uri)], sources
  end

  test "authorized_external_identifier_sources returns an empty array when there are no external identifiers" do
    entity_uri = "http://kg.artsdata.ca/resource/K2"

    Entity.any_instance.stubs(:load_authorized_external_identifiers)
    Entity.any_instance.stubs(:graph).returns(RDF::Graph.new)

    entity = Entity.new(entity_uri: entity_uri)
    assert_equal [], authorized_external_identifier_sources(entity)
  end

  test "display_label shows a SHACL message only on the focus node it was reported for" do
    sh = RDF::Vocabulary.new("http://www.w3.org/ns/shacl#")
    schema_name = RDF::URI("http://schema.org/name")
    place = RDF::URI("https://example.com/place")
    annotation = RDF::Node.new
    result = RDF::Node.new
    graph = RDF::Graph.new
    graph << [schema_name, RDF::RDFS.label, "name"]
    graph << [place, schema_name, "Place"]
    graph << [annotation, schema_name, "Annotation"]
    graph << [result, sh.focusNode, place]
    graph << [result, sh.resultPath, schema_name]
    graph << [result, sh.resultMessage, "Name has a problem"]
    @entity = Entity.new(entity_uri: place.to_s, graph: graph)

    assert_includes display_label(schema_name, focus_node: place), "Name has a problem"
    assert_includes display_label(schema_name), "Name has a problem"
    refute_includes display_label(schema_name, focus_node: annotation), "Name has a problem"
  end
end
