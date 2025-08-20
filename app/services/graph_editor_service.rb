class GraphEditorService
  require 'sparql/client'

  def initialize
    @client = SPARQL::Client.new("http://db.artsdata.ca/repositories/artsdata/statements", headers: {
      Authorization: "Basic #{Rails.application.credentials.graph_db_basic_auth}"})
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
