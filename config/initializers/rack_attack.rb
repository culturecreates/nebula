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
Rack::Attack.throttled_responder = lambda do |_request|
  [429, { "Content-Type" => "text/plain" }, ["Too many requests. Please slow down.\n"]]
end
