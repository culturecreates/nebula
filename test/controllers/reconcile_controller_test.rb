require "test_helper"

class ReconcileControllerTest < ActionDispatch::IntegrationTest
  WIKIDATA_RECON = "https://wikidata.reconci.link/en/api".freeze

  test "query shows a timeout message inside the recon_results frame" do
    stub_request(:get, /wikidata\.reconci\.link/).to_timeout

    get reconcile_query_url, params: { query: "Frontenac", reconEndpoint: WIKIDATA_RECON }

    assert_response :gateway_timeout
    assert_select "turbo-frame#recon_results .alert", text: /took too long/
  end

  test "query shows an unavailable message when the service is unreachable" do
    stub_request(:get, /wikidata\.reconci\.link/).to_raise(SocketError)

    get reconcile_query_url, params: { query: "Frontenac", reconEndpoint: WIKIDATA_RECON }

    assert_response :bad_gateway
    assert_select "turbo-frame#recon_results .alert", text: /unavailable/
  end

  test "query shows the upstream error inside the frame on a non-200 response" do
    stub_request(:get, /wikidata\.reconci\.link/).to_return(status: 500)

    get reconcile_query_url, params: { query: "Frontenac", reconEndpoint: WIKIDATA_RECON }

    assert_response :bad_gateway
    assert_select "turbo-frame#recon_results .alert", text: /Error: 500/
  end
end
