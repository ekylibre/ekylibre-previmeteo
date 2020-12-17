# frozen_string_literal: true

require 'ekylibre-plugin_system'

module Ekylibre
  module Previmeteo
    autoload :GenericController, "#{__dir__}/previmeteo/generic_controller"
  end
end

require_relative 'previmeteo/plugin/previmeteo_plugin'
require_relative 'previmeteo/version'

require_relative 'previmeteo/engine' if defined?(Rails)
