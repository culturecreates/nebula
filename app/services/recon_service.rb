class ReconService
  def initialize(recon_uri)
    @recon_uri = URI.parse(recon_uri)
  end

  def query_party(params)
    headers = { "Content-Type" => "application/json" }
    query =   {
        "q0" => {
          "query" => params[:query]
        }
      }
   
    if params[:type]
      query["q0"]["type"] = params[:type]
    end
    if params[:postalCode]
      query["q0"]["properties"] = [{pid: "schema:address/schema:postalCode", v: params[:postalCode]}]
    end

   # Build the URL
   @recon_uri.query = "queries=" + CGI.escape(query.to_json)

   # Print the URL
   puts "URL: #{@recon_uri}"

   HTTParty.get(@recon_uri, :headers => headers)
    
  end
 
  def query(params)
    request = Net::HTTP::Get.new(@recon_uri)
    request["Content-Type"] = "application/json"

    body_hash = {
      "query" => params[:query]
    }

    if params[:type]
      body_hash[:type] = params[:type]
    end

    if params[:postalCode]
      body_hash["properties"] = [{pid: "schema:address/schema:postalCode", v: params[:postalCode]}]
    end
    request.body = JSON.dump(body_hash)

    req_options = {
      use_ssl: @recon_uri.scheme == "https",
    }
    response = Net::HTTP.start(@recon_uri.hostname, @recon_uri.port, req_options) do |http|
      http.request(request)
    end
  end

end