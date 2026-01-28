require "test_helper"

class ControlledVocabulariesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get controlled_vocabularies_path
    assert_response :success
  end

  test "should return vocabularies in turbo-frame" do
    get controlled_vocabularies_path
    assert_response :success
    
    # Should contain the turbo-frame wrapper
    assert_includes @response.body, 'id="controlled-vocabularies-list"'
  end

  test "should use fallback vocabularies on error" do
    # Mock the SPARQL client to raise an error
    SPARQL::Client.any_instance.stubs(:query).raises(StandardError.new("Connection failed"))
    
    get controlled_vocabularies_path
    assert_response :success
    
    # Should still display the fallback vocabularies
    assert_includes @response.body, "Event Types"
    assert_includes @response.body, "Organization Types"
    assert_includes @response.body, "Genres"
  end
end
