require 'darkroom'
require 'sass/plugin/rack'

Sass::Plugin.options[:template_location] = 'views'
use Sass::Plugin::Rack

run Sinatra::Application