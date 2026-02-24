require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get vocabularies" do
    get vocabularies_path
    assert_response :success
  end

  test "vocabularies page should have vocabularies stimulus controller" do
    get vocabularies_path
    assert_response :success
    
    # Should include the vocabularies Stimulus controller
    assert_includes @response.body, 'data-controller="vocabularies"'
  end

  test "vocabularies page should have expected container elements" do
    get vocabularies_path
    assert_response :success
    
    # Should include the main container elements
    assert_includes @response.body, 'class="vocabularies-page"'
    assert_includes @response.body, 'data-vocabularies-target="chart"'
    assert_includes @response.body, 'data-vocabularies-target="loading"'
    assert_includes @response.body, 'data-vocabularies-target="tooltip"'
  end

  test "should get events" do
    get events_path
    assert_response :success
  end

  test "events page should have events stimulus controller" do
    get events_path
    assert_response :success
    
    # Should include the events Stimulus controller
    assert_includes @response.body, 'data-controller="events"'
  end

  test "events page should have expected container elements" do
    get events_path
    assert_response :success
    
    # Should include the main container elements
    assert_includes @response.body, 'class="events-page"'
    assert_includes @response.body, 'data-events-target="map"'
    assert_includes @response.body, 'data-events-target="loading"'
    assert_includes @response.body, 'data-events-target="tooltip"'
  end
end
