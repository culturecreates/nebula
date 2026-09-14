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
    assert_includes @response.body, "Artsdata Core data dumps"
    assert_includes @response.body, "No Artsdata Core dump resources are currently published."
  end

  test "data dumps page should render dump metadata" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([
      {
        translation_key: "core_minus_provenance_latest",
        title: "Artsdata core minus provenance",
        description: "Core dump",
        version: "2026-09-01T05_18_57",
        resource_uri: "artsdata://dumps/core-minus-provenance/latest",
        data_dump_uri: "http://kg.artsdata.ca/databus/example/distribution",
        download_url: "https://example.test/core.ttl.gz"
      }
    ])

    get data_dumps_path

    assert_response :success
    assert_includes @response.body, "2026-09-01T05_18_57"
    assert_includes @response.body, "artsdata://dumps/core-minus-provenance/latest"
    assert_includes @response.body, "https://example.test/core.ttl.gz"
  end

  test "data dumps page should render in french" do
    ArtsdataMcpService.any_instance.stubs(:dumps).returns([])

    get data_dumps_path(locale: :fr)

    assert_response :success
    assert_includes @response.body, "Jeux de données Artsdata Core"
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
    assert_includes @response.body, "Artsdata Core dump metadata is temporarily unavailable."
  end
end
