class Artifact
  attr_accessor :name, :description, :action_name, :action_url, :type, :description, :sheet_url, :group, :user, :errors, :artifact_create_action_uri

  def initialize(hsh = {}, user = nil)
    hsh.each do |key, value|
      self.send(:"#{key}=", value)
    end
    self.group = "A10s Google sheet"
    self.user = user
  end

  # Save the artifact to the databus using the Artsdata API
  def save
    name = self.name
    if name.blank?
      self.errors = "Name is required"
      return false
    end
    artifact_id = self.name.downcase.gsub(" ", "-")

    description = self.description
    publisher = "https://github.com/#{self.user}#this"
 
    if self.type == "spreadsheet-a10s" && self.sheet_url.present?
      group_id = "a10s-google-sheet"
      action_name = "Load #{artifact_id} A10s Google Sheet"
      action_url = "https://api.github.com/repos/artsdata-stewards/a10s-google-sheet-importer/actions/workflows/databus-a10-sheet-importer.yml/dispatches"
      httpBody = {
        ref: "main",
        inputs: {
          artifact: artifact_id,
          spreadsheet_url: self.sheet_url,
          publisher: "{{PublisherWebID}}"
        }
      }
    elsif self.type == "spreadsheet-smart-chip" && self.sheet_url.present?
      group_id = "spreadsheet-smart-chip"
      action_name = "Load #{artifact_id} Smart Chip Google Sheet"
      action_url = "https://api.github.com/repos/culture-creates/artsdata-google-workspace-smart-chip/actions/workflows/push-to-artsdata.yml/dispatches"
      httpBody = {
        ref: "main",
        inputs: {
          artifact: artifact_id,
          spreadsheet_url: self.sheet_url,
          publisher: "{{PublisherWebID}}"
        }
      }
    elsif self.type == "website"
      self.errors = "website artifacts not yet supported."
      return false
    else
      self.errors = "Invalid artifact. Please review your input."
      return false
    end
   
    
    # Call the API to save the artifact
    databus_endpoint = Rails.application.credentials.artsdata_databus_endpoint
    body = {
      name: name,
      description: description,
      artifact_id: artifact_id,
      group_id: group_id,
      action_name: action_name,
      action_url: action_url,
      action_body: httpBody.to_json,
      publisher: publisher
    }
    response = HTTParty.post("#{databus_endpoint}/artifact", 
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' })

    if response.code.between?(200, 299)
      self.artifact_create_action_uri = JSON.parse(response.body)["artifact_create_action_uri"]
      return true
    else
      self.errors = response
      return false
    end
  end

  def run_action(artifact_uri)
      
  end
end 