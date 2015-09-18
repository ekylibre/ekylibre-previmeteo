module Weather
  class << self
    def root
      Ekylibre.root.join('plugins', 'weather')
    end
  end

  autoload :Previmeteo, 'weather/previmeteo'
  ActiveSensor::Equipment.register_many(Weather.root.join('config', 'sensors.yml'))
end

