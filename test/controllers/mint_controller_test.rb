require "test_helper"

class MintControllerTest < ActionDispatch::IntegrationTest

  test "should get preview with valid parameters" do
    VCR.use_cassette('mint_preview_url') do
      get mint_preview_url, params: { externalUri: 'http://scenepro.ca/some-uri', classToMint: 'SomeClass' }
      assert_response :success
    end
  end

  
  test "should redirect to root with missing externalUri" do
    get mint_preview_url, params: { classToMint: 'SomeClass' }
    assert_equal 'Missing a required param. Required list: [:externalUri]', flash[:alert]
  end
  
end
