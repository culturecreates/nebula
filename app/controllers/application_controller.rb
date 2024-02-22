class ApplicationController < ActionController::Base
  before_action :set_locale

  def home; end

  def test; end

  def authenticate_user!
    return true if session[:name] || Rails.env.test?
    flash.alert = "You must be logged in to access this section"
    redirect_back(fallback_location: root_path)
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
end
