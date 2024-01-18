require "test_helper"

class MintControllerTest < ActionDispatch::IntegrationTest

  test "should get preview with valid parameters" do
    get mint_preview_url, params: { externalUri: 'http://scenepro.ca/some-uri', classToMint: 'SomeClass' }
    assert_response :success
  end
  
  test "should redirect to root with invalid externalUri" do
    get mint_preview_url, params: { externalUri: 'http://invalid.com/some-uri', classToMint: 'SomeClass' }
    assert_redirected_to root_path
    assert_equal 'Missing publisher authority.', flash[:alert]
  end
  
  test "should redirect to root with missing externalUri" do
    get mint_preview_url, params: { classToMint: 'SomeClass' }
    assert_redirected_to root_path
    assert_equal 'Missing a required param. Required list: [:externalUri, :classToMint]', flash[:alert]
  end
  
  test "should redirect to root with missing classToMint" do
    get mint_preview_url, params: { externalUri: 'http://scenepro.ca/some-uri' }
    assert_redirected_to root_path
    assert_equal 'Missing a required param. Required list: [:externalUri, :classToMint]', flash[:alert]
  end
end
