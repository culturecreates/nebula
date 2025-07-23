require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  def setup
    @entity = Entity.new(entity_uri: "http://kg.artsdata.ca/resource/K23-300")
    VCR.use_cassette('EntityTest setup event entity K23-300', record: :new_episodes) do
      @entity.load_graph
   end
  end
 

end