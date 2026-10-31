# rack-timeout is inserted into the middleware stack by its own Railtie and
# reads its settings from ENV when the stack is built, so default them here.
#
# Heroku's router answers H12 after 30s but leaves the Puma thread running, so a
# runaway request keeps burning CPU and a thread. Abort it a little before that.
# Override with RACK_TIMEOUT_SERVICE_TIMEOUT (seconds).
ENV["RACK_TIMEOUT_SERVICE_TIMEOUT"] ||= "25"

# Only log expired/timed_out requests (source=rack-timeout id=<request_id> ...);
# the default logs two INFO lines for every request. The id matches the
# [request_id] tag on the Rails "Started GET ..." line, which gives the path.
Rack::Timeout::Logger.level = Logger::ERROR if defined?(Rack::Timeout::Logger)
