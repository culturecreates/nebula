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

  test "refresh_entity forwards source param to the maintenance API when scoped to one identifier" do
    uri = "http://kg.artsdata.ca/resource/K1"
    source = "http://www.wikidata.org/entity/Q1"
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .with(body: hash_including("source" => source))
      .to_return(status: 200, body: { logs: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_refresh_entity_url,
      params: { uri: uri, dryrun: false, source: source }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    assert_match "Successfully refreshed #{uri} from #{source}.", flash[:notice]
  end

  test "refresh_entity omits source param when refreshing all sources" do
    uri = "http://kg.artsdata.ca/resource/K1"
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .with { |request| !JSON.parse(request.body).key?("source") }
      .to_return(status: 200, body: { logs: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_refresh_entity_url,
      params: { uri: uri, dryrun: false }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    assert_match "Successfully refreshed #{uri}.", flash[:notice]
  end

  test "refresh_entity dryrun preview omits empty brackets when a log item has no source" do
    uri = "http://kg.artsdata.ca/resource/K1"
    logs = [{
      "action" => "add",
      "update_assertions" => true,
      "claim" => nil,
      "source" => "",
      "subject" => uri,
      "predicate" => "http://schema.org/name",
      "object" => "New Name"
    }]
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .to_return(status: 200, body: { logs: logs, rescues: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_refresh_entity_url,
      params: { uri: uri, dryrun: true }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    json = JSON.parse(response.body)
    refute_match(/\(\)/, json["message"])
    assert_match "<li>name: <b>New Name</b></li>", json["message"]
  end

  test "refresh_entity dryrun preview keeps the source in brackets when present" do
    uri = "http://kg.artsdata.ca/resource/K1"
    logs = [{
      "action" => "add",
      "update_assertions" => true,
      "claim" => nil,
      "source" => "http://www.wikidata.org/entity/Q1",
      "subject" => uri,
      "predicate" => "http://schema.org/name",
      "object" => "New Name"
    }]
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .to_return(status: 200, body: { logs: logs, rescues: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_refresh_entity_url,
      params: { uri: uri, dryrun: true }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    json = JSON.parse(response.body)
    assert_match "<li>name: <b>New Name</b> (Q1)</li>", json["message"]
  end

  test "refresh_entity dryrun preview marks added and removed claims with +/- in the Claims section" do
    uri = "http://kg.artsdata.ca/resource/K1"
    logs = [
      {
        "action" => "add",
        "update_assertions" => false,
        "claim" => "primary",
        "source" => "http://www.wikidata.org/entity/Q1",
        "subject" => uri,
        "predicate" => "http://schema.org/image",
        "object" => "http://example.org/new.jpg"
      },
      {
        "action" => "delete",
        "update_assertions" => false,
        "claim" => "derived",
        "source" => "http://www.wikidata.org/entity/Q2",
        "subject" => uri,
        "predicate" => "http://schema.org/image",
        "object" => "http://example.org/old.jpg"
      }
    ]
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .to_return(status: 200, body: { logs: logs, rescues: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_refresh_entity_url,
      params: { uri: uri, dryrun: true }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    json = JSON.parse(response.body)
    assert_match "<h4>Claims</h5>", json["message"]
    assert_match "<li>+image: <b>http://example.org/new.jpg</b> (Q1)</li>", json["message"]
    assert_match "<li>-image: <b>http://example.org/old.jpg</b> (secondary Q2)</li>", json["message"]
  end

  test "refresh_entity dryrun preview omits a claim already shown in the Updates section" do
    uri = "http://kg.artsdata.ca/resource/K1"
    logs = [
      {
        "action" => "add",
        "update_assertions" => true,
        "claim" => nil,
        "source" => "http://www.wikidata.org/entity/Q1",
        "subject" => uri,
        "predicate" => "http://schema.org/name",
        "object" => "New Name"
      },
      # asserting a value also writes its own matching claim annotation (see
      # artsdata-api's MaintenanceService#add_to_log), so the same change can arrive a second
      # time here with update_assertions: false
      {
        "action" => "add",
        "update_assertions" => false,
        "claim" => "primary",
        "source" => "http://www.wikidata.org/entity/Q1",
        "subject" => uri,
        "predicate" => "http://schema.org/name",
        "object" => "New Name"
      }
    ]
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .to_return(status: 200, body: { logs: logs, rescues: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_refresh_entity_url,
      params: { uri: uri, dryrun: true }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    json = JSON.parse(response.body)
    assert_match "<h4>Updates</h5>", json["message"]
    refute_match "<h4>Claims</h5>", json["message"]
    assert_equal 1, json["message"].scan("New Name").length
  end

  test "refresh_entity dryrun preview still shows a claim with no matching asserted change" do
    uri = "http://kg.artsdata.ca/resource/K1"
    logs = [
      {
        "action" => "add",
        "update_assertions" => true,
        "claim" => nil,
        "source" => "http://www.wikidata.org/entity/Q1",
        "subject" => uri,
        "predicate" => "http://schema.org/name",
        "object" => "New Name"
      },
      {
        "action" => "add",
        "update_assertions" => false,
        "claim" => "derived",
        "source" => "http://www.wikidata.org/entity/Q2",
        "subject" => uri,
        "predicate" => "http://schema.org/name",
        "object" => "Alternate Name"
      }
    ]
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .to_return(status: 200, body: { logs: logs, rescues: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_refresh_entity_url,
      params: { uri: uri, dryrun: true }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    json = JSON.parse(response.body)
    assert_match "<h4>Claims</h5>", json["message"]
    assert_match "<li>+name: <b>Alternate Name</b> (secondary Q2)</li>", json["message"]
  end

  test "refresh_entity dryrun preview does not add a sign to the Updates/Deletes sections" do
    uri = "http://kg.artsdata.ca/resource/K1"
    logs = [{
      "action" => "add",
      "update_assertions" => true,
      "claim" => nil,
      "source" => "http://www.wikidata.org/entity/Q1",
      "subject" => uri,
      "predicate" => "http://schema.org/name",
      "object" => "New Name"
    }]
    stub_request(:post, MAINTENANCE_ENDPOINT)
      .to_return(status: 200, body: { logs: logs, rescues: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    post maintenance_refresh_entity_url,
      params: { uri: uri, dryrun: true }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }

    assert_response :success
    json = JSON.parse(response.body)
    assert_match "<li>name: <b>New Name</b> (Q1)</li>", json["message"]
    refute_match "<li>+name", json["message"]
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

