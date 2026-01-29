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

end
