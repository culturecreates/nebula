require "test_helper"

class TurboFrameErrorTest < ActiveSupport::TestCase
  test "wraps the message in a turbo-frame matching the given id" do
    html = TurboFrameError.html(frame_id: "card-42", message: "Too many requests")

    assert_match %r{\A<turbo-frame id="card-42">}, html
    assert_match "Too many requests", html
    assert_match "</turbo-frame>", html
  end

  test "includes the detail line when given one" do
    html = TurboFrameError.html(frame_id: "card-1", message: "boom", detail: "example.org")

    assert_match "example.org", html
    assert_match "boom", html
  end

  test "omits the detail line when not given one" do
    html = TurboFrameError.html(frame_id: "card-1", message: "boom")

    assert_no_match "<br>", html
  end

  test "escapes HTML in both the message and the detail" do
    html = TurboFrameError.html(
      frame_id: "card-1",
      message: "<script>alert(1)</script>",
      detail: "<script>alert(2)</script>"
    )

    assert_no_match "<script>", html
  end
end
