class ApplicationController < ActionController::Base

  def home; end

  def test; end

  def authenticate_user!
    return true if session[:name] || Rails.env.test?
    flash.alert = "You must be logged in to access this section"
    redirect_to root_path
    
  end
end
