module Weather
  class << self
    def root
      Pathname.new(__FILE__).expand_path.dirname.dirname
    end
  end

  autoload :Previmeteo, 'weather/previmeteo'
  ActiveSensor::Equipment.register_many(Weather.root.join('config', 'sensors.yml'))
end
