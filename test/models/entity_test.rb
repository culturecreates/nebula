require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  def setup
    @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/K23-300")
    VCR.use_cassette('EntityTest setup event entity K23-300', record: :new_episodes) do
      @entity.load_graph
   end
   
  end

  test "graph_api_endpoint is correctly set"  do
    expected_endpoint = "http://db.artsdata.ca"
    actual_endpoint = Rails.application.credentials.graph_api_endpoint
    assert_equal expected_endpoint, actual_endpoint, "The graph_api_endpoint is not correctly set in credentials"
  end
 

end