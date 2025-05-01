class DatabusService
  attr_accessor :recon_uri, :errors, :latest_version

  def initialize(artifact_uri, user_uri = nil)
    @artifact_uri = URI.parse(artifact_uri)
    @user_uri = user_uri
    @errors = []
    @latest_version = nil
  end

  def push_lastest_artifact(artifact_uri)

    # Get latest version of the artifact
    @latest_version = get_latest_version(artifact_uri)
    return false if @latest_version.nil?
    
    # Define the API endpoint
    api_endpoint = "#{Rails.application.credentials.artsdata_databus_endpoint}/push_artifact_version?artifact_version_uri=#{CGI.escape(@latest_version)}&publisher=#{CGI.escape(@user_uri)}"
    uri = URI.parse(api_endpoint)

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
  end

  def get_latest_version(artifact_uri)
    # Define the API endpoint
    api_endpoint = "#{Rails.application.credentials.artsdata_databus_endpoint}/artifact/latest?artifact=#{CGI.escape(artifact_uri)}"
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