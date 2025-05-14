require "test_helper"

class ReconcileControllerTest < ActionDispatch::IntegrationTest
  
  test "artsdata_recon_endpoint is correctly set"  do
    expected_endpoint = "https://api.artsdata.ca/recon"
    actual_endpoint = Rails.application.credentials.artsdata_recon_endpoint
    assert_equal expected_endpoint, actual_endpoint, "The artsdata_recon_endpoint is not correctly set in credentials"
  end


end
