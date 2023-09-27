module DereferenceHelper

  def dereference_helper(id)
    query = RDF::Query.new do
     pattern [RDF::URI(id), RDF::URI("http://www.w3.org/2000/01/rdf-schema#label"), :label]
     pattern [RDF::URI(id), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :type]
    end
    solution = @entity.graph.query(query).first
    return solution unless solution.blank?

    data = {label:"External resource", type:""}
    solution = OpenStruct.new(data)
    solution
  end

  def use_prefix(str)
    str.gsub("http://schema.org/","schema:")
  end
end
