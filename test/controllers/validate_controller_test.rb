require "test_helper"

class ValidateControllerTest < ActionDispatch::IntegrationTest
  MINT_PREVIEW = /preview/

  test "show renders the card-validation frame with an error when the mint API times out" do
    stub_request(:get, MINT_PREVIEW).to_timeout

    get validate_url, params: { uri: "http://www.wikidata.org/entity/Q1", classToMint: "schema:Place" }

    assert_response :success
    assert_select "turbo-frame#card-validation .alert", text: /timed out/
  end

  test "show renders the frame with an error when the mint API returns a non-JSON body" do
    stub_request(:get, MINT_PREVIEW).to_return(status: 502, body: "<html>Bad Gateway</html>")

    get validate_url, params: { uri: "http://www.wikidata.org/entity/Q1", classToMint: "schema:Place" }

    assert_response :success
    assert_select "turbo-frame#card-validation .alert", text: /Error calling Mint Preview API/
  end

  test "show renders the frame with a data error when the mint API reports failure" do
    stub_request(:get, MINT_PREVIEW).to_return(status: 200, body: { status: "error", message: "bad data" }.to_json)

    get validate_url, params: { uri: "http://www.wikidata.org/entity/Q1", classToMint: "schema:Place" }

    assert_response :success
    assert_select "turbo-frame#card-validation .alert", text: /Data Error: bad data/
  end
end
