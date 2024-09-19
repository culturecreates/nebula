class GithubService
  def self.info(token, uri)
    result = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      body = {"access_token" => token}.to_json
  
      auth = "Bearer #{token}"
      headers = {"Accept" => "application/json", "Content-Type" => "application/json", "Authorization" => auth}
  
      http.send_request("GET", uri.path, body, headers)
    end
  
    parse_response(result)
  end

  def self.parse_response(response)
    case response
    when Net::HTTPOK
      JSON.parse(response.body)
    else
      puts response
      puts response.body
      {}
    end
  end

end