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

end
