class IcalController < ApplicationController

  def index
    uri = URI("https://api.github.com/repos/artsdata-stewards/artsdata-actions/contents/ical")
    @icals = GithubService.info(session[:token], uri)
    @icals.each do |ical|
      ical[:jsonld_url] = "https://api.artsdata.ca/query?format=jsonld&sparql=#{ical["download_url"]}"
      ical[:dereference_url] = dereference_external_url(uri: ical[:jsonld_url])
      ical[:feed_url] = "https://artsdata-ical-2b5d78f4cfc6.herokuapp.com/conversion/convert?url=" + URI.encode_www_form_component(ical[:jsonld_url])
    end
  end
  
end
