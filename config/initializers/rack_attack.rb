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
