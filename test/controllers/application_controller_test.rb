require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "navigation should display lazy loading frame for controlled vocabularies" do
    get root_path
    
    assert_response :success
    
    # Should display the turbo-frame for lazy loading controlled vocabularies
    assert_includes @response.body, "Controlled Vocabularies"
    assert_includes @response.body, 'id="controlled-vocabularies-list"'
    assert_includes @response.body, "Loading..."
  end

  test "navigation should include job status component" do
    get root_path
    
    assert_response :success
    
    # Should include the job status controller and targets
    assert_includes @response.body, 'data-controller="job-status"'
    assert_includes @response.body, 'data-job-status-target="processingIcon"'
    assert_includes @response.body, 'data-job-status-target="queueBadge"'
  end

  test "should include Google Analytics when GOOGLE_ANALYTICS_ID is set" do
    # Set the environment variable
    original_ga_id = ENV['GOOGLE_ANALYTICS_ID']
    ENV['GOOGLE_ANALYTICS_ID'] = 'G-TEST123456'
    
    get root_path
    
    assert_response :success
    
    # Should include the Google Analytics script
    assert_includes @response.body, 'www.googletagmanager.com/gtag/js?id=G-TEST123456'
    assert_includes @response.body, "gtag('config', 'G-TEST123456')"
    assert_includes @response.body, 'window.dataLayer'
    
    # Restore original value
    ENV['GOOGLE_ANALYTICS_ID'] = original_ga_id
  end

  test "should not include Google Analytics when GOOGLE_ANALYTICS_ID is not set" do
    # Ensure the environment variable is not set
    original_ga_id = ENV['GOOGLE_ANALYTICS_ID']
    ENV['GOOGLE_ANALYTICS_ID'] = nil
    
    get root_path
    
    assert_response :success
    
    # Should not include the Google Analytics script
    assert_not_includes @response.body, 'www.googletagmanager.com/gtag/js'
    assert_not_includes @response.body, "gtag('config'"
    
    # Restore original value
    ENV['GOOGLE_ANALYTICS_ID'] = original_ga_id
  end

end
