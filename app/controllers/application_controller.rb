class ApplicationController < ActionController::Base
  helper_method :user_has_access?
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
      redirect_back(fallback_location: root_path)
      return # Stop further execution
    end
  end

  def temporarily_disable
    flash.alert = "This feature is temporarily disabled for maintenance. Try again in a few minutes."
    redirect_back(fallback_location: root_path)
  end
  

  def authenticate_user!
    return true if  Rails.env.test?
    
    unless user_signed_in?
      user_signed_in!
      return # Stop further execution
    end
    # TODO: Replace with user table
    if ["dlh28",
      "MorganPann",
      "GaryMan1968",
      "fjjulien",
      "saumier",
      "Liverace",
      "sahalali",
      "tammy-culture",
      "MichifDorian",
      "troughc",
      "dev-aravind"].include?(session[:handle])
      return true
    else
      flash.alert = "#{session[:name]} does not have sufficient permissions to access this section."
      redirect_back(fallback_location: root_path)
    end
   
  end

  def authenticate_databus_user!
    return true if  Rails.env.test?
    
    unless user_signed_in?
      user_signed_in!
      return # Stop further execution
    end
  
    if session[:accounts].present?
      return true
    else
      flash.alert = "Please request that #{session[:name]} be linked to an Artsdata Databus account."
      redirect_back(fallback_location: root_path)
    end
   
  end

  # Role-Based Access Control (RBAC) pattern
  def user_has_access?(feature)
    case feature
    when "ranked_links" # Level 2 or Level 1
      return session[:teams].any? { |team| team.key?("10808270") || team.key?("10808293") } 
    when "cms_links" # Level 2
      return session[:teams].any? { |team| team.key?("10808270") }
    when "minting" 
      return session[:teams].any? { |team| team.key?("10808270") || team.key?("10808293") } 
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
