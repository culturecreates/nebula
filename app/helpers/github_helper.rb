module GithubHelper

  def humanize(sparql_url)
    sparql_url.split("/").last.split(".").first.humanize
  end
end
