require "json"
require "net/http"
require "securerandom"

class ArtsdataMcpService
  PROTOCOL_VERSION = "2025-06-18".freeze
  DUMP_RESOURCE_PREFIX = "artsdata://dumps/".freeze

  class Error < StandardError; end

  attr_reader :error

  def initialize(endpoint: Rails.application.config.artsdata_mcp_endpoint)
    @endpoint = URI.parse(endpoint)
  end

  def dumps
    @error = nil
    list_resources
      .select { |resource| resource["uri"].to_s.start_with?(DUMP_RESOURCE_PREFIX) }
      .map { |resource| normalize_dump(resource, read_resource(resource["uri"])) }
  rescue Error => e
    @error = e.message
    Rails.logger.error("Artsdata MCP dump fetch error: #{e.message}")
    []
  end

  private

  def list_resources
    rpc("resources/list").fetch("resources", [])
  end

  def read_resource(resource_uri)
    result = rpc("resources/read", { uris: [resource_uri] })
    content = result.fetch("contents", []).first || {}
    JSON.parse(content.fetch("text", "{}"))
  rescue JSON::ParserError => e
    raise Error, "Invalid MCP resource payload for #{resource_uri}: #{e.message}"
  end

  def rpc(method, params = nil)
    request = Net::HTTP::Post.new(@endpoint.request_uri)
    request["Accept"] = "application/json"
    request["Content-Type"] = "application/json"
    request["MCP-Protocol-Version"] = PROTOCOL_VERSION
    request.body = JSON.generate(
      {
        jsonrpc: "2.0",
        id: SecureRandom.uuid,
        method: method,
        params: params
      }.compact
    )

    response = Net::HTTP.start(@endpoint.host, @endpoint.port, use_ssl: @endpoint.scheme == "https") do |http|
      http.request(request)
    end

    body = begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end

    raise Error, body.dig("error", "message") if body&.dig("error", "message").present?
    raise Error, "MCP request failed with HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    raise Error, "Invalid MCP response" if body.nil?

    body.fetch("result", {})
  rescue StandardError => e
    raise e if e.is_a?(Error)

    raise Error, e.message
  end

  def normalize_dump(resource, manifest)
    {
      resource_uri: resource["uri"],
      translation_key: resource_translation_key(resource["uri"]),
      title: resource["title"].presence || resource["name"],
      description: manifest["comment"].presence || resource["description"],
      version: manifest["version"],
      data_dump_uri: manifest["isVersionOf"].presence || manifest["id"],
      distribution_uri: manifest["id"],
      artifact_uri: manifest["isVersionOf"],
      download_url: manifest["downloadURL"] || manifest["downloadUrl"],
      media_type: manifest["mediaType"] || resource["mimeType"],
      byte_size: manifest["byteSize"]
    }
  end

  def resource_translation_key(resource_uri)
    resource_uri.to_s.delete_prefix(DUMP_RESOURCE_PREFIX).tr("/-", "_")
  end
end
