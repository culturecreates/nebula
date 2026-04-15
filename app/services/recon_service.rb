class ReconService
  def initialize(recon_uri)
    @recon_uri = URI.parse(recon_uri)
  end

  def query_party(query:, type: nil, postalCode: nil)
    q = query.gsub("?","") # Need more investigation: even though query gets CGI.escaped below, it is necessary to remove ? character to reconcile urls with query strings
    headers = { "Content-Type" => "application/json" }
    query =   {
        "q0" => {
          "query" => q
        }
      }
   
    if type.presence
      query["q0"]["type"] = type    
    end
    if postalCode.presence 
      if type.downcase.include?("event")
        query["q0"]["properties"] = [{pid: "schema:location/schema:address/schema:postalCode", v: postalCode}]
      else
        query["q0"]["properties"] = [{pid: "schema:address/schema:postalCode", v: postalCode}]
      end
    end

   

   # Build the URL
   @recon_uri.query = "queries=" + CGI.escape(query.to_json)

   # Print the URL
   puts "URL: #{@recon_uri}"
   
   # TODO: bring back  Net::HTTP::Get.new(uri) native solution instead of HTTParty
   HTTParty.get(@recon_uri, :headers => headers)
    
  end


end