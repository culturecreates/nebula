class FootlightController < ApplicationController
  # GET /footlight/export?uri=
  # Export the graph as viewed by Footlight Aggregator for CMS import
  def export 
    uri = params[:uri]

    # get the source graph from URI
    select_query = "select ?graph where { graph ?graph { <#{uri}> a ?type } }"
    solutions = ArtsdataApi::SparqlService.client.query(select_query)
    source = solutions.first.graph.value if solutions.first&.bound?(:graph)

    redirect_to home_path, alert: "No source graph found for URI: #{uri}" and return if source.blank?
    
    # source = "http://kg.artsdata.ca/culture-creates/artsdata-planet-ville-de-laval/calendrier-activites"
    version = params[:version] || "v3"
    case version
    when "v2"
      redirect_to dereference_external_path(uri: cms_link_v2(uri, source)), status: 303, allow_other_host: true
    when "v3"
      redirect_to dereference_external_path(uri: cms_link_v3(uri, source)), status: 303, allow_other_host: true
    end 

  end


  def cms_link_v2(uri, source)
    "https://api.artsdata.ca/query?frame=event_footlight&format=jsonld&sparql=https://raw.githubusercontent.com/culturecreates/footlight-aggregator/main/sparql/query-event-uri-v2.sparql&uri=#{CGI.escape(uri)}&source=#{CGI.escape(source)}"
  end

  def cms_link_v3(uri, source)
    "https://api.artsdata.ca/query?frame=event_footlight&format=jsonld&sparql=https://raw.githubusercontent.com/culturecreates/footlight-aggregator/main/sparql/query-event-uri-v3.sparql&uri=#{CGI.escape(uri)}&source=#{CGI.escape(source)}"
  end

end
