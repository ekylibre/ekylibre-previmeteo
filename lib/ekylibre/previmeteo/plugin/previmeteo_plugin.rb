# frozen_string_literal: true

using Corindon::DependencyInjection::Injectable

module Ekylibre
  module Previmeteo
    module Plugin
      class PrevimeteoPlugin < Ekylibre::PluginSystem::Plugin
        injectable do
          tag 'ekylibre.system.plugin'
        end

        def boot(container) end

        def version
          Previmeteo::VERSION
        end
      end
    end
  end
end
