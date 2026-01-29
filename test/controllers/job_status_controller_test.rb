require "test_helper"

class JobStatusControllerTest < ActionDispatch::IntegrationTest
  test "should return empty response in test environment" do
    # Test environment behaves like development for this endpoint
    get job_status_path
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    assert_not_nil json['queues']
    assert_not_nil json['processing']
    assert_equal [], json['processing']
  end

  test "job status endpoint should be accessible" do
    get job_status_path
    
    assert_response :success
    assert_equal 'application/json; charset=utf-8', @response.content_type
  end
end
