activate :blog do |blog|
  blog.layout = :article_layout
  blog.permalink = "posts/{title}/"
  blog.sources = "articles/{year}-{month}-{day}-{title}.html"
  blog.tag_template = "tag.html"
  blog.calendar_template = "calendar.html"
end

activate :disqus do |d|
  d.shortname = "brianauton"
end

page "/feed.xml", layout: false

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, :smartypants => true
activate :syntax

configure :development do
  activate(:google_analytics) { |ga| ga.tracking_id = false }
end

configure :build do
  activate(:google_analytics) { |ga| ga.tracking_id = "UA-8088357-1" }
end
