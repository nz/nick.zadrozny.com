#\ -s puma
require 'bundler/setup'
require 'rack'
run Rack::File.new("public")
