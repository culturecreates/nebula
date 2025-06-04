class GithubService
  def self.info(token, uri)
    result = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|

      if token
        body = {"access_token" => token}.to_json
        auth = "Bearer #{token}"
        headers = {"Accept" => "application/vnd.github+json", "X-GitHub-Api-Version" => "2022-11-28","Content-Type" => "application/json", "Authorization" => auth}
        http.send_request("GET", uri.path, body, headers)
      else
        headers = {"Accept" => "application/json", "Content-Type" => "application/json"}
        http.send_request("GET", uri.path, "", headers)
      end
      
    end
  
    parse_response(result)
  end

  # Class service to fetch information from GitHub API about the workflow schedule
  # TODO: call this from show artifact controller
  def self.schedule(workflow_url = nil)
    workflow_url ||= "https://api.github.com/repos/culturecreates/artsdata-orion/contents/.github/workflows/agoradanse-events.yml"
    uri = URI(workflow_url)
    json = info(nil, uri)
    return "No workflow found." if !json["content"]

    content = Base64.decode64(json["content"])
    yaml = YAML.load(content)
    schedule = yaml.dig(true, "schedule") || []
    return  "No cron schedule found in workflow." if schedule.empty?
     
    crons = []
    schedule.each { |s|  crons << s["cron"] }
    "Cron schedule: #{crons.join(', ')}"
  end

  def self.parse_response(response)
    case response
    when Net::HTTPOK
      JSON.parse(response.body)
    else
      puts response
      response.message
    end
  end

end