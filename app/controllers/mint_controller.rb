class MintController < ApplicationController
  before_action :check_minting_access # ensure user has permission

  # Preview data and SHACL report before minting a new Artsdata URI
  # GET /mint/preview
  #   - externalUri (required)
  #   - classToMint
  #   - label
  #   - language
  #   - dataset : [string] The void:inDataset URI of the entity
  #   - postalCode
  #   - startDate
  def preview
    required = [:externalUri]
    if required.all? { |k| params.key? k } 
      @externalUri = params[:externalUri]
      @classToMint = params[:classToMint]

      @label = params[:label]
      @dataset = params[:dataset].presence
      @user_uri = user_uri

      # get extra data about the entity when only externalUri is provided
      # Need: 
      # - dataset (i.e. graph URI that contains external URI)
      # - label (i.e. name)
      # - language (of name)
      # - classToMint (i.e. type)
      # - postalCode
      # - startDate
      @entity = Entity.new(entity_uri: @externalUri)
      @entity.load_card
      
    
      if !@dataset
        datasets = [RDF::URI(@externalUri), RDF::URI("http://rdfs.org/ns/void#inDataset"), nil]
        @dataset =  @entity.graph.query(datasets)&.first&.object&.value
      end

      # Wikidata entities carry no void:inDataset; use the Artsdata Wikidata dataset
      if @dataset.blank? && @externalUri.start_with?("http://www.wikidata.org/entity/")
        @dataset = "http://kg.artsdata.ca/resource/K1-20"
      end

      if !@label
        @label = @entity.label&.value
      end
      
      @language = @entity&.label&.language 
      
      if !@classToMint
        @classToMint = @entity.top_level_type 
      end
      
      # if classToMint was passed in as a parameter wihtout a full URI, add schema.org prefix
      if !@classToMint&.starts_with?("http") 
        @classToMint = "http://schema.org/" + @classToMint
      end

      @postalCode = @entity.card[:postal_code]
      if @postalCode &&  @postalCode.chars.length == 6
        @postalCode = @postalCode.dup.insert(3, " ")
      end
      @startDate =  @entity.card[:start_date]
    else 
      flash.now.alert = "Missing a required param. Required list: #{required}"
    end
  end

  # Link to an existing Artsdata URI
  # GET /mint/link
  def link 
    required = [:externalUri, :classToMint, :adUri, :dataset]
    if required.all? { |k| params[k].present? }
      @externalUri = params[:externalUri]
      @classToMint =  if params[:classToMint].starts_with?("http") 
                        params[:classToMint]
                      else
                        "http://schema.org/" + params[:classToMint]
                      end
      @adUri = params[:adUri]
      @dataset = params[:dataset]
      @publisher = user_uri

      # call link in mint service
      artsdata_link_endpoint = Rails.application.config.artsdata_link_endpoint
      uri = URI.parse(artsdata_link_endpoint) 

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({
          "externalUri" => @externalUri,
          "classToLink" => @classToMint,
          "adUri" => @adUri,
          "dataset" => @dataset,
          "publisher" => @publisher
      })
      
      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      @result = JSON.parse(response.body)
      if @result["status"] == "success"
        flash.notice = "Successfully linked #{@externalUri} to #{@adUri}"
      else  
        flash.alert = "Failed to link #{@externalUri} to #{@adUri}.  #{@result}"
      end
      redirect_back(fallback_location: root_path)
    else
      flash.alert = "Missing a required param. Required list: #{required}"
      redirect_back(fallback_location: root_path)
    end
  end

  # Link a blank node to an existing Artsdata URI
  # POST /mint/link_facts 
  def link_facts
    required = [:facts, :adUri, :externalReference, :classToMint]
    if required.all? { |k| params.key? k }
      facts = params[:facts]
      externalReference = params[:externalReference]
      adUri = params[:adUri]
      classToLink = params[:classToMint] # if params[:classToMint].starts_with?("http") 
      #                   params[:classToMint]
      #                 else
      #                   "http://schema.org/" + params[:classToMint]
      #                 end
     

      # call link in mint service
      artsdata_link_endpoint = Rails.application.config.artsdata_link_endpoint
      uri = URI.parse("#{artsdata_link_endpoint}/facts")
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({
          "facts" => facts,
          "externalReference" => externalReference,
          "classToLink" => classToLink,
          "adUri" => adUri,
          "user" => user_uri
      })
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      # make the HTTP request
      begin
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        if response.code.to_i >= 400
          raise "HTTP Error #{response.code}: #{response.message} - #{response.body}"
        end
        result = JSON.parse(response.body)
      rescue StandardError => e
        Rails.logger.error("Error in MintController#link_facts: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        flash.alert = "An error occurred while making the HTTP request: #{e.message}"
        redirect_back(fallback_location: root_path) and return
      end
      
      if result["status"] == "success"
        flash.notice = "Successfully linked blank node to #{adUri}"
        redirect_back(fallback_location: root_path)
      else
        flash.alert = "Failed to link blank node to #{adUri}. #{result}"
        redirect_back(fallback_location: root_path)
      end

    else
      flash.alert = "Missing a required param. Required list: #{required}"
      redirect_to entity_path(uri: @entity.entity_uri)
    end
  end

  # Mint an existing Wikidata URI
  # GET /mint/wikidata?wikidata_id=&classToMint=
  def wikidata
    #mapping table for wikidata types
    @wikidata_place_type = "Q17350442"
    @wikidata_person_type = "Q5"
    @wikidata_organization_type = "Q43229"
    
    # Search wikidata
    #  - reconile name and type against wikidata(even when the user entered a QID) 
    #    and show other close matches incase there are duplicates in Wikidata
    if params[:wikidata_search].present?
     
      @wikidata_data = {}
      if params[:wikidata_search] =~ /\AQ\d+\z/ # Wikidata ID
        @wikidata_data[:label] = params[:wikidata_search]
      elsif params[:wikidata_search] =~ /\Ahttp/ # Wikidata URI
        qid = params[:wikidata_search].split("/").last
        @wikidata_data[:label] = convert_id_to_name(qid)
      else # Wikidata label
        @wikidata_data[:label] = params[:wikidata_search] 
      end
      @wikidata_data[:type] = params[:type] if params[:type]
      @wikidata_data[:tab_type] = params[:tab_type] if params[:tab_type]
    end

    # Continue after user selects a wikidata entity from initial search results
    if params[:uri].present?
      @external_uri = "http://www.wikidata.org/entity/#{params[:uri]}"
      resolve_class_to_mint

      # call wikidata sparql to get more data
      entity = wikidata_entities([params[:uri]], props: "labels|descriptions")&.dig(params[:uri])
      @label = wikidata_text(entity, "labels", %w[en fr mul]) || params[:uri]
      @description = wikidata_text(entity, "descriptions", %w[en fr])
      @language = "en"
      @dataset = "http://kg.artsdata.ca/resource/K1-20"
      @group = 'http://wikidata.org'
      @user_uri = user_uri
    end


  end

  private

  # Determines @class_to_mint from the (possibly custom) type ID the user
  # searched with. If that type resolves to a broad type (person/org/place)
  # different from the tab the user started from, don't guess: set
  # @tab_class_choice / @wikidata_class_choice so the view can ask the user
  # which one to use, unless they already answered via params[:classToMint].
  def resolve_class_to_mint
    if params[:classToMint].present?
      @class_to_mint = params[:classToMint]
      return
    end

    wikidata_class = map_wikidata_type_to_schema(params[:type])
    tab_class = map_wikidata_type_to_schema(params[:tab_type]) if params[:tab_type].present?

    if tab_class.present? && wikidata_class.present? && tab_class != wikidata_class
      @tab_class_choice = tab_class
      @wikidata_class_choice = wikidata_class
    else
      @class_to_mint = wikidata_class || tab_class
    end
  end

  # Check if the user has access the the minting feature
  def check_minting_access
    ensure_access("minting")
  end

  def convert_id_to_name(wikidata_id)
    entity = wikidata_entities([wikidata_id], props: "labels")&.dig(wikidata_id)
    wikidata_text(entity, "labels", %w[en fr])
  end

  def map_wikidata_type_to_schema(wikidata_type)
    if wikidata_type == @wikidata_place_type
      "schema:Place"
    elsif wikidata_type == @wikidata_person_type
      "schema:Person"
    elsif wikidata_type == @wikidata_organization_type
      "schema:Organization"
    elsif wikidata_type.present?
      # Custom type IDs (e.g. a specific occupation or place subtype) aren't
      # one of the 3 broad types we know how to mint. Follow its subclass-of
      # (P279) chain in Wikidata to find which broad type it belongs to.
      broad_type = broad_wikidata_type(wikidata_type)
      map_wikidata_type_to_schema(broad_type) if broad_type
    end
  end

  WIKIDATA_API_ENDPOINT = "https://www.wikidata.org/w/api.php".freeze
  WIKIDATA_TIMEOUT = 5 # seconds; Wikidata can hang, and Heroku kills requests at 30s
  WIKIDATA_MAX_SUBCLASS_DEPTH = 5

  # Fetches entities from the Wikidata Action API (much more reliable than the
  # query service, query.wikidata.org, which often times out). Returns a hash
  # of QID => entity, or nil (and logs) if Wikidata is slow or unavailable so
  # callers can degrade gracefully.
  def wikidata_entities(qids, props:)
    response = HTTParty.get(
      WIKIDATA_API_ENDPOINT,
      query: { action: "wbgetentities", ids: qids.join("|"), props: props, languages: "en|fr|mul", format: "json" },
      timeout: WIKIDATA_TIMEOUT
    )
    raise "HTTP #{response.code}" unless response.code == 200

    entities = JSON.parse(response.body)["entities"]
    raise "unexpected response" unless entities.is_a?(Hash)

    entities
  rescue StandardError => e
    Rails.logger.warn("Wikidata request failed (#{e.class}): #{e.message}")
    nil
  end

  # First available text from an entity's labels/descriptions, in language order.
  def wikidata_text(entity, field, languages)
    values = entity&.dig(field) || {}
    languages.each { |lang| return values[lang]["value"] if values[lang] }
    nil
  end

  # Resolves a Wikidata type QID to one of the 3 broad types (person,
  # organization, place) by following subclass-of (P279) up the chain, one
  # level per request, up to WIKIDATA_MAX_SUBCLASS_DEPTH. Returns nil if not
  # found or Wikidata is unavailable. Results are cached, including "not
  # found", but not failures.
  def broad_wikidata_type(wikidata_type)
    return nil unless wikidata_type =~ /\AQ\d+\z/

    broad_ids = [@wikidata_person_type, @wikidata_organization_type, @wikidata_place_type]
    cache_key = ["wikidata_broad_type", wikidata_type]
    cached = Rails.cache.read(cache_key)
    return cached.presence if cached

    result = lookup_broad_wikidata_type(wikidata_type, broad_ids)
    Rails.cache.write(cache_key, result || "", expires_in: 1.day) unless result == :failed
    result == :failed ? nil : result
  end

  def lookup_broad_wikidata_type(wikidata_type, broad_ids)
    current = [wikidata_type]
    seen = Set.new(current)

    WIKIDATA_MAX_SUBCLASS_DEPTH.times do
      entities = wikidata_entities(current.first(50), props: "claims")
      return :failed if entities.nil?

      parents = entities.values.flat_map do |entity|
        (entity.dig("claims", "P279") || []).filter_map { |claim| claim.dig("mainsnak", "datavalue", "value", "id") }
      end.uniq

      found = broad_ids.find { |id| parents.include?(id) }
      return found if found

      current = parents.reject { |qid| seen.include?(qid) }
      seen.merge(current)
      return nil if current.empty?
    end
    nil
  end
end
