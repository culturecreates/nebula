require "test_helper"

class BotVerificationControllerTest < ActionDispatch::IntegrationTest
  test "should get http_message_signatures_directory" do
    get "/.well-known/http-message-signatures-directory"
    assert_response :success
    assert_equal "application/http-message-signatures-directory+json", response.content_type
    assert_includes response.headers, "Signature"
    assert_includes response.headers, "Signature-Input"
    assert_includes response.headers, "Cache-Control"
    json = JSON.parse(response.body)
    assert json["keys"].is_a?(Array)
    assert_equal "OKP", json["keys"][0]["kty"]
    assert_equal "Ed25519", json["keys"][0]["crv"]
    assert json["keys"][0]["x"].present?
  end
end
