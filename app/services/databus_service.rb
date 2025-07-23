class DatabusService
  attr_accessor :artifact_uri, :user_uri, :errors, :latest_version

  def initialize(artifact_uri, user_uri = nil)
    @artifact_uri = URI.parse(artifact_uri)
    @user_uri = user_uri
    @errors = []
    @latest_version = nil
  end

  # Push the latest version of the artifact to Artsdata
  def push_lastest_artifact(artifact_uri)
    # Get latest version of the artifact
    @latest_version = get_latest_version(artifact_uri)
    return false if @latest_version.nil?
    api_endpoint = "#{Rails.application.config.artsdata_databus_endpoint}/push_artifact_version"
    # payload = {
    #   artifact_version_uri: @latest_version,
    #   publisher: @user_uri
    # }
    api_url = "#{api_endpoint}?artifact_version_uri=#{CGI.escape(@latest_version)}&publisher=#{CGI.escape(@user_uri)}"
    call_databus_api(api_url,"post")
  end

  # Delete all versions of the artifact from Databus
  def delete_artifact
      api_endpoint = "#{Rails.application.config.artsdata_databus_endpoint}"
      api_url = "#{api_endpoint}?artifact=#{CGI.escape(@artifact_uri.to_s)}&publisher=#{CGI.escape(@user_uri)}"
      call_databus_api(api_url,"delete")
  end

  def call_databus_api(url, action)
    uri = URI.parse(url)

    if action == "post"
     # Make the HTTP POST request
     begin
       response = Net::HTTP.post(uri, "")
       if response.code.to_i == 201
         true
       else
         @errors << "API Error: #{response.code} - #{response.message}"
         false
       end
     rescue StandardError => e
       @errors << "Request failed: #{e.message}"
       false
     end
    elsif action == "delete"
      # Make the HTTP DELETE request
      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == "https"
        request = Net::HTTP::Delete.new(uri.request_uri)
        response = http.request(request)
        if response.code.to_i == 200 || response.code.to_i == 204
          true
        else
          @errors << "DELETE API Error: #{response.code} - #{response.message}"
          false
        end
      rescue StandardError => e
        @errors << "DELETE Request failed: #{e.message}"
        false
      end
    end
  end

  def get_artifact_uri(artifact_uri)
    # Check if the artifact_uri is valid
    if artifact_uri.nil? || artifact_uri.empty?
      @errors << "Invalid artifact URI."
      return nil
    end

    # Parse the artifact_uri to ensure it's a valid URI
    begin
      parsed_uri = URI.parse(artifact_uri)
      if parsed_uri.scheme.nil? || parsed_uri.host.nil?
        @errors << "Invalid artifact URI format."
        return nil
      end
    rescue URI::InvalidURIError => e
      @errors << "Invalid artifact URI: #{e.message}"
      return nil
    end

    
  end

  def get_latest_version(artifact_uri)
    # Define the API endpoint
    api_endpoint = "#{Rails.application.config.artsdata_databus_endpoint}/artifact/latest?artifact=#{CGI.escape(artifact_uri)}"
    begin
      response = Net::HTTP.get_response(URI.parse(api_endpoint))
      if response.code.to_i == 200
        version = JSON.parse(response.body)["artifacts"][0]["latestVersion"]
        "#{@artifact_uri}/#{version}#Dataset"
      else
        @errors << "API Error: #{response.code} - #{response.message}"
        nil
      end
    rescue StandardError => e
      @errors << "Request failed: #{e.message}"
      nil
    end
  end
end