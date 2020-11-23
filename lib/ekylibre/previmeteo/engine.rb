# frozen_string_literal: true

module Ekylibre
  module Previmeteo
    class Engine < ::Rails::Engine
      extend Ekylibre::PluginSystem::PluginRegistration

      register_plugin(Ekylibre::Previmeteo::Plugin::PrevimeteoPlugin)

      initializer 'weather.add_sensor_equipment' do |_app|
        ::ActiveSensor::Equipment.register_many(root.join('config', 'sensors.yml'))
      end
    end
  end
end
