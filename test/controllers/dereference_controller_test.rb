require "test_helper"

class DereferenceControllerTest < ActionDispatch::IntegrationTest
  setup do
    Entity.any_instance.stubs(:label).returns(nil)
    Entity.any_instance.stubs(:type).returns(RDF::URI("http://schema.org/Thing"))
    Entity.any_instance.stubs(:card).returns({})
    Entity.any_instance.stubs(:graph).returns(RDF::Graph.new)

    # The app's cache_store is :null_store in the test environment (never
    # actually caches), so swap in a real store for these tests, which
    # specifically assert on caching behavior.
    @previous_cache_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @previous_cache_store
  end

  test "card serves subsequent requests from cache" do
    uri = "http://kg.artsdata.ca/resource/K23-300"
    Entity.any_instance.expects(:load_card).once

    get dereference_card_path(uri: uri, frame_id: "1")
    assert_response :success

    get dereference_card_path(uri: uri, frame_id: "2")
    assert_response :success
  end

  test "card with refresh param bypasses the cache and reloads" do
    uri = "http://kg.artsdata.ca/resource/K23-300"
    Entity.any_instance.expects(:load_card).twice

    get dereference_card_path(uri: uri, frame_id: "1")
    assert_response :success

    get dereference_card_path(uri: uri, frame_id: "1", refresh: true)
    assert_response :success
  end
end
