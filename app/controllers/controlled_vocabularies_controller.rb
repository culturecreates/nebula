class ControlledVocabulariesController < ApplicationController
  # GET /controlled_vocabularies
  # Returns the list of controlled vocabularies for lazy loading in the navigation menu
  def index
    @controlled_vocabularies = fetch_controlled_vocabularies
    
    respond_to do |format|
      format.turbo_stream
      format.html { render partial: "list", locals: { controlled_vocabularies: @controlled_vocabularies } }
    end
  end

  private

  # Fetch controlled vocabularies dynamically from Artsdata
  def fetch_controlled_vocabularies
    current_locale = I18n.locale.to_s
    
    begin
      query = SparqlLoader.load("list_controlled_vocabularies")
      solutions = ArtsdataGraph::SparqlService.client.query(query).limit(100)
      
      # Group solutions by URI to collect all labels
      vocabularies_by_uri = {}
      solutions.each do |solution|
        uri = solution[:cv].to_s
        label = solution[:label]
        
        vocabularies_by_uri[uri] ||= { uri: uri, labels: {} }
        
        # Store label with its language tag if present
        if label.respond_to?(:language) && label.language
          vocabularies_by_uri[uri][:labels][label.language.to_s] = label.to_s
        elsif label.respond_to?(:to_s) && label.to_s.present?
          # If no language tag, use as fallback
          vocabularies_by_uri[uri][:labels]["default"] = label.to_s
        end
      end
      
      # Build final list with locale-specific labels
      vocabularies_by_uri.map do |uri, data|
        # Try to get label in current locale, fallback to English, then any available label, then humanized URI
        label = data[:labels][current_locale] || 
                data[:labels]["en"] || 
                data[:labels]["default"] ||
                data[:labels].values.first ||
                uri.split('/').last.humanize
        
        {
          uri: uri,
          label: label
        }
      end.sort_by { |v| v[:uri] }
      
    rescue StandardError => e
      Rails.logger.error "Failed to fetch controlled vocabularies: #{e.message}"
      # Return minimal fallback - English labels only (no i18n in fallback by design)
      [
        { uri: "http://kg.artsdata.ca/resource/ArtsdataEventTypes", label: "Event Types" },
        { uri: "http://kg.artsdata.ca/resource/ArtsdataOrganizationTypes", label: "Organization Types" },
        { uri: "http://kg.artsdata.ca/resource/ArtsdataGenres", label: "Genres" }
      ]
    end
  end
end
