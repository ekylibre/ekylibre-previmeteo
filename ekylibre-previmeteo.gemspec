# coding: utf-8

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'weather/version'

Gem::Specification.new do |s|
  s.name        = 'ekylibre-previmeteo'
  s.version     = Weather::VERSION
  s.authors     = ['Brice Texier', 'Alexandre Lécuelle']
  s.email       = ['brice@ekylibre.com', 'alecuelle@ekylibre.com']
  s.homepage    = 'https://github.com/ekylibre/ekylibre-previmeteo'
  s.summary     = 'Previmeteo integration'
  s.license     = 'MIT'

  s.files = Dir['{app,config,lib}/**/*', 'abaci/**/*', 'Rakefile', 'README.rdoc']
end
