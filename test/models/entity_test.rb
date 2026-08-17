require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  def setup
    @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/K23-300")
    VCR.use_cassette('EntityTest setup event entity K23-300', record: :new_episodes) do
      @entity.load_graph
   end
  end
 

  test "should load graph and populate attributes" do
    assert_not_nil @entity.graph
    assert_equal "http://kg.artsdata.ca/resource/K23-300", @entity.entity_uri
    assert_equal "http://schema.org/Event", @entity.type.value
    assert_equal "Le dîner de cons", @entity.label.value
  end
end

class EntityResolveSubjectPathTest < ActiveSupport::TestCase
  def setup
    @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/K23-300")
  end

  def resolve(subject, root_subject, path_predicates)
    @entity.send(:resolve_subject_path, subject, root_subject, path_predicates)
  end

  test "returns the subject unchanged and an empty fragment when it's not a blank node" do
    term, where = resolve("<http://kg.artsdata.ca/resource/K23-300>", nil, [])

    assert_equal "<http://kg.artsdata.ca/resource/K23-300>", term
    assert_equal "", where
  end

  test "returns nil when the subject is a blank node and no root/path is given" do
    assert_nil resolve("_:b0", nil, [])
    assert_nil resolve("_:b0", "<http://kg.artsdata.ca/resource/K23-300>", [])
    assert_nil resolve("_:b0", nil, ["<http://schema.org/address>"])
  end

  test "returns nil when the given root subject is itself a blank node" do
    assert_nil resolve("_:b0", "_:root", ["<http://schema.org/address>"])
  end

  test "builds a single join line and variable for a 1-hop path" do
    term, where = resolve("_:b0", "<http://kg.artsdata.ca/resource/K23-300>", ["<http://schema.org/address>"])

    assert_equal "?bnode_path_0", term
    assert_equal "<http://kg.artsdata.ca/resource/K23-300> <http://schema.org/address> ?bnode_path_0 .", where
  end

  test "chains join lines and variables for a 2-hop path" do
    term, where = resolve("_:b1", "<http://kg.artsdata.ca/resource/K23-300>", ["<http://schema.org/address>", "<http://schema.org/geo>"])

    assert_equal "?bnode_path_1", term
    assert_equal "<http://kg.artsdata.ca/resource/K23-300> <http://schema.org/address> ?bnode_path_0 .\n?bnode_path_0 <http://schema.org/geo> ?bnode_path_1 .", where
  end
end