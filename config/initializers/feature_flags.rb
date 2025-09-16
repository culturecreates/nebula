
Rails.application.config.feature_minting_enabled = true
Rails.application.config.feature_maintenance_mode_enabled = false # set to false for normal operation
Rails.application.config.announcement_enabled = false
Rails.application.config.announcement_message = "News flash! <a href=/entity?uri=http%3A%2F%2Fkg.artsdata.ca%2Fresource%2FArtsdataEventTypes>Artsdata Event Types</a> v4.0 now available!".html_safe
Rails.application.config.announcement_start_time = Time.now.to_i