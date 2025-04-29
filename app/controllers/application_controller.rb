class ApplicationController < ActionController::Base
  helper_method :ensure_access, :user_has_access?
  before_action :set_locale
  append_view_path "doc"

  def home; end

  def test; end

  def doc
    template = "#{I18n.locale.to_s}/#{params[:path]}"
    render template: template
  end

  def user_signed_in?
    session[:handle].present?
  end

  def user_signed_in!
    unless user_signed_in?
      flash.alert = "You must be logged in to access this section"
      redirect_back(fallback_location: root_path) and return
    end
  end

  def temporarily_disable
    flash.alert = "This feature is temporarily disabled for maintenance. Try again in a few minutes."
    redirect_back(fallback_location: root_path)
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
    user_signed_in!
    return unless user_signed_in?

    unless user_has_access?(feature)
      flash.alert = "You do not have access to this feature. Please request access to the '#{feature}' feature from an Artsdata admin."
      redirect_to root_path and return
    end
  end

  # Role-Based Access Control (RBAC) pattern
  def user_has_access?(feature)
    return true if  Rails.env.test? 
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
    else
      false
    end
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  # TODO: Figure out if this is needed
  # def default_url_options
  #   { locale: I18n.locale }
  # end
end
