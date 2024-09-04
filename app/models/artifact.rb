class Artifact
  attr_accessor :name, :type, :description, :sheet_url

  def initialize(hsh = {})
    hsh.each do |key, value|
      self.send(:"#{key}=", value)
    end
  end

  def save
    # Save the artifact to the database
    
    return true
  end
end