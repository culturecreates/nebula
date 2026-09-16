# Builds a minimal turbo-frame HTML fragment carrying an error message.
# A failed turbo-frame request (rate-limited, raised an exception, etc.)
# needs a response containing a matching <turbo-frame id="..."> or Turbo
# has nothing to swap in and the frame is silently left blank - this
# gives it something to find instead.
module TurboFrameError
  def self.html(frame_id:, message:, detail: nil)
    body = +%(<turbo-frame id="#{Rack::Utils.escape_html(frame_id)}">)
    body << %(<div class="text-danger small">)
    body << %(#{Rack::Utils.escape_html(detail)}<br>) if detail.present?
    body << Rack::Utils.escape_html(message)
    body << "</div></turbo-frame>"
    body
  end
end
