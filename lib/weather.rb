require 'weather/engine'

module Weather
  class << self
    def root
      Weather.root
    end
  end

  autoload :Previmeteo, 'weather/previmeteo'
end
