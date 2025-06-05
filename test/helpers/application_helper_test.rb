require 'test_helper'
include ApplicationHelper

class ApplicationHelperTest < ActiveSupport::TestCase

  test "dump_jsonld with nested organizer" do
    bn = RDF::Node.new("123")
    graph = RDF::Graph.new
    graph << [RDF::URI("http://example.com/event"), RDF::URI("http://example.com/organizer"), bn]
    graph << [bn, RDF::Vocab::SCHEMA.name, "Organizer Name"]
    # puts graph.dump(:jsonld, standard_prefixes: true)
    expected = {"@context"=>{"schema"=>"http://schema.org/"}, "@id"=>"_:123", "schema:name"=>"Organizer Name"}
    output = dump_jsonld(bn, graph)
    assert_equal expected, JSON.parse(output)
  end

  test "dump_jsonld with nested place and address" do
    bn_place = RDF::Node.new("place")
    bn_address = RDF::Node.new("address")
    graph = RDF::Graph.new
    graph << [RDF::URI("http://example.com/event"), RDF::URI("http://example.com/location"), bn_place]
    graph << [bn_place, RDF::Vocab::SCHEMA.name, "Place Name"]
    graph << [bn_place, RDF::Vocab::SCHEMA.address, bn_address]
    graph << [bn_address, RDF::Vocab::SCHEMA.streetAddress, "123 Main St"]
    graph << [bn_address, RDF::Vocab::SCHEMA.addressLocality, "City"]
    # puts graph.dump(:jsonld, standard_prefixes: true)
    expected = {"@context"=>{"schema"=>"http://schema.org/"}, "@graph"=>[{"@id"=>"_:place", "schema:name"=>"Place Name"}, {"@id"=>"_:address", "schema:streetAddress"=>"123 Main St", "schema:addressLocality"=>"City"}]}
    output = dump_jsonld(bn_place, graph)
    assert_equal expected, JSON.parse(output)
  end

  # Add more tests for ApplicationHelper methods here
end