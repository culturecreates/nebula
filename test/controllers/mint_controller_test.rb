require "test_helper"

class MintControllerTest < ActionDispatch::IntegrationTest
  
  test "should redirect to root with missing externalUri param in API call" do
    get mint_preview_url, params: { classToMint: 'SomeClass' }
    assert_equal 'Missing a required param. Required list: [:externalUri]', flash[:alert]
  end
  
end
