#\ -s puma

require 'bundler/setup'
require 'rack'
require 'rack/contrib/try_static'
require 'rack/contrib/not_found'

use Rack::TryStatic,
  root: 'public',
  urls: %w[/],
  try: ['.html', 'index.html', '/index.html']

run Rack::NotFound.new(File.expand_path('public/404.html', File.dirname(__FILE__)))