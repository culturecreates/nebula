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

class RackAttackThrottleLoggingTest < ActiveSupport::TestCase
  test "a throttle notification logs the rule, IP, counts, path and user agent" do
    env = Rack::MockRequest.env_for("/dereference/card", "REMOTE_ADDR" => "1.2.3.4", "HTTP_USER_AGENT" => "TestBot/1.0")
    env["rack.attack.matched"] = "dereference_card/ip"
    env["rack.attack.match_data"] = { count: 61, limit: 60, period: 60, epoch_time: 30 }
    request = Rack::Attack::Request.new(env)

    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    begin
      ActiveSupport::Notifications.instrument("throttle.rack_attack", request: request)
    ensure
      Rails.logger = original_logger
    end

    line = io.string
    assert_match "rack_attack throttle rule=dereference_card/ip", line
    assert_match "ip=1.2.3.4", line
    assert_match "count=61 limit=60 period=60", line
    assert_match "path=/dereference/card", line
    assert_match 'ua="TestBot/1.0"', line
  end
end

class RackAttackEntitySerialisationsThrottleTest < ActiveSupport::TestCase
  setup do
    @original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    @app = Rack::Attack.new(->(_env) { [200, {}, ["ok"]] })
  end

  teardown do
    Rack::Attack.cache.store = @original_store
  end

  # Each request comes from a different IP, as in a distributed crawl.
  def statuses(path, count, method: "GET")
    (1..count).map do |i|
      env = Rack::MockRequest.env_for(path, method: method, "REMOTE_ADDR" => "10.0.#{i / 250}.#{i % 250 + 1}")
      @app.call(env).first
    end
  end

  test "entity.jsonld is throttled globally once the limit is passed, whatever the IP" do
    result = statuses("/en/entity.jsonld?uri=http://example.org/x", 121)

    assert_equal [200], result.first(120).uniq
    assert_equal 429, result.last
  end

  test "entity.ttl and locale-less paths share the same global counter" do
    statuses("/entity.ttl?uri=http://example.org/x", 60)
    statuses("/fr/entity.jsonld?uri=http://example.org/x", 60)

    assert_equal [429], statuses("/entity.ttl?uri=http://example.org/x", 1)
  end

  test "the HTML entity page and its fragments are never throttled by this rule" do
    %w[/entity /en/entity /entity/property_claims].each do |path|
      assert_equal [200], statuses("#{path}?uri=http://example.org/x", 130).uniq, path
    end
  end

  test "non-GET requests are not counted" do
    assert_equal [200], statuses("/entity.jsonld", 130, method: "POST").uniq
  end
end
