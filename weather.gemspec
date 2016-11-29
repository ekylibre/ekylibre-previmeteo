$:.push File.expand_path("../lib", __FILE__)

require "weather/version"

Gem::Specification.new do |s|
  s.name        = 'weather'
  s.version     = Weather::VERSION
  s.authors     = ["Brice Texier", "Alexandre Lécuelle"]
  s.email       = ["brice@ekylibre.com", "alecuelle@ekylibre.com"]
  s.homepage    = "https://forge.ekylibre.com/projects/weather/repository"
  s.summary     = "Capteur météo"
  s.description = "Capteur météo"
  s.license     = "MIT"

  s.files = Dir["{app,config,lib}/**/*", "abaci/**/*", "Rakefile", "README.rdoc"]

  # s.add_dependency "active_sensor"
end
