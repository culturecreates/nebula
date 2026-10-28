class Rack::Attack
  # Rack::Attack defaults to Rails.cache, but this app's cache_store is
  # :null_store in development unless `rails dev:cache` is toggled on, and
  # isn't explicitly set in production either - give Rack::Attack its own
  # dedicated in-memory store so throttling always works regardless of the
  # app's cache configuration.
  self.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Don't throttle requests from the local machine (dev/test).
  safelist("allow-localhost") do |req|
    ["127.0.0.1", "::1"].include?(req.ip)
  end

  # General ceiling on all requests.
  # (~1/sec sustained, generous enough for scripted/automated dereferencing
  # of entity URIs, but stops broad floods).
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Stricter ceiling on the homepage specifically, since that's the page
  # being repeatedly hit by bot traffic.
  # No normal visitor reloads the homepage that often.
  throttle("home/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.get? && req.path =~ %r{\A/(en|fr)?/?\z}
  end

  # /dereference/card fans out once per URI triple on an entity page, so allow
  # a busy page's burst but stop crawlers; /dereference/external fetches a
  # third-party site per request.
  throttle("dereference_card/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.get? && req.path =~ %r{\A/(en|fr)?/?dereference/card\z}
  end

  throttle("dereference_external/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.get? && req.path =~ %r{\A/(en|fr)?/?dereference/external}
  end

  # Distributed crawlers stay under every per-IP limit, so cap the machine-readable
  # entity serialisations globally (keyed on a constant, not the IP). These are the
  # expensive requests (graph load + framing; .jsonld also self-fetches /context.jsonld).
  # The HTML /entity page and its fragments are deliberately not included.
  throttle("entity_serialisations/global", limit: 120, period: 1.minute) do |req|
    "all" if req.get? && req.path =~ %r{\A/(en|fr)?/?entity\.(jsonld|jsonlds|ttl|ttls|rdf)\z}
  end
end

# Keep the throttled response itself cheap - plain text, no view rendering.
# Exception: a throttled turbo-frame request (e.g. one of the many
# /dereference/card fan-out requests on a busy entity page) expects a
# response containing a matching <turbo-frame id="..."> to swap in: a
# plain-text body has no such element, so Turbo can't find anything to
# swap and the frame is silently left blank. Echo back a minimal frame
# with the URI and a short error instead, so the throttling is visible
# rather than looking like the card failed to load for no reason.
Rack::Attack.throttled_responder = lambda do |request|
  # Throttle windows are fixed, epoch-aligned periods (see
  # Rack::Attack::Cache#key_and_expiry), not rolling from the client's
  # first request - so the wait until the count resets is whatever's
  # left of the *current* period, not the full period every time.
  match_data = request.env["rack.attack.match_data"]
  retry_after = match_data[:period] - (match_data[:epoch_time] % match_data[:period])
  headers = { "Retry-After" => retry_after.to_s }

  frame_id = request.get_header("HTTP_TURBO_FRAME")
  if frame_id.present?
    body = TurboFrameError.html(
      frame_id: frame_id,
      message: "Too many requests - please try again in #{retry_after}s.",
      detail: request.params["uri"]
    )
    [429, headers.merge("Content-Type" => "text/html"), [body]]
  else
    [429, headers.merge("Content-Type" => "text/plain"), ["Too many requests. Please try again in #{retry_after}s.\n"]]
  end
end

# Log each throttled request so the throttles' impact shows up in the app log
# (Heroku's router only records a bare status=429). One line per request,
# tagged with the rule name so it's easy to grep/count, e.g.
#   heroku logs | grep "rack_attack throttle" | grep dereference_card
ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  match_data = req.env["rack.attack.match_data"] || {}
  Rails.logger.warn(
    "rack_attack throttle rule=#{req.env['rack.attack.matched']} ip=#{req.ip} " \
    "count=#{match_data[:count]} limit=#{match_data[:limit]} period=#{match_data[:period]} " \
    "path=#{req.path} ua=#{req.user_agent.inspect}"
  )
end
