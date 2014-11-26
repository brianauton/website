activate :blog do |blog|
  blog.layout = :article_page
  blog.permalink = "posts/{title}.html"
  blog.sources = "posts/{year}-{month}-{day}-{title}.html"
  blog.tag_template = "tag.html"
  blog.calendar_template = "calendar.html"
end

page "/feed.xml", layout: false

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, :smartypants => true
activate :syntax

configure :development do
  activate(:disqus) { |config| config.shortname = false }
  activate(:google_analytics) { |ga| ga.tracking_id = false }
end

configure :build do
  activate(:disqus) { |config| config.shortname = "brianauton" }
  activate(:google_analytics) { |ga| ga.tracking_id = "UA-8088357-1" }
end
