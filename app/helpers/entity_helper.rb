module EntityHelper

  # Try to find a label for the URI
  # Otherwise display the URI
  def display_label(uri)
    return nil unless uri

    link = entity_path(uri: uri)
    query = RDF::Query.new
    query.patterns <<  RDF::Query::Pattern.new(RDF::URI(uri), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label,{optional: true} )
    query.patterns << RDF::Query::Pattern.new(RDF::URI(uri), RDF::URI("http://schema.org/name"), :name,{optional: true} )

    solution = @entity.graph.query(query)
     
    if solution.count > 0
      label = solution.first[:name]  ||  solution.first[:label]
      "<a href='#{link}' target='_top'>#{label}</a>".html_safe
    else
      if uri.starts_with?("http")
        "<a href='#{link}' target='_top'>#{uri.split("/").last.split("#").last}</a>".html_safe
      else
        uri
      end
    end
  end

  # Display objects which may be URIs, language literals, or literals.
  def display_object(obj)
    if obj.uri?
      if obj.starts_with?("_:") 
        obj
      else 
        uri_link(obj)
      end
    else
      if obj.language
        language_literal(obj.value, obj.language)
      else
        obj
      end
    end
  end

  def language_literal(string, language)
    "<span>#{string} <span style='color:gray;font-size: small'>@#{language}</span></span>".html_safe  
  end

  def uri_link(uri)
    link = entity_path(uri: uri)
    "<a href=\"#{link}\">#{use_prefix(uri)}</a>".html_safe
  end

  def display_reference(uri)
    query = RDF::Query.new do
      pattern [RDF::URI(uri), :p, :o]
    end
    @entity.graph.query(query)
  end

  def date_display(date_time)
    begin
      I18n.l(Date.parse(date_time), format: :long)
    rescue
      ""
    end
   
  end

  def date_time_display(date_time)
    Time.zone = 'Eastern Time (US & Canada)'
    I18n.l(date_time.in_time_zone, format: :long)
  end

  def graphdb_link(uri)
    return "https://db.artsdata.ca/resource?uri=#{uri}"
  end

  def derived_link(uri)
    return "https://api.artsdata.ca/resource?uri=#{uri}"
  end
end
