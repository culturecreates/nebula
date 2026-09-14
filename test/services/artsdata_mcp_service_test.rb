require "test_helper"

class ArtsdataMcpServiceTest < ActiveSupport::TestCase
  ENDPOINT = "https://mcp.example.test/mcp".freeze
  RESOURCE_URI = "artsdata://dumps/core-minus-provenance/latest".freeze
  ARTIFACT_URI = "http://kg.artsdata.ca/databus/culture-creates/artsdata-dump/core-minus-provenance".freeze
  DISTRIBUTION_URI = "http://kg.artsdata.ca/databus/culture-creates/artsdata-dump/core-minus-provenance/2026-09-01T05_18_57#artsdata-2026-09-01-core-minus-provenance.ttl.gz".freeze
  DOWNLOAD_URL = "https://example.test/artsdata-2026-09-01-core-minus-provenance.ttl.gz".freeze

  test "dumps returns normalized MCP dump metadata" do
    stub_request(:post, ENDPOINT)
      .with { |request| JSON.parse(request.body)["method"] == "resources/list" }
      .to_return(
        status: 200,
        body: JSON.generate(
          jsonrpc: "2.0",
          id: "1",
          result: {
            resources: [
              {
                "uri" => RESOURCE_URI,
                "title" => "Artsdata core minus provenance",
                "description" => "Latest dump metadata"
              },
              {
                "uri" => "artsdata://other/resource",
                "title" => "Ignore me"
              }
            ]
          }
        ),
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:post, ENDPOINT)
      .with do |request|
        body = JSON.parse(request.body)
        body["method"] == "resources/read" && body.dig("params", "uris") == [RESOURCE_URI]
      end
      .to_return(
        status: 200,
        body: JSON.generate(
          jsonrpc: "2.0",
          id: "2",
          result: {
            contents: [
              {
                "uri" => RESOURCE_URI,
                "mimeType" => "application/ld+json",
                "text" => JSON.generate(
                  {
                    "id" => DISTRIBUTION_URI,
                    "comment" => "Monthly core graph snapshot",
                    "version" => "2026-09-01T05_18_57",
                    "isVersionOf" => ARTIFACT_URI,
                    "downloadURL" => DOWNLOAD_URL,
                    "mediaType" => "text/turtle",
                    "byteSize" => 8581868
                  }
                )
              }
            ]
          }
        ),
        headers: { "Content-Type" => "application/json" }
      )

    dumps = ArtsdataMcpService.new(endpoint: ENDPOINT).dumps

    assert_equal 1, dumps.length
    assert_equal RESOURCE_URI, dumps.first[:resource_uri]
    assert_equal "core_minus_provenance_latest", dumps.first[:translation_key]
    assert_equal DISTRIBUTION_URI, dumps.first[:data_dump_uri]
    assert_equal ARTIFACT_URI, dumps.first[:artifact_uri]
    assert_equal DOWNLOAD_URL, dumps.first[:download_url]
  end

  test "dumps returns empty array when the MCP server fails" do
    stub_request(:post, ENDPOINT).to_return(status: 500, body: "error")

    service = ArtsdataMcpService.new(endpoint: ENDPOINT)

    assert_equal [], service.dumps
    assert_equal "MCP request failed with HTTP 500", service.error
  end
end
