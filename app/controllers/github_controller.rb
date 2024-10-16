class GithubController < ApplicationController

  # See more https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app#using-the-web-application-flow-to-generate-a-user-access-token
  def callback
    code = params["code"]

    token_data = exchange_code(code)

    if token_data.key?("access_token")
      token = token_data["access_token"]
      
      user_info = user_info(token)
      session[:handle] = user_info["login"]
      session[:name] = user_info["name"] || user_info["login"]
      session[:token] = token

      # user_repos = user_repos(token)
      # session[:repos] = user_repos.map { |repo| repo["name"] }
    else
      flash.alert = "Authorized, but unable to exchange code #{code} for token."
    end
    redirect_to root_path 
  end

  def workflows
    uri = URI("https://api.github.com/repos/culturecreates/footlight-aggregator/actions/runs?per_page=10")
    req = Net::HTTP::Get.new(uri)
    req['Accept'] = 'application/vnd.github.v3+json'
  
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
      http.request(req)
    }
    @workflows = JSON.parse(res.body)["workflow_runs"]
  end

  def sparqls
      uri = URI("https://api.github.com/repos/artsdata-stewards/artsdata-actions/contents/queries")
      @sparqls = GithubService.info(nil, uri)
  end

  private 

  def user_info(token)
    uri = URI("https://api.github.com/user")
    GithubService.info(token, uri)
  end

  def user_repos(token)
    uri = URI("https://api.github.com/user/repos")
    GithubService.info(token, uri)
  end

  def exchange_code(code)
    params = {
      "client_id" => Rails.application.credentials.CLIENT_ID,
      "client_secret" => Rails.application.credentials.CLIENT_SECRET,
      "code" => code
    }
    result = Net::HTTP.post(
      URI("https://github.com/login/oauth/access_token"),
      URI.encode_www_form(params),
      {"Accept" => "application/json"}
    )
  
    GithubService.parse_response(result)
  end
end
