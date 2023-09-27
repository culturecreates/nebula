module EntityHelper
  def display_label(id)
    query = RDF::Query.new do
      pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label, nil, optional: true]
    end
    solution = @entity.graph.query(query)
    if solution.count > 0
      return solution.first[:label].value 
    else
      query = RDF::Query.new do
        pattern [RDF::URI(id), RDF::URI("http://schema.org/name"), :name ]
      end
      solution = @entity.graph.query(query)
      if solution.count > 0
        return solution.first[:name].value 
      else
        return id
      end
    end
  end

  def display_literal(literal)
    if literal["@language"]
      "#{literal['@value'].capitalize} @#{literal['@language']}" 
    elsif  literal["@value"]
      literal["@value"]
    else
      literal
    end
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
