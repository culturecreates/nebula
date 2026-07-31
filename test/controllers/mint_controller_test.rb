require "test_helper"

class MintControllerTest < ActionDispatch::IntegrationTest
  
  test "should redirect to root with missing externalUri param" do
    get mint_preview_url, params: { classToMint: 'SomeClass' }
    assert_equal 'Missing a required param. Required list: [:externalUri]', flash[:alert]
  end

  test "wikidata form shows default type id" do
    get mint_wikidata_url

    assert_response :success
    assert_includes response.body, 'name="type"'
    assert_includes response.body, 'value="Q5"'
  end

  test "wikidata search uses submitted type id for reconciliation request" do
    get mint_wikidata_url, params: { wikidata_search: "The Beatles", type: "Q215380" }

    assert_response :success
    assert_includes response.body, 'name="type"'
    assert_includes response.body, 'value="Q215380"'
    assert_includes response.body, "type=Q215380"
  end
  
end
