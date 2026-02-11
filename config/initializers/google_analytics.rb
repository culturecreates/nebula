# Set Google Analytics ID from credentials if present and not already set
if Rails.application.credentials.google_analytics_id && ENV['GOOGLE_ANALYTICS_ID'].nil?
  ENV['GOOGLE_ANALYTICS_ID'] = Rails.application.credentials.google_analytics_id
end
