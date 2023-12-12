module EntityHelper

  # Try to find a label or name for the URI
  # Otherwise display the URI
  def display_label(uri)
    return nil unless uri

    # Check for SHACL errors 
    query = RDF::Query.new
    query.patterns << RDF::Query::Pattern.new(:shacl, RDF::URI("http://www.w3.org/ns/shacl#focusNode"), RDF::URI(@entity.entity_uri) )
    query.patterns << RDF::Query::Pattern.new(:shacl, RDF::URI("http://www.w3.org/ns/shacl#resultPath"), RDF::URI(uri) )
    query.patterns << RDF::Query::Pattern.new(:shacl, RDF::URI("http://www.w3.org/ns/shacl#resultMessage"), :message )
    solution = @entity.graph.query(query)
    if solution.first
      message = "<p style='color:red;'>#{solution.first[:message]}".html_safe
    else
      message = nil
    end


    # Get labels 
    link = entity_path(uri: uri)
    query = RDF::Query.new
    query.patterns <<  RDF::Query::Pattern.new(RDF::URI(uri), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label, {optional: true} )
    query.patterns << RDF::Query::Pattern.new(RDF::URI(uri), RDF::URI("http://schema.org/name"), :name, {optional: true} )
    solution = @entity.graph.query(query)
    if solution.first.count > 0
      label =  solution.first[:name]  ||  solution.first[:label] || "missing"
      error =  solution.first[:label] || "missing"
      "<a href='#{link}' target='_top'>#{label}</a>#{message}".html_safe
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
    if obj.node? 
      obj
    elsif obj.uri?
      uri_link(obj)
    elsif obj.language
      language_literal(obj.value, obj.language)
    else
      obj
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
