class ApplicationController < ActionController::Base
  before_action :set_locale
  append_view_path "doc"

  def home; end

  def test; end

  def authenticate_user!
    return true if  Rails.env.test?

    if session[:handle]
      # TODO: Replace with user table
      if session[:handle] == "saumier" || session[:handle] == "sahalali"
        return true
      else
        flash.alert = "#{session[:name]} does not have sufficient permissions to access this section."
        redirect_back(fallback_location: root_path)
      end
    else
    flash.alert = "You must be logged in to access this section"
    redirect_back(fallback_location: root_path)
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
