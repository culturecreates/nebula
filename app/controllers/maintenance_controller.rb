class MaintenanceController < ApplicationController
  before_action :check_refresh_access, only: [:refresh_entity, :batch_refresh_entity] # ensure user has permissions

  def refresh_entity
    artsdata_uri = params[:uri]
    dryrun = ActiveModel::Type::Boolean.new.cast(params[:dryrun])
    # Present only when the refresh was triggered from a single external identifier in the
    # refresh dropdown (see entity/_refresh_dropdown.html.erb); scopes the refresh to that
    # source instead of pulling from all of the entity's sources.
    source = params[:source].presence
    publisher = user_uri
    timeout_seconds = 15
    # Call Artsdata API to refresh entity data
    api_endpoint = Rails.application.config.artsdata_maintenance_endpoint + "/refresh_entity"
    begin
      body = {
        uri: artsdata_uri,
        publisher: publisher,
        dryrun: dryrun
      }
      body[:source] = source if source
      response = HTTParty.post(api_endpoint,
        body: body.to_json,
        headers: { 'Content-Type' => 'application/json' },
         timeout: timeout_seconds
      )
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      error_message = "Timeout: Artsdata Maintenance API did not respond within #{timeout_seconds} seconds. Try again in a few minutes."
    rescue StandardError => e
      error_message = "Error connecting to Artsdata Maintenance API: #{e.message}"
    end
    if error_message
      if dryrun
        render json: { message: error_message }, status: :service_unavailable
      else
        flash[:alert] = error_message
        render json: { redirect_url: entity_path(uri: artsdata_uri) }, status: :service_unavailable
      end
      return
    end
    if dryrun
      if response.code != 200
        message =  "#{CGI.escapeHTML(response["message"])}"
        render json: { message: message }, status: :service_unavailable
      else
        items = JSON.parse(response.body)['logs']
        formated_items = ""
        # update_assertions distinguishes an asserted triple actually inserted/deleted in the
        # store (true) from an unasserted claim change (false, e.g. a non-winning source's
        # value) - shown separately below so a refresh that only touches claims isn't shown as
        # if it changed nothing, without implying those claims changed the entity itself.
        asserted_items = items.select { |item| item["update_assertions"] }
        # Asserting a value also writes its own matching claim annotation (see artsdata-api's
        # MaintenanceService#add_to_log), so the same subject/predicate/object/action can arrive
        # here twice - once with update_assertions: true, once without. Only the second (falsy)
        # copy is filtered out by the update_assertions reject below, so also drop anything that
        # already appears in the Updates/Deletes list, or it'd show up a second time under Claims.
        asserted_keys = asserted_items.map { |item| item.values_at("subject", "predicate", "object", "action") }.to_set
        claimed_items = items.reject { |item| item["update_assertions"] || asserted_keys.include?(item.values_at("subject", "predicate", "object", "action")) }
        add_list = asserted_items.select{ |item| item["action"] == "add" }
        unless add_list.empty?
          formated_items << "<h4>Updates</h5> <ul>"
          add_list.each do |item|
            formated_items << format_display(item)
          end
          formated_items << "</ul>"
        end
        delete_list = asserted_items.select{ |item| item["action"] == "delete" }
        unless delete_list.empty?
          formated_items << "<h4>Deletes</h5> <ul>"
          delete_list.each do |item|
            formated_items << format_display(item)
          end
          formated_items << "</ul>"
        end
        unless claimed_items.empty?
          formated_items << "<h4>Claims</h5> <ul>"
          claimed_items.each do |item|
            # Unlike Updates/Deletes above, claims are all listed under one shared header, so
            # each line needs its own +/- to tell an added claim from a removed one.
            formated_items << format_display(item, show_sign: true)
          end
          formated_items << "</ul>"
        end
        # Display errors if there are any
        rescues = JSON.parse(response.body)['rescues']
        formated_rescues = ""
        unless rescues.blank?
          formated_rescues << "<h4>Ignored sources</h5> <ul>"
          rescues.each do |rescue_item|
            formated_rescues << "<li>#{ERB::Util.html_escape(rescue_item)}</li>"
          end
          formated_rescues << "</ul>"
        end
        render json: { message: formated_items, rescues: formated_rescues }, status: :ok
      end
    else
      if response.code != 200
        flash[:alert] = "Failed. Error: #{response.body.truncate(1000)}"
      else
        expire_entity_view_caches(artsdata_uri)
        flash[:notice] = source ? "Successfully refreshed #{artsdata_uri} from #{source}." : "Successfully refreshed #{artsdata_uri}."
      end
      render json: { redirect_url: entity_path(uri: artsdata_uri) }
    end
  end

  def batch_refresh_entity
    uris = params[:uris]
    publisher = user_uri
    redirect_url = params[:redirect_url] || root_path
    timeout_seconds = 30
    api_endpoint = Rails.application.config.artsdata_maintenance_endpoint + "/refresh_entity"
    begin
      response = HTTParty.post(api_endpoint,
        body: {
          uri: uris,
          publisher: publisher,
          dryrun: false
        }.to_json,
        headers: { 'Content-Type' => 'application/json' },
        timeout: timeout_seconds
      )
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      error_message = "Timeout: Artsdata Maintenance API did not respond within #{timeout_seconds} seconds. Try again in a few minutes."
    rescue StandardError => e
      error_message = "Error connecting to Artsdata Maintenance API: #{e.message}"
    end
    if error_message
      flash[:alert] = error_message
    elsif response.code != 202 && response.code != 200
      flash[:alert] = "Batch refresh failed. Error: #{response.body.truncate(1000)}"
    else
      uris.each { |uri| expire_entity_view_caches(uri) }
      flash[:notice] = "Successfully queued refresh for #{uris.length} #{"entity".pluralize(uris.length)}."
    end
    render json: { redirect_url: redirect_url }
  end

  private

  def check_refresh_access
    ensure_access("refresh_entity")
  end

  # show_sign: prefix the predicate with +/- (item["action"] == "add"/"delete") - used for the
  # Claims section, where adds and removes are listed together under one header, unlike the
  # asserted Updates/Deletes sections which already say which they are via their own header.
  def format_display(item, show_sign: false)
    id = item["source"].to_s.split("/").last
    # A blank source (e.g. no current claim annotation for this change - see
    # history_logs.sparql's ?source comment for why that happens) would otherwise render as
    # empty brackets "()" or "(secondary )"; omit the claim entirely instead of showing them.
    claim = if id.blank?
              nil
            elsif item["claim"] == "derived"
              "(secondary #{id})"
            else
              "(#{id})"
            end
    claim_suffix = claim ? " #{claim}" : ""
    sign = show_sign ? (item["action"] == "add" ? "+" : "-") : ""
    if item["object"].to_s.start_with?("_")
      "<li>#{sign}#{item["predicate"].to_s.split("/").last}#{claim_suffix}:</li>"
    elsif item["object"].to_s.include?("#")
      "<li>#{sign}#{item["predicate"].to_s.split("/").last}: <b>#{item["object"].to_s.split("#").last}</b>#{claim_suffix}</li>"
    else
      if item["subject"].to_s.start_with?("_") || item["subject"].to_s.include?("#")
        "<li class='ms-4'>nested #{sign}#{item["predicate"].to_s.split("/").last.split("#").last}: <b>#{item["object"].to_s.split("/").last}</b>#{claim_suffix}</li>"
      else
        "<li>#{sign}#{item["predicate"].to_s.split("/").last.split("#").last}: <b>#{ActionController::Base.helpers.strip_tags(item["object"].to_s).truncate(50)}</b>#{claim_suffix}</li>"
      end
    end
  end

end
