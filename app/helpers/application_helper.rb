module ApplicationHelper


  def use_prefix(uri)
    uri = uri.value if uri.class != String


    uri_compact = uri.gsub("http://schema.org/","schema:")
      .gsub("http://kg.artsdata.ca/resource/","")
      .gsub("http://kg.footlight.io/resource/","footlight-console:")
      .gsub("http://api.footlight.io/places/","footlight-places:")
      .gsub("http://api.footlight.io/events/","footlight-events:")
      .gsub("http://www.w3.org/2000/01/rdf-schema#","rdfs:")
      .gsub("http://www.w3.org/2002/07/owl#","owl:")
      .gsub("http://www.w3.org/2004/02/skos/core#","skos:")
      .gsub("http://www.w3.org/ns/prov#","prov:")
      .gsub("http://kg.artsdata.ca/databus/culture-creates/","databus:")

    if uri_compact.present?
      return uri_compact
    else
      return uri
    end
  end
end
