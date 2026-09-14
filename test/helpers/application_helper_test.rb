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
    expected = {"@context"=>{"schema"=>"http://schema.org/"}, "@graph"=>[{"@id"=>"_:place", "schema:name"=>"Place Name", "schema:address"=>{"@id"=>"_:address"}}, {"@id"=>"_:address", "schema:streetAddress"=>"123 Main St", "schema:addressLocality"=>"City"}]}
    output = dump_jsonld(bn_place, graph)
    assert_equal expected, JSON.parse(output)
  end

  test "make_hash returns a deterministic string starting with 'f'" do
    result1 = make_hash("http://example.com/entity", "http://schema.org/name")
    result2 = make_hash("http://example.com/entity", "http://schema.org/name")
    assert_equal result1, result2, "make_hash should return the same value for the same input"
    assert result1.start_with?("f"), "make_hash result should start with 'f' for a valid DOM id"
    assert_match(/\A[a-z0-9]+\z/, result1, "make_hash result should contain only lowercase alphanumeric characters")
  end

  test "make_hash returns different values for different inputs" do
    result1 = make_hash("http://example.com/entity", "http://schema.org/name")
    result2 = make_hash("http://example.com/entity", "http://schema.org/description")
    assert_not_equal result1, result2, "make_hash should return different values for different inputs"
  end

  test "safe_external_url only allows http and https URLs" do
    assert_equal "https://example.com/file.ttl.gz", safe_external_url("https://example.com/file.ttl.gz")
    assert_equal "http://example.com/file.ttl.gz", safe_external_url("http://example.com/file.ttl.gz")
    assert_nil safe_external_url("javascript:alert(1)")
    assert_nil safe_external_url("artsdata://dumps/core-minus-provenance/latest")
  end

  test "data_dumps_jsonld builds a dcat:Distribution graph and skips unsafe/missing download urls" do
    dumps = [
      { title: "A", distribution_uri: "http://example.com/a", download_url: "https://example.com/a.ttl.gz", byte_size: 10 },
      { title: "B", distribution_uri: "http://example.com/b", download_url: "javascript:alert(1)" },
      { title: "C", distribution_uri: "http://example.com/c" }
    ]
    result = data_dumps_jsonld(dumps)
    assert_equal 1, result["@graph"].size
    node = result["@graph"].first
    assert_equal "http://example.com/a", node["id"]
    assert_equal "dcat:Distribution", node["type"]
    assert_equal "https://example.com/a.ttl.gz", node["downloadURL"]
    assert_equal 10, node["byteSize"]
  end

  test "data_dumps_jsonld returns nil when no dumps have a safe download url" do
    assert_nil data_dumps_jsonld([])
    assert_nil data_dumps_jsonld([{ title: "A", download_url: nil }])
  end

  # Add more tests for ApplicationHelper methods here
end