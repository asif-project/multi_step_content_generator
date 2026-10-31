module ApplicationHelper
  # Turn Markdown text from the AI into safe HTML.
  def markdown(text)
    sanitize(Kramdown::Document.new(text).to_html)
  end
end
