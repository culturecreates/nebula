class GithubController < ApplicationController
  before_action :user_signed_in?, only: [:workflows, :sparqls]

  # Exchange the code for an access token
  # This is used in the callback method after user authorizes the app
  # The token is stored in the session for subsequent API calls
  # The token is valid for a limited time, usually over 6 hours
  # See more https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app#using-the-web-application-flow-to-generate-a-user-access-token
  def callback
    code = params["code"]

    token_data = exchange_code(code)

    if token_data.key?("access_token")
      token = token_data["access_token"]
      expires_in = token_data["expires_in"]
      flash.notice = "Successfully authenticated with GitHub."
      session[:github_authenticated] = true
      session[:github_expires_in] = expires_in # seconds. usually over 6 hrs
      session[:github_authenticated_time] = Time.now.utc.iso8601
      
      user_info = user_info(token)
      session[:handle] = user_info["login"]
      session[:name] = user_info["name"] || user_info["login"]
      session[:token] = token

      # configure teams
      teams = user_teams(token)
      user_teams = teams.map{ |team| { team["id"] => team["name"] } }
      session[:teams] = user_teams
      databus_accounts = teams.select{ |t| t.dig("parent","slug") == "databus"}.map {|t| t["slug"]}
      session[:accounts] = databus_accounts

      # user_repos = user_repos(token)
      # session[:repos] = user_repos.map { |repo| repo["name"] }
    else
      flash.alert = "Authorized, but unable to exchange code #{code} for token."
    end
    redirect_to root_path 
  end

  # List of workflows in the repository
  def workflows
    uri = URI("https://api.github.com/repos/culturecreates/footlight-aggregator/actions/runs?per_page=10")
    req = Net::HTTP::Get.new(uri)
    req['Accept'] = 'application/vnd.github.v3+json'
  
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
      http.request(req)
    }
    @workflows = JSON.parse(res.body)["workflow_runs"]
  end

  # List of SPARQL queries in the repository 
  def sparqls
      uri = URI("https://api.github.com/repos/artsdata-stewards/artsdata-actions/contents/queries")
      @sparqls = GithubService.info(nil, uri)
      @sparqls.select! { |sparql| sparql["download_url"].present?} # skip directories
  end

  def logout!
    flash.notice = "You have been logged out of GitHub."
    logout
    redirect_to root_path
  end

  private  

  # Get user information from GitHub API
  def user_info(token)
    uri = URI("https://api.github.com/user")
    GithubService.info(token, uri)
  end

  # Get user repositories from GitHub API
  def user_repos(token)
    uri = URI("https://api.github.com/user/repos")
    GithubService.info(token, uri)
  end

  # Get user teams from GitHub API
  def user_teams(token)
   # /orgs/{org}/teams
    uri = URI("https://api.github.com/user/teams")
    GithubService.info(token, uri)
  end

  # Exchange the code for an access token
  # See more https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authorizing-oauth-apps#web-application-flow
  # This is used in the callback method
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
