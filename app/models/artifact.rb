class Artifact
  attr_accessor :name, 
    :description, 
    :uri, 
    :artifact_id,
    :group, 
    :account,
    :action_name, 
    :action_url, 
    :type, 
    :description,
    :sheet_url,
    :webpage_url,
    :link_identifier, 
    :user, 
    :errors, 
    :artifact_create_action_uri

  def initialize(hsh = {}, user = nil)
    hsh.each do |key, value|
      self.send(:"#{key}=", value)
    end
    self.user = user
  end

  def uri=(uri)
    @uri = uri
    @account, @group, @artifact_id = uri.split("/")[4..6]
  end

  # Save the artifact to the databus using the Artsdata API
  def save
    name = self.name
    if name.blank?
      self.errors = "Name is required"
      return false
    end
    @artifact_id = self.name.downcase.gsub(" ", "-")

    @description = self.description
    @publisher = "https://github.com/#{self.user}#this"
 
    if self.type == "spreadsheet-a10s" && self.sheet_url.present?
      @group = "a10s-google-sheet"
      action_name = "Create an artifact version of #{@artifact_id}"
      action_url = "https://api.github.com/repos/artsdata-stewards/a10s-google-sheet-importer/actions/workflows/databus-a10-sheet-importer.yml/dispatches"
      httpBody = {
        ref: "main",
        inputs: {
          artifact: @artifact_id,
          spreadsheet_url: self.sheet_url,
          publisher: "{{PublisherWebID}}"
        }
      }
    elsif self.type == "spreadsheet-smart-chip" && self.sheet_url.present?
      @group = "spreadsheet-smart-chip"
      action_name = "Create an artifact version of #{@artifact_id}"
      action_url = "https://api.github.com/repos/culturecreates/artsdata-google-workspace-smart-chip/actions/workflows/push-to-artsdata.yml/dispatches"
      httpBody = {
        ref: "main",
        inputs: {
          artifact: @artifact_id,
          spreadsheet_url: self.sheet_url,
          publisher: "{{PublisherWebID}}"
        }
      }
    elsif self.type == "website"
      @group = "artsdata-orion"
      action_name = "Create an artifact version of the #{@artifact_id} website."
      # artsdata-pipeline-action
      action_url = "https://api.github.com/repos/culturecreates/artsdata-pipeline-action/actions/workflows/custom-crawl-test.yml/dispatches"
      httpBody = {
        ref: "main",
        inputs: {
          artifact: @artifact_id,
          "page-url" => @webpage_url,
          "entity-identifier" => @link_identifier,
          publisher: "{{PublisherWebID}}"
        }
      }
    else
      self.errors = "Invalid artifact. Please review your input."
      return false
    end
   
    
    # Call the API to save the artifact
    databus_endpoint = Rails.application.credentials.artsdata_databus_endpoint
    body = {
      name: name,
      description: @description,
      artifact_id: @artifact_id,
      group_id: @group,
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

end 