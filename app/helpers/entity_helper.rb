module EntityHelper

  # Try to find a label or name for the URI
  # Otherwise display the URI
  def display_label(uri, check_shacl: true)
    return nil unless uri

    if check_shacl
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
    end


    # Get labels 
    link = entity_path(uri: uri)
    query = RDF::Query.new
    query.patterns <<  RDF::Query::Pattern.new(RDF::URI(uri), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label, {optional: true} )
    query.patterns << RDF::Query::Pattern.new(RDF::URI(uri), RDF::URI("http://schema.org/name"), :name, {optional: true} )
    solution = @entity.graph.query(query)
    if solution.first.count > 0
      label =  solution.first[:name]  ||  solution.first[:label] || "missing"
      "<a href='#{link}' rel='nofollow' target='_top'>#{label}</a>#{message}".html_safe
    else
      display_object(RDF::URI(uri))
    end
  end

  # Display RDF objects which may be URIs, blank nodes, literals or RDF statements.
  def display_object(obj)
    return if obj.nil?
    if obj.statement? 
      display_statement(obj)
    elsif obj.uri?
      display_uri(obj)
    elsif obj.literal?
      display_literal(obj)
    elsif obj.node? # blank node
      "Node (#{obj.to_s.truncate(20)})"
    else
      raise StandardError.new "Unexpected RDF class: #{obj.class.to_s}"
    end
  end

  # Display RDF object literal
  def display_literal(obj)
    if obj.value.starts_with?("http")
      "<span>#{obj.value} <a href='#{obj.value}' title='Open external webpage' target='_blank'>&nbsp;#{ render partial: 'shared/icon_link'}</a></span>".html_safe
    elsif obj.datatype?
      "<span>#{obj.value}<span style='color:gray;font-size: small'>&nbsp;#{use_prefix(obj.datatype)}</span></span>".html_safe 
    elsif obj.value.starts_with?("<a href='/")
      "<span><a href='/#{ I18n.locale }/#{obj.value.split("<a href='/").last}<span>".html_safe
    else
      word_max = 30
      if obj.value.split.length > word_max
        <<-HTML.html_safe
          <div data-controller='read-more' data-read-more-more-text-value='Read more ↓' data-read-more-less-text-value='Read less ↑'>
            <span class='nebula-field' data-read-more-target='content'>
              #{literal_with_lang(obj)}
            </span>
            <div class="d-flex justify-content-end">
              <button type='button' class='btn btn-outline' data-action='read-more#toggle'>Read more ↓</button>
            </div>
          </div>
        HTML
      else
        "<span>#{literal_with_lang(obj)}</span>".html_safe
      end
    end
  end

  def literal_with_lang(obj)
    if obj.language
      "#{obj.value}<span style='color:gray;font-size: small'>&nbsp;#{obj.language}</span>".html_safe  
    else
      obj.value
    end
  end

 # Display RDF::URI as a link
  def display_uri(uri)
    #uri = CGI.unescape(uri) # to correctly display cases with '#this' like http://localhost:3000/entity?uri=https%3A%2F%2Fsaumier.github.io%2Fgregory-saumier-finch.ttl%23this
    link = entity_path(uri: uri)
    char_max = 60
    display_uri = use_prefix(uri)
    display_uri = remove_protocol(display_uri)
    if display_uri.length > char_max
      display_uri = display_uri[0..char_max/2] + "..." + display_uri[-(char_max/2)..-1] 
    end
    
    # Properly escape values for security
    escaped_link = ERB::Util.html_escape(link)
    escaped_display_uri = ERB::Util.html_escape(display_uri)
    escaped_uri = ERB::Util.html_escape(uri)
    
    # Wrap in a container with clipboard functionality
    <<-HTML.html_safe
      <span class="uri-link-container--floating" data-controller="clipboard" data-clipboard-success-content-value="URI copied">
        <a href='#{escaped_link}' rel='nofollow' target='_top'>#{escaped_display_uri}</a>
        <span data-clipboard-target="source" style="display:none;">#{escaped_uri}</span>
        <a class="copy-uri-icon--floating copy-uri-icon" data-action="clipboard#copy" data-clipboard-target="button" title="Copy URI">
          <i class="fa-regular fa-copy"></i>
        </a>
      </span>
    HTML
  end

  def remove_protocol(uri)
    uri.to_s.gsub(%r{^https?://}, '')
  end

  def display_reference(uri)
    query = RDF::Query.new do
      pattern [RDF::URI(uri), :p, :o]
    end
    @entity.graph.query(query)
  end

  def display_statement(statement)
    "<< #{display_object(statement.subject)} #{display_object(statement.predicate)} #{display_object(statement.object)} >>".html_safe
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
    return "#{Rails.application.config.graph_api_endpoint}/resource?uri=#{CGI.escape(uri)}"
  end

  def ranked_link(entity)
    if entity.type == "http://schema.org/Person" || entity.type == "http://schema.org/Organization"  || entity.type == "http://schema.org/Event" 
      return "http://api.artsdata.ca/ranked/#{entity.k_number}?format=jsonld"
    end
  end

  def query_ranked_link(entity)
      if entity.type == "http://schema.org/Person" || entity.type == "http://schema.org/Organization"
        return "http://api.artsdata.ca/query?adid=#{entity.k_number}&format=jsonld&frame=ranked_org_person_footlight&sparql=ranked_org_person_footlight"
      elsif entity.type == "http://schema.org/Place"
        return "http://api.artsdata.ca/query?adid=#{entity.k_number}&format=jsonld&frame=ranked_place_footlight&sparql=ranked_place_footlight"
      elsif entity.type == "http://schema.org/Event"
        return "http://api.artsdata.ca/query?adid=#{entity.k_number}&format=jsonld&sparql=ranked_event_footlight"
      end
  end

  def aggregator_place_v2_link(entity)
      if entity.type == "http://schema.org/Place"
       return "http://api.artsdata.ca/query?uri=http://kg.artsdata.ca/resource/#{entity.k_number}&format=jsonld&frame=ranked_place_footlight&sparql=https://raw.githubusercontent.com/culturecreates/footlight-aggregator/main/sparql/query-place-v2.sparql"
      end
  end

  def capacoa_ranked_link(entity)
    if entity.type == "http://schema.org/Person" || entity.type == "http://schema.org/Organization"
      return "http://api.artsdata.ca/query?adid=#{entity.k_number}&format=jsonld&frame=capacoa/member2&sparql=capacoa/member_detail2"
    end
  end

  def cms_link(entity) # for non-artsdata URIs
    return "http://api.artsdata.ca/resource?uri=#{CGI.escape(entity.entity_uri)}"
  end

  def is_authoritative(uri)
    if uri.starts_with?("http://kg.artsdata.ca")
      true
    else
      false
    end
  end
end
