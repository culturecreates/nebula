module Handlers
  class MarkdownHandler
    def call(template, source)
      @options ||= {
        autolink: true,
        space_after_headers: true,
        fenced_code_blocks: true,
        underline: true,
        highlight: true,
        footnotes: true,
        tables: true,
        link_attributes: {rel: 'nofollow', target: "_blank"}
    }
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, @options)
      rendered_content = markdown.render(source)
      
      # Wrap the rendered content with <div class="container">
      wrapped_content = "<div class=\"container\">#{rendered_content}</div>"

      "#{wrapped_content.inspect}.html_safe"
    end
  end
end