require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get vocabularies" do
    get vocabularies_path
    assert_response :success
  end

  test "vocabularies page should have vocabularies stimulus controller" do
    get vocabularies_path
    assert_response :success
    
    # Should include the vocabularies Stimulus controller
    assert_includes @response.body, 'data-controller="vocabularies"'
  end

  test "vocabularies page should have expected container elements" do
    get vocabularies_path
    assert_response :success
    
    # Should include the main container elements
    assert_includes @response.body, 'class="vocabularies-page"'
    assert_includes @response.body, 'data-vocabularies-target="chart"'
    assert_includes @response.body, 'data-vocabularies-target="loading"'
    assert_includes @response.body, 'data-vocabularies-target="tooltip"'
  end

  test "should get events" do
    get events_path
    assert_response :success
  end

  test "events page should have events stimulus controller" do
    get events_path
    assert_response :success
    
    # Should include the events Stimulus controller
    assert_includes @response.body, 'data-controller="events"'
  end

  test "events page should have expected container elements" do
    get events_path
    assert_response :success
    
    # Should include the main container elements
    assert_includes @response.body, 'class="events-page"'
    assert_includes @response.body, 'data-events-target="map"'
    assert_includes @response.body, 'data-events-target="loading"'
    assert_includes @response.body, 'data-events-target="tooltip"'
  end

  test "should get data dumps" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([])

    get data_dumps_path

    assert_response :success
    assert_includes @response.body, "Artsdata data dumps"
    assert_includes @response.body, "No Artsdata dump resources are currently published."
  end

  test "data dumps page should render dump metadata" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([
      {
        translation_key: "core_minus_provenance_latest",
        title: "Artsdata core minus provenance",
        description: "Core dump",
        version: "2026-09-01T05_18_57",
        resource_uri: "artsdata://dumps/core-minus-provenance/latest",
        data_dump_uri: "http://kg.artsdata.ca/databus/example/artifact",
        distribution_uri: "http://kg.artsdata.ca/databus/example/distribution",
        download_url: "https://example.test/core.ttl.gz"
      }
    ])

    get data_dumps_path

    assert_response :success
    assert_includes @response.body, "2026-09-01T05_18_57"
    assert_includes @response.body, "artsdata://dumps/core-minus-provenance/latest"
    assert_includes @response.body, "http://kg.artsdata.ca/databus/example/artifact"
    assert_includes @response.body, "core.ttl.gz"
    assert_includes @response.body, "https://example.test/core.ttl.gz"
  end

  test "data dumps page should render in french" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([])

    get data_dumps_path(locale: :fr)

    assert_response :success
    assert_includes @response.body, "Jeux de données Artsdata"
  end

  test "data dumps page should not link unsafe URLs" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([
      {
        translation_key: "core_minus_provenance_latest",
        title: "Artsdata core minus provenance",
        description: "Core dump",
        version: "2026-09-01T05_18_57",
        resource_uri: "artsdata://dumps/core-minus-provenance/latest",
        data_dump_uri: "artsdata://dumps/core-minus-provenance/latest",
        download_url: "javascript:alert(1)"
      }
    ])

    get data_dumps_path

    assert_response :success
    assert_includes @response.body, "artsdata://dumps/core-minus-provenance/latest"
    assert_not_includes @response.body, 'href="artsdata://dumps/core-minus-provenance/latest"'
    assert_not_includes @response.body, 'href="javascript:alert(1)"'
    assert_includes @response.body, "Not available"
  end

  test "data dumps page should show unavailable message on MCP failure" do
    mock_service = mock
    mock_service.stubs(:dumps).returns([])
    mock_service.stubs(:error).returns("MCP request failed with HTTP 500")
    ArtsdataMcpService.stubs(:new).returns(mock_service)

    get data_dumps_path

    assert_response :success
    assert_includes @response.body, "Artsdata dump metadata is temporarily unavailable."
  end

  test "data dumps page should include JSON-LD structured data with a CSP nonce" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([
      {
        translation_key: "core_minus_provenance_latest",
        title: "Artsdata core minus provenance",
        description: "Core dump",
        version: "2026-09-01T05_18_57",
        resource_uri: "artsdata://dumps/core-minus-provenance/latest",
        data_dump_uri: "http://kg.artsdata.ca/databus/example/artifact",
        distribution_uri: "http://kg.artsdata.ca/databus/example/distribution",
        artifact_uri: "http://kg.artsdata.ca/databus/example/artifact",
        media_type: "application/n-triples",
        byte_size: 123_456,
        download_url: "https://example.test/core.ttl.gz"
      }
    ])

    get data_dumps_path

    assert_response :success
    doc = Nokogiri::HTML(@response.body)
    script = doc.at_css('script[type="application/ld+json"]')
    assert script.present?, "expected a JSON-LD <script> tag"
    assert script["nonce"].present?, "expected the script tag to carry a CSP nonce"

    payload = JSON.parse(script.text)
    assert_equal "http://www.example.com/context/dump-distribution.jsonld", payload["@context"]
    node = payload["@graph"].first
    assert_equal "http://kg.artsdata.ca/databus/example/distribution", node["id"]
    assert_equal "dcat:Distribution", node["type"]

    # "@context" is a dereferenceable URL, not an inline object, precisely so tooling
    # that assumes @context is always a string (many browser extensions/link-preview
    # bots do) doesn't crash trying to call string methods on it.
    get payload["@context"]
    assert_response :success
    context_document = JSON.parse(@response.body)
    assert_equal "http://www.w3.org/ns/dcat#", context_document["@context"]["dcat"]
    assert_equal "https://example.test/core.ttl.gz", node["downloadURL"]
    assert_equal 123_456, node["byteSize"]
  end

  test "data dumps JSON-LD should exclude dumps without a safe download url" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([
      {
        translation_key: "unsafe",
        title: "Unsafe dump",
        distribution_uri: "http://kg.artsdata.ca/databus/unsafe/distribution",
        download_url: "javascript:alert(1)"
      },
      {
        translation_key: "safe",
        title: "Safe dump",
        distribution_uri: "http://kg.artsdata.ca/databus/safe/distribution",
        download_url: "https://example.test/safe.ttl.gz"
      }
    ])

    get data_dumps_path

    assert_response :success
    doc = Nokogiri::HTML(@response.body)
    payload = JSON.parse(doc.at_css('script[type="application/ld+json"]').text)
    ids = payload["@graph"].map { |node| node["id"] }
    assert_equal ["http://kg.artsdata.ca/databus/safe/distribution"], ids
  end

  test "data dumps page should omit the JSON-LD script tag when there are no dumps" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([])

    get data_dumps_path

    assert_response :success
    assert_not_includes @response.body, "application/ld+json"
  end

  test "data dumps page should omit the JSON-LD script tag on MCP failure" do
    mock_service = mock
    mock_service.stubs(:dumps).returns([])
    mock_service.stubs(:error).returns("MCP request failed with HTTP 500")
    ArtsdataMcpService.stubs(:new).returns(mock_service)

    get data_dumps_path

    assert_response :success
    assert_not_includes @response.body, "application/ld+json"
  end

  test "data dumps page should render meta description and canonical link" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([])

    get data_dumps_path

    assert_response :success
    assert_includes @response.body, 'name="description"'
    assert_includes @response.body, 'rel="canonical"'
    assert_includes @response.body, 'href="http://www.example.com/data-dumps"'
  end

  test "data dumps page canonical url should self-canonicalize for the french locale" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([])

    get data_dumps_path(locale: :fr)

    assert_response :success
    assert_includes @response.body, 'href="http://www.example.com/fr/data-dumps"'
  end

  test "data dumps page should show the MCP endpoint note" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([])

    get data_dumps_path

    assert_response :success
    assert_includes @response.body, Rails.application.config.artsdata_mcp_endpoint
  end

  test "data dumps page download link should have an accessible label with title, media type and size" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([
      {
        translation_key: "core_minus_provenance_latest",
        title: "Artsdata core minus provenance",
        media_type: "application/n-triples",
        byte_size: 1_048_576,
        distribution_uri: "http://kg.artsdata.ca/databus/example/distribution",
        download_url: "https://example.test/core.ttl.gz"
      }
    ])

    get data_dumps_path

    assert_response :success
    assert_includes @response.body, 'aria-label="Download Artsdata core minus provenance (application/n-triples, 1 MB)"'
  end
end
