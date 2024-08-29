class Artifact
  attr_accessor :name, :group, :description, :account

  def initialize(hsh = {})
    hsh.each do |key, value|
      self.send(:"#{key}=", value)
    end
  end

  def self.all
    # This is a dummy method that returns an empty array
    []
  end
end