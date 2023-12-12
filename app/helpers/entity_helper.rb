module EntityHelper
  def display_label(id)
    return nil unless id
    link = entity_path(uri: id)
 
    query = RDF::Query.new do
      pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label, nil, optional: true]
    end
    solution = @entity.graph.query(query)
    if solution.count > 0
      response = "<a href='#{link}' target='_top'>#{solution.first[:label].value}</a>".html_safe
    else
      query = RDF::Query.new do
        pattern [RDF::URI(id), RDF::URI("http://schema.org/name"), :name ]
      end
      solution = @entity.graph.query(query)
      if solution.count > 0
        response = "<a href='#{link}' target='_top'>#{solution.first[:name].value}</a>".html_safe
      else
        if id.starts_with?("http")
          response = "<a href='#{link}' target='_top'>#{id.split("/").last.split("#").last}</a>".html_safe
        else
          response = id
        end
        
      end
    end

    response
  end

  def display_object(obj)
    # Todo: Add anchor link button for literals that look like urls
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
    "<a href=\"/entity?uri=#{CGI.escape(uri)}\">#{use_prefix(uri)}</a>".html_safe
  end

  def display_reference(id)
    query = RDF::Query.new do
      pattern [RDF::URI(id), :p, :o]
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

  def graphdb_link(id)
    return "https://db.artsdata.ca/resource?uri=#{id}"
  end

  def derived_link(id)
    return "https://api.artsdata.ca/resource?uri=#{id}"
  end
end
