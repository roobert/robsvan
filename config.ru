#\ -p 4567 -o 0.0.0.0

require 'sinatra'
require 'rack/reloader'
require './app.rb'

# show errors and reload environment on file change
set :environment, :development

configure :development do
  enable :raise_errors
  enable :show_exceptions
end

use Rack::Reloader, 0 if development?

# if installed as http://example.com/someapp then change this to /someapp
map '/' do
  run Sinatra::Application
end
