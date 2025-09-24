
Rails.application.config.feature_minting_enabled = true
Rails.application.config.feature_maintenance_mode_enabled = false # set to false for normal operation
Rails.application.config.announcement_enabled = true
Rails.application.config.announcement_message = "News flash! <a href=/query/show?sparql=reconcile_controller/graphs_with_agents_to_reconcile>Batch Reconcile</a> for People, Organizations and Places is now available!".html_safe
Rails.application.config.announcement_start_time = 1758728904