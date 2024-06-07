module DereferenceHelper

  def dereference_helper(id)
    query = RDF::Query.new do
     pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
    end
    solution = @entity.graph.query(query).first 

    if solution.present? && solution.type == "http://schema.org/PostalAddress"
      query = RDF::Query.new do
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
        pattern [RDF::URI(id), RDF::URI("http://schema.org/streetAddress"), :streetAddress]
        pattern [RDF::URI(id), RDF::URI("http://schema.org/addressLocality"), :addressLocality]
        pattern [RDF::URI(id), RDF::URI("http://schema.org/postalCode"), :postalCode]
      end
    elsif solution.present? && (solution.type == "http://schema.org/Event" || solution.type == "http://schema.org/EventSeries")
      query = RDF::Query.new do
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label]
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
        pattern [RDF::URI(id), RDF::URI("http://schema.org/startDate"), :startDate]
        pattern [RDF::URI(id), RDF::URI("http://schema.org/location"), :location]
        #pattern [RDF::URI(id), RDF::URI("http://www.w3.org/ns/prov#wasDerivedFrom"), :dataid]
      end
    elsif solution.present? && solution.type == "http://schema.org/Place"
      query = RDF::Query.new do
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label]
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
        pattern [RDF::URI(id), RDF::URI("http://schema.org/addressLocality"), :addressLocality]
        pattern [RDF::URI(id), RDF::URI("http://schema.org/postalCode"), :postalCode]
        #pattern [RDF::URI(id), RDF::URI("http://www.w3.org/ns/prov#wasDerivedFrom"), :dataid]
      end
    else
      query = RDF::Query.new do
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label]
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
       # pattern [RDF::URI(id), RDF::URI("http://www.w3.org/ns/prov#wasDerivedFrom"), :dataid]
      end
    end

    @entity.graph.query(query).first

  end

end
