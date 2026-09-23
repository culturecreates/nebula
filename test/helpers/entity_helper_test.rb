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
end
