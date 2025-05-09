class GraphEditorService
  require 'sparql/client'

  def initialize
    @client = SPARQL::Client.new("http://db.artsdata.ca/repositories/artsdata/statements", headers: {
      Authorization: "Basic YXJ0c2RhdGEtYXBpOlN5amNpeC16b3Z3ZXMtN3ZvYm1p"})
  end

  # Method to update a triple in the graph
  def update_triple(graph:, subject:, predicate:, old_object:, new_object:)
    query = <<-SPARQL
      WITH <#{graph}>
      DELETE {
        <#{subject}> <#{predicate}> #{old_object} .
      }
      INSERT {
        <#{subject}> <#{predicate}> #{new_object} .
      }
      WHERE {
        <#{subject}> <#{predicate}> #{old_object} .
      }
    SPARQL

    # Execute the SPARQL query
    begin
      response = @client.update(query)
      puts "Triple updated successfully! #{response.inspect}"
    rescue StandardError => e
      puts "Error updating triple: #{e.message}"
    end
  end


end
