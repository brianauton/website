activate :blog do |blog|
  blog.permalink = "blog/{title}/"
  blog.sources = "articles/{year}-{month}-{day}-{title}.html"
  blog.tag_template = "tag.html"
  blog.calendar_template = "calendar.html"
end

page "/feed.xml", layout: false

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

configure :build do
end
