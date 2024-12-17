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
  
      "#{markdown.render(source).inspect}.html_safe"
    end
  end
end