require "test_helper"

class MintControllerTest < ActionDispatch::IntegrationTest


  test "artsdata_mint_endpoint is correctly set"  do
    expected_endpoint = "https://api.artsdata.ca/mint"
    actual_endpoint = Rails.application.credentials.artsdata_mint_endpoint
    assert_equal expected_endpoint, actual_endpoint, "The artsdata_mint_endpoint is not correctly set in credentials"
  end

  test "artsdata_link_endpoint is correctly set"  do
    expected_endpoint = "https://api.artsdata.ca/link"
    actual_endpoint = Rails.application.credentials.artsdata_link_endpoint
    assert_equal expected_endpoint, actual_endpoint, "The artsdata_link_endpoint is not correctly set in credentials"
  end


  
  test "should redirect to root with missing externalUri" do
    get mint_preview_url, params: { classToMint: 'SomeClass' }
    assert_equal 'Missing a required param. Required list: [:externalUri]', flash[:alert]
  end
  
end
