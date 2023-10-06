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
      end
    else
      query = RDF::Query.new do
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label]
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
      end
    end

    solution = @entity.graph.query(query).first
    return solution.to_h unless solution.blank?

    # handle blank
    {label: nil, type: ""}
  end

end
