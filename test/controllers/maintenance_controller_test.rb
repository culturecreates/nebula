require "test_helper"

class MaintenanceControllerTest < ActionDispatch::IntegrationTest
  MAINTENANCE_ENDPOINT = "#{Rails.application.config.artsdata_maintenance_endpoint}/refresh_entity"

  test "batch_refresh_entity returns redirect_url on success" do
    uris = ["http://kg.artsdata.ca/resource/K1", "http://kg.artsdata.ca/resource/K2"]
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_batch_refresh_entity_url,
      params: { uris: uris, redirect_url: "/query/show?sparql=test" }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "/query/show?sparql=test", json["redirect_url"]
  end

  test "batch_refresh_entity sets notice flash on success" do
    uris = ["http://kg.artsdata.ca/resource/K1", "http://kg.artsdata.ca/resource/K2"]
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_batch_refresh_entity_url,
      params: { uris: uris, redirect_url: "/" }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_equal "Successfully queued refresh for 2 entities.", flash[:notice]
  end

  test "batch_refresh_entity sets alert flash on API failure" do
    uris = ["http://kg.artsdata.ca/resource/K1"]
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .to_return(status: 500, body: "Internal Server Error", headers: {})

    post maintenance_batch_refresh_entity_url,
      params: { uris: uris, redirect_url: "/" }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    assert_match "Batch refresh failed", flash[:alert]
  end

  test "batch_refresh_entity sets alert flash on timeout" do
    uris = ["http://kg.artsdata.ca/resource/K1"]
    stub_request(:post, MAINTENANCE_ENDPOINT).to_timeout

    post maintenance_batch_refresh_entity_url,
      params: { uris: uris, redirect_url: "/" }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    assert flash[:alert].present?
  end

  test "batch_refresh_entity uses root_path when no redirect_url given" do
    uris = ["http://kg.artsdata.ca/resource/K1"]
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_batch_refresh_entity_url,
      params: { uris: uris }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["redirect_url"]
  end
end

