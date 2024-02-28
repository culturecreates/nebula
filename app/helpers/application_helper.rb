module ApplicationHelper

  # Returns the Github callback URL based on the environment
  def github_callback_url
      "#{request.protocol}#{request.domain}#{':' + request.port.to_s if request.port.present?}/github/callback"
  end

  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = "Artsdata"
    base_title += " DEV" if Rails.env.development?
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end

  def use_prefix(uri)

    return if uri.blank?

    uri = uri.value if uri.class != String

    
    uri_compact = uri.gsub("http://schema.org/","schema:")
      .gsub("http://kg.artsdata.ca/resource/","ad:")
      .gsub("http://kg.footlight.io/resource/","footlight-console:")
      .gsub("http://api.footlight.io/places/","footlight-cms-places:")
      .gsub("http://api.footlight.io/events/","footlight-cms-events:")
      .gsub("http://www.w3.org/2000/01/rdf-schema#","rdfs:")
      .gsub("http://www.w3.org/2002/07/owl#","owl:")
      .gsub("http://www.w3.org/2004/02/skos/core#","skos:")
      .gsub("http://www.w3.org/ns/prov#","prov:")
      .gsub("http://kg.artsdata.ca/databus/culture-creates/","databus:")
      .gsub("http://www.w3.org/ns/shacl#","shacl:")
      .gsub("http://www.wikidata.org/entity/","wd:")
      .gsub("http://www.w3.org/2001/XMLSchema#", "xsd:")
      .gsub("http://scenepro.ca#","sp:")

    if uri_compact.present?
      return uri_compact
    else
      return uri
    end
  end
end
