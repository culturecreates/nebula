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
  
  test "should return error when API is unavailable in production" do
    # Mock production environment behavior
    Rails.env.stub :production?, true do
      Rails.env.stub :staging?, false do
        # Mock Net::HTTP to raise an error
        Net::HTTP.stub :get_response, ->(_uri) { raise StandardError.new("Connection failed") } do
          get job_status_path
          
          assert_response :service_unavailable
          json = JSON.parse(@response.body)
          assert_equal "Failed to fetch job status", json['error']
        end
      end
    end
  end
  
  test "should return error when API returns non-200 status in production" do
    # Mock production environment behavior
    Rails.env.stub :production?, true do
      Rails.env.stub :staging?, false do
        # Mock Net::HTTP to return a failed response
        mock_response = Minitest::Mock.new
        mock_response.expect :code, "500"
        
        Net::HTTP.stub :get_response, ->(_uri) { mock_response } do
          get job_status_path
          
          assert_response :service_unavailable
          json = JSON.parse(@response.body)
          assert_equal "Failed to fetch job status", json['error']
        end
        
        mock_response.verify
      end
    end
  end
end
