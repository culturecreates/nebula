class GithubController < ApplicationController

  def callback
    code = params["code"]

    token_data = exchange_code(code)

    if token_data.key?("access_token")
      token = token_data["access_token"]
      
      user_info = user_info(token)
      session[:handle] = user_info["login"]
      session[:name] = user_info["name"]

      # user_repos = user_repos(token)
      # session[:repos] = user_repos.map { |repo| repo["name"] }

      # nebula_sparqls = nebula_sparqls(token)
      # session[:nebula_sparqls] = nebula_sparqls.map { |sparql| sparql["download_url"].split('app/services/sparqls/')[1].split('.')[0]}
      
    else
      flash.alert = "Authorized, but unable to exchange code #{code} for token."

    end
    redirect_to root_path 
  end

  private 

  def user_info(token)
    uri = URI("https://api.github.com/user")
    info(token, uri)
  end

  def user_repos(token)
    uri = URI("https://api.github.com/user/repos")
    info(token, uri)
  end

  def nebula_sparqls(token) 
    uri = URI("https://api.github.com/repos/culturecreates/nebula/contents/app/services/sparqls/custom")
    info(token, uri)
  end


  def info(token, uri)
    result = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      body = {"access_token" => token}.to_json
  
      auth = "Bearer #{token}"
      headers = {"Accept" => "application/json", "Content-Type" => "application/json", "Authorization" => auth}
  
      http.send_request("GET", uri.path, body, headers)
    end
  
    parse_response(result)
  end

  

  def parse_response(response)
    case response
    when Net::HTTPOK
      JSON.parse(response.body)
    else
      puts response
      puts response.body
      {}
    end
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
  
    parse_response(result)
  end
end
