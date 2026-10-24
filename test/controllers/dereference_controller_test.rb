require "test_helper"

class DereferenceControllerTest < ActionDispatch::IntegrationTest
  TURBO = { "Turbo-Frame" => "card-1" }.freeze

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

    get dereference_card_path(uri: uri, frame_id: "1"), headers: TURBO
    assert_response :success

    get dereference_card_path(uri: uri, frame_id: "2"), headers: TURBO
    assert_response :success
  end

  test "card with refresh param bypasses the cache and reloads for signed-in users" do
    ApplicationController.any_instance.stubs(:user_signed_in?).returns(true)
    uri = "http://kg.artsdata.ca/resource/K23-300"
    Entity.any_instance.expects(:load_card).twice

    get dereference_card_path(uri: uri, frame_id: "1"), headers: TURBO
    assert_response :success

    get dereference_card_path(uri: uri, frame_id: "1", refresh: true), headers: TURBO
    assert_response :success
  end

  test "card renders an error inside the frame when it fails during a turbo-frame request" do
    uri = "http://kg.artsdata.ca/resource/K23-300"
    Entity.any_instance.stubs(:load_card).raises(StandardError, "boom")

    get dereference_card_path(uri: uri, frame_id: "1"), headers: { "Turbo-Frame" => "card-1" }

    assert_response :success
    assert_select "turbo-frame#card-1 .text-danger", text: /Could not load: boom/
    assert_match "K23-300", response.body
  end

  test "card refresh param does not bypass the cache for anonymous users" do
    uri = "http://kg.artsdata.ca/resource/K23-300"
    Entity.any_instance.expects(:load_card).once

    get dereference_card_path(uri: uri, frame_id: "1"), headers: TURBO
    get dereference_card_path(uri: uri, frame_id: "1", refresh: true), headers: TURBO
    assert_response :success
  end

  test "card rejects requests that are not turbo-frame fetches" do
    Entity.any_instance.expects(:load_card).never

    get dereference_card_path(uri: "http://kg.artsdata.ca/resource/K23-300", frame_id: "1")

    assert_response :forbidden
  end
end
