require "test_helper"

class ArtifactControllerTest < ActionDispatch::IntegrationTest

  test "artsdata_databus_endpoint is correctly set"  do
    expected_endpoint = "https://api.artsdata.ca/databus"
    actual_endpoint = Rails.application.credentials.artsdata_databus_endpoint
    assert_equal expected_endpoint, actual_endpoint, "The artsdata_databus_endpoint is not correctly set in credentials"
  end

end
