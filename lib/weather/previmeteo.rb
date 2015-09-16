module Weather::Previmeteo

  class << self

    def root
      Ekylibre.root.join('plugins', 'weather')
    end
  end

  ActiveSensor::Base.register_many(Weather::Previmeteo.root.join('config', 'sensors.yml'))

end

