module Weather
  class Engine < ::Rails::Engine
    initializer 'weather.add_sensor_equipment' do |_app|
      ::ActiveSensor::Equipment.register_many(Weather::Engine.root.join('config', 'sensors.yml'))
    end
  end
end
