class ApplicationController < ActionController::Base
  helper_method :ensure_access, :user_has_access?, :controlled_vocabularies
  before_action :set_locale, :maintenance_mode?, :announcement_flash
  append_view_path "doc"

  def announcement_flash
    if Rails.application.config.announcement_enabled &&
       Rails.application.config.announcement_message.present?
      announcement_start = (Rails.application.config.respond_to?(:announcement_start_time) && Rails.application.config.announcement_start_time) || nil
      now = Time.now.to_i
      one_week = 7 * 24 * 60 * 60
      on_home = (request.path == root_path || request.path == "/")
      if on_home
        if announcement_start.nil? || now - announcement_start < one_week
          flash.now[:notice] = Rails.application.config.announcement_message
        end
      elsif session[:announcement_shown].nil?
        if announcement_start.nil? || now - announcement_start < one_week
          flash.now[:notice] = Rails.application.config.announcement_message
        end
        session[:announcement_shown] = true
      end
    end
  end
  

  def home; end

  def doc
    template = "#{I18n.locale.to_s}/#{params[:path]}"
    render template: template
  end

  def maintenance_mode?
    if Rails.application.config.feature_maintenance_mode_enabled
      flash.notice = "Artsdata is currently undergoing maintenance. Service is slower than usual."
    end
  end
  
  # Check if user is signed in and has a valid session
  def user_signed_in?
    return false unless session[:handle].present?
      
    return false unless session[:github_authenticated_time].present? && session[:github_expires_in].present?

    return false if Time.now.utc - Time.parse(session[:github_authenticated_time]) > session[:github_expires_in]

    true
  end

  def user_uri
    if session[:handle].present?
      "https://github.com/#{session[:handle]}#this"
    end
  end

  # Ensure user is signed in, otherwise notify and redirect
  def user_signed_in!
    unless user_signed_in?
      logout
      flash.alert = "You must be logged in to access this section. Artsdata uses GitHub.com accounts which can be created for free."
      redirect_back(fallback_location: root_path) and return
    end
  end

  # Log out user by clearing session data
  def logout
    session[:github_authenticated] = false
    session[:github_expires_in] = nil
    session[:github_authenticated_time] = nil
    session[:handle] = nil
    session[:name] = nil
    session[:token] = nil
    session[:teams] = nil
    session[:accounts] = nil
  end

  def authenticate_databus_user!
    return true if  Rails.env.test?

    user_signed_in!
    return unless user_signed_in?

    if session[:accounts].present?
      return true
    else
      flash.alert = "Please request that #{session[:handle]} be added to an Artsdata Databus team."
      redirect_back(fallback_location: root_path)
    end
  end

  # Check if user is signed in and has permission to use the feature
  def ensure_access(feature)
    return if Rails.env.test? 

    user_signed_in!
    return unless user_signed_in?

    unless user_has_access?(feature)
      flash.alert = "You do not have access to this feature. Please request access to the '#{feature}' feature from an Artsdata admin at artsdata-support@capacoa.ca."
      redirect_to root_path and return
    end
    
    # Check feature flag
    if feature == "minting" && Rails.application.config.feature_minting_enabled == false
      flash.alert = "This feature is temporarily disabled for maintenance. Try again later."
      redirect_to root_path and return
    end
  end

  # Role-Based Access Control (RBAC) pattern
  # Github Team IDs:
  #     Level 2: 10808270 (Artsdata Admins)
  #     Level 1: 10808293 (Artsdata Editors)
  def user_has_access?(feature)
    return false unless session[:teams].present?

    case feature
    when "ranked_links" # Level 2 or Level 1
      return session[:teams].any? { |team| team.key?("10808270") || team.key?("10808293") } 
    when "cms_links" # Level 2
      return session[:teams].any? { |team| team.key?("10808270") }
    when "minting" 
      return session[:teams].any? { |team| team.key?("10808270") || team.key?("10808293") } 
    when "sparql_manager" # Level 2
      return session[:teams].any? { |team| team.key?("10808270") }
    when "ical"
      return session[:teams].any? { |team| team.key?("10808270") || team.key?("10808293") }
    when "delete_entity"
      return session[:teams].any? { |team| team.key?("10808270") }
    when "refresh_entity"
      return session[:teams].any? { |team| team.key?("10808270") || team.key?("10808293") }
    else
      false
    end
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  # Fetch controlled vocabularies dynamically from Artsdata
  def controlled_vocabularies
    return @controlled_vocabularies if @controlled_vocabularies

    begin
      query = SparqlLoader.load("list_controlled_vocabularies")
      solutions = ArtsdataGraph::SparqlService.client.query(query).limit(100)
      
      # Mapping of URI patterns to translation keys
      label_mapping = {
        "ArtsdataEventTypes" => "nav.event_types",
        "ArtsdataOrganizationTypes" => "nav.organization_types",
        "ArtsdataGenres" => "nav.genres"
      }
      
      @controlled_vocabularies = solutions.map do |solution|
        uri = solution[:cv].to_s
        # Extract the resource name from URI (e.g., "ArtsdataEventTypes")
        resource_name = uri.split('/').last
        
        # Use translation if available, otherwise use humanized resource name
        label_key = label_mapping[resource_name] || resource_name.humanize
        label = label_key.start_with?("nav.") ? I18n.t(label_key) : label_key
        
        {
          uri: uri,
          label: label
        }
      end
    rescue StandardError => e
      Rails.logger.error "Failed to fetch controlled vocabularies: #{e.message}"
      # Return hardcoded list as fallback
      @controlled_vocabularies = [
        { uri: "http://kg.artsdata.ca/resource/ArtsdataEventTypes", label: I18n.t("nav.event_types") },
        { uri: "http://kg.artsdata.ca/resource/ArtsdataOrganizationTypes", label: I18n.t("nav.organization_types") },
        { uri: "http://kg.artsdata.ca/resource/ArtsdataGenres", label: I18n.t("nav.genres") }
      ]
    end

    @controlled_vocabularies
  end

  # TODO: Figure out if this is needed
  # def default_url_options
  #   { locale: I18n.locale }
  # end
end
