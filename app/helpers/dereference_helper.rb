module DereferenceHelper

  def top_type(string)
    if [  "http://schema.org/TheaterEvent",
          "http://schema.org/DanceEvent",
          "http://schema.org/MusicEvent",
          "http://schema.org/EventSeries" ].include?(string)
      "http://schema.org/Event"
    elsif [ "http://schema.org/PerformingArtsTheater",
            "http://schema.org/Museum",
            "http://schema.org/MusicVenue",
            "http://schema.org/CivicStructure",
            "http://schema.org/EventVenue"].include?(string)
      "http://schema.org/Place"
    elsif [ "http://schema.org/PerformingGroup",
            "http://schema.org/DanceGroup",
            "http://schema.org/MusicGroup",
            "http://schema.org/TheaterGroup",
            "http://schema.org/Corporation",
            "http://schema.org/GovernmentOrganization",
            "http://schema.org/NGO"].include?(string)
      "http://schema.org/Organization"
    else
      string
    end
  end

  def dereference_helper(id)
    query = RDF::Query.new do
      pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
    end
    solution = @entity.graph.query(query).first 

    if solution.present? && solution.type
      top_level_type = top_type(solution.type.value)
                     
      if top_level_type == "http://schema.org/PostalAddress"
        query = RDF::Query.new do
          pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
          pattern [RDF::URI(id), RDF::URI("http://schema.org/streetAddress"), :streetAddress]
          pattern [RDF::URI(id), RDF::URI("http://schema.org/addressLocality"), :addressLocality]
          pattern [RDF::URI(id), RDF::URI("http://schema.org/postalCode"), :postalCode]
        end
      elsif top_level_type == "http://schema.org/Event" 
        query = RDF::Query.new do
          pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label]
          pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
          pattern [RDF::URI(id), RDF::URI("http://schema.org/startDate"), :startDate]
          pattern [RDF::URI(id), RDF::URI("http://schema.org/location"), :location]
        end
      elsif top_level_type == "http://schema.org/Place"
        query = RDF::Query.new do
          pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label]
          pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
          pattern [RDF::URI(id), RDF::URI("http://schema.org/addressLocality"), :addressLocality]
          pattern [RDF::URI(id), RDF::URI("http://schema.org/postalCode"), :postalCode]
        end
      end
    else
      query = RDF::Query.new do
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label]
        pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
      end
    end

    @entity.graph.query(query).first

  end

end
