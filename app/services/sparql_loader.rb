# Class to load SPARQL from local or remote files
class SparqlLoader
 
  def self.load(filename, substitute_list = [])
    if  filename.starts_with?("http")
      self.load_url(filename, substitute_list)
    else
      f = File.read("app/services/sparqls/#{filename}.sparql")
      make_sparql(f, substitute_list)
    end
  end

  def self.load_url(url,  substitute_list = [] )
    uri = URI(url)
    f = ''
    begin
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        f = response.body
        make_sparql(f, substitute_list)
      else
        return { error: "HTTP Error: #{response.code}" }
      end
    rescue => exception
      return { error: exception.message }
    end
  end

  def self.make_sparql(f, substitute_list)
    substitute_list.each_slice(2) do |a, b|
      f.gsub!(a.to_s, b.to_s)
    end
    f
  end
end