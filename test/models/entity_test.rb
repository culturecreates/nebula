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