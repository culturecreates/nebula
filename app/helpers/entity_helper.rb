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
      uri = uri.value if uri.class == RDF::URI
      if uri.starts_with?("http")
        "<a href='#{link}' target='_top'>#{uri.split("/").last.split("#").last}</a>".html_safe
      else
        uri
      end
    end
  end

  # Display RDF objects which may be URIs, blank nodes or literals.
  def display_object(obj)
    if obj.node? # blank node
      "Node (#{obj.to_s.truncate(20)})"
    elsif obj.uri?
      display_uri(obj)
    elsif obj.literal?
      display_literal(obj)
    else
      raise StandardError.new "Unexpected RDF class: #{obj.class.to_s}"
    end
  end

  # Display RDF object literal
  def display_literal(obj)
    if obj.language
      "<span>#{obj.value}<span style='color:gray;font-size: small'>&nbsp;#{obj.language}</span></span>".html_safe  
    elsif obj.value.starts_with?("http")
      "<span>#{obj.value} <a href='#{obj.value}' target='_blank'>&nbsp;#{ render partial: 'shared/icon_link'}</a></span>".html_safe
    elsif obj.datatype?
      "<span>#{obj.value}<span style='color:gray;font-size: small'>&nbsp;#{use_prefix(obj.datatype)}</span></span>".html_safe 
    elsif obj.value.starts_with?("<a href='/")
      "<span><a href='/#{ I18n.locale }/#{obj.value.split("<a href='/").last}<span>".html_safe
    else
      word_max = 50
      if obj.value.split.length > word_max
      "<span title='#{obj.value}'>#{truncate_words(obj.value, 50)}</span>".html_safe
      else
      "<span>#{obj.value}</span>".html_safe
      end

    end
  end

  def truncate_words(text, num_words, omission: '...')
    words = text.split
    words.length > num_words ? words[0...num_words].join(' ') + omission : text
  end


 # Display RDF::URI as a link
  def display_uri(uri)
    uri = CGI.unescape(uri) # to correctly display cases with '#this' like http://localhost:3000/entity?uri=https%3A%2F%2Fsaumier.github.io%2Fgregory-saumier-finch.ttl%23this
    link = entity_path(uri: uri)
    "<a href='#{link}' target='_top'>#{use_prefix(uri)}</a>".html_safe
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
