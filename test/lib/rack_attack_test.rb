require "test_helper"

class RackAttackThrottledResponderTest < ActiveSupport::TestCase
  def build_request(turbo_frame: nil, uri: nil, period:, epoch_time:)
    query = uri ? "?uri=#{CGI.escape(uri)}" : ""
    env = Rack::MockRequest.env_for("/dereference/card#{query}")
    env["HTTP_TURBO_FRAME"] = turbo_frame if turbo_frame
    env["rack.attack.match_data"] = {
      period: period, epoch_time: epoch_time, limit: 300, count: 301, discriminator: "1.2.3.4"
    }
    Rack::Attack::Request.new(env)
  end

  test "Retry-After is the seconds remaining in the current fixed window, not the full period" do
    request = build_request(period: 300, epoch_time: 250)
    status, headers, _body = Rack::Attack.throttled_responder.call(request)

    assert_equal 429, status
    assert_equal "50", headers["Retry-After"]
  end

  test "plain-text response for a non-turbo-frame request states the wait time" do
    request = build_request(period: 60, epoch_time: 45)
    status, headers, body = Rack::Attack.throttled_responder.call(request)

    assert_equal 429, status
    assert_equal "text/plain", headers["Content-Type"]
    assert_equal "15", headers["Retry-After"]
    assert_match "15s", body.first
  end

  test "turbo-frame response includes a matching frame, the URI, and the wait time" do
    request = build_request(turbo_frame: "card-1", uri: "http://example.org/x", period: 300, epoch_time: 100)
    status, headers, body = Rack::Attack.throttled_responder.call(request)

    assert_equal 429, status
    assert_equal "text/html", headers["Content-Type"]
    assert_equal "200", headers["Retry-After"]
    assert_match '<turbo-frame id="card-1">', body.first
    assert_match "example.org", body.first
    assert_match "200s", body.first
  end
end
